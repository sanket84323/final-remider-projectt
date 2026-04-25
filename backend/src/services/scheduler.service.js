/**
 * Scheduler Service
 * node-cron jobs for auto-reminders before assignment/reminder deadlines
 */

const cron = require('node-cron');
const Reminder = require('../models/Reminder');
const Assignment = require('../models/Assignment');
const User = require('../models/User');
const notificationService = require('./notification.service');
const logger = require('../utils/logger');

/**
 * Check scheduled reminders that are due to be sent now
 */
const processScheduledReminders = async () => {
  try {
    const now = new Date();
    const reminders = await Reminder.find({
      status: 'scheduled',
      scheduledAt: { $lte: now },
    });

    for (const reminder of reminders) {
      // Build audience
      const userFilter = { role: 'student', isActive: true };
      if (reminder.targetAudience?.type === 'class') userFilter.className = reminder.targetAudience.className;
      if (reminder.targetAudience?.type === 'department') userFilter.department = reminder.targetAudience.department;

      const targetUsers = await User.find(userFilter).select('_id fcmToken').lean();
      await notificationService.notifyUsers({
        users: targetUsers,
        title: reminder.title,
        body: reminder.description.substring(0, 150),
        type: 'reminder',
        reminderId: reminder._id,
        priority: reminder.priority,
        data: { reminderId: reminder._id.toString(), type: 'reminder' },
      });

      reminder.status = 'sent';
      await reminder.save();
      logger.info(`Scheduled reminder sent: ${reminder.title}`);
    }
  } catch (error) {
    logger.error(`Scheduler error (scheduled reminders): ${error.message}`);
  }
};

/**
 * Send auto-reminders 24h, 2h, and 30min before deadline
 */
const processDeadlineReminders = async () => {
  try {
    const now = new Date();
    const timeWindows = [
      { label: '24h', ms: 24 * 60 * 60 * 1000, field: 'sent24h' },
      { label: '2h', ms: 2 * 60 * 60 * 1000, field: 'sent2h' },
      { label: '30min', ms: 30 * 60 * 1000, field: 'sent30min' },
    ];

    for (const window of timeWindows) {
      const windowStart = new Date(now.getTime() + window.ms - 5 * 60 * 1000); // 5 min tolerance
      const windowEnd = new Date(now.getTime() + window.ms + 5 * 60 * 1000);

      const reminders = await Reminder.find({
        deadlineAt: { $gte: windowStart, $lte: windowEnd },
        status: 'sent',
        [`autoReminders.${window.field}`]: false,
      });

      for (const reminder of reminders) {
        const userFilter = { role: 'student', isActive: true };
        const targetUsers = await User.find(userFilter).select('_id fcmToken').lean();
        await notificationService.notifyUsers({
          users: targetUsers,
          title: `⏰ Deadline Approaching: ${reminder.title}`,
          body: `Due in ${window.label}! Don't forget to check the reminder.`,
          type: 'reminder',
          reminderId: reminder._id,
          priority: 'urgent',
        });

        reminder.autoReminders[window.field] = true;
        await reminder.save();
        logger.info(`Auto-reminder (${window.label}) sent for: ${reminder.title}`);
      }

      // Also check assignments
      const assignments = await Assignment.find({
        dueDate: { $gte: windowStart, $lte: windowEnd },
        isActive: true,
      });

      for (const assignment of assignments) {
        const userFilter = { role: 'student', isActive: true };
        if (assignment.targetAudience?.className) userFilter.className = assignment.targetAudience.className;
        const targetUsers = await User.find(userFilter).select('_id fcmToken').lean();
        await notificationService.notifyUsers({
          users: targetUsers,
          title: `📚 Assignment Due in ${window.label}: ${assignment.title}`,
          body: `Don't miss the deadline! Submit your assignment now.`,
          type: 'assignment',
          assignmentId: assignment._id,
          priority: 'urgent',
        });
      }
    }
  } catch (error) {
    logger.error(`Scheduler error (deadline reminders): ${error.message}`);
  }
};

/**
 * Start all cron jobs
 */
const startScheduler = () => {
  // Check scheduled reminders every minute
  cron.schedule('* * * * *', processScheduledReminders);

  // Check deadline auto-reminders every 5 minutes
  cron.schedule('*/5 * * * *', processDeadlineReminders);

  logger.info('📅 Cron scheduler started');
};

module.exports = { startScheduler };

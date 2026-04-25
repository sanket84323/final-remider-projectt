# CampusSync 🎓
## Secure Academic Management and Notification System

A full-stack mobile application for college students, teachers, and admins built with **Flutter + Node.js + MongoDB**.

---

## 🏗 Project Structure

```
campussync/
├── backend/          # Node.js + Express + MongoDB
└── frontend/         # Flutter mobile app
```

---

## 🚀 Quick Start

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy env file and configure
cp .env.example .env

# Start MongoDB (ensure it's running on localhost:27017)

# Seed sample data
npm run seed

# Start dev server
npm run dev
```

**Server runs at:** `http://localhost:5000`

### 2. Flutter Frontend Setup

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on Android emulator (ensure backend is running)
flutter run

# Or run on a specific device
flutter run -d <device-id>
```

> **Note:** Update `AppStrings.baseUrl` in `lib/core/constants/app_constants.dart`:
> - Android emulator: `http://10.0.2.2:5000/api`
> - iOS simulator: `http://localhost:5000/api`
> - Physical device: `http://<your-local-ip>:5000/api`

---

## 🔑 Demo Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@campussync.edu | Admin@123 |
| Teacher | anita@campussync.edu | Teacher@123 |
| Teacher | vikram@campussync.edu | Teacher@123 |
| Student | arjun@student.edu | Student@123 |
| Student | priya.s@student.edu | Student@123 |

---

## 🔥 Firebase (FCM) Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Add an Android app with package name `com.campussync.app`
3. Download `google-services.json` → place in `frontend/android/app/`
4. Get Admin SDK credentials → add to backend `.env`

---

## ☁️ Cloudinary Setup

1. Create account at [cloudinary.com](https://cloudinary.com) (free tier)
2. Get Cloud Name, API Key, API Secret from dashboard
3. Add to backend `.env`

---

## 📡 API Documentation

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with email/password |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout (clears FCM token) |
| POST | `/api/auth/forgot-password` | Request password reset |

### Reminders
| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/api/reminders` | Any (role-filtered) |
| POST | `/api/reminders` | Teacher/Admin |
| GET | `/api/reminders/:id` | Any |
| PUT | `/api/reminders/:id` | Teacher/Admin |
| DELETE | `/api/reminders/:id` | Teacher/Admin |
| GET | `/api/reminders/:id/read-receipts` | Teacher/Admin |

### Assignments
| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/api/assignments` | Any |
| POST | `/api/assignments` | Teacher |
| GET | `/api/assignments/:id` | Any |
| PUT | `/api/assignments/:id/complete` | Student |
| DELETE | `/api/assignments/:id` | Teacher/Admin |

### Notifications
| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/api/notifications` | Any |
| PUT | `/api/notifications/mark-all-read` | Any |
| PUT | `/api/notifications/:id/read` | Any |
| DELETE | `/api/notifications/:id` | Any |

---

## 🛡 Security Features

- ✅ bcrypt password hashing (salt rounds: 12)
- ✅ JWT access tokens (15min) + refresh tokens (7 days)
- ✅ JWT middleware on all private routes
- ✅ Role-based access control (student/teacher/admin)
- ✅ Helmet.js security headers
- ✅ Rate limiting (100 req/15min, auth: 10/15min)
- ✅ Input validation with express-validator
- ✅ Secure token storage with flutter_secure_storage
- ✅ Automatic token refresh in Flutter Dio interceptor

---

## 📱 App Features by Role

### Student
- View personalized dashboard with reminders, assignments, stats
- Real-time push notifications via FCM
- Calendar view for all deadlines and events
- Mark assignments as completed
- View attachment files (PDF, images, docs)
- Dark mode support

### Teacher  
- Create and schedule reminders (send now or later)
- Target specific class, section, department, or all students
- Set urgency levels (normal/important/urgent)
- View read receipts and engagement stats
- Create assignments with due dates
- Pin important reminders

### Admin
- Full user management (CRUD)
- Department and class management
- College-wide announcements
- Analytics dashboard with charts
- Activity logs and audit trail

---

## 🏛 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Frontend | Flutter 3.x |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Backend | Node.js + Express |
| Database | MongoDB + Mongoose |
| Authentication | JWT (access + refresh) |
| Push Notifications | Firebase Cloud Messaging |
| File Uploads | Cloudinary |
| Cron Jobs | node-cron |
| Logging | Winston |
| Security | Helmet, bcrypt, express-validator |

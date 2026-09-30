# WCU Gibi Gubae — Wachemo University EOTC Student Fellowship Platform

**WCU Gibi Gubae** (`wcu_orthodox`) is a full-featured Flutter mobile and web platform built for the **Wachemo University Ethiopian Orthodox Tewahedo Church (EOTC) Student Fellowship** (*የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ*).

It connects campus students, Spiritual Parents (*መንፈሳዊ አባትና እናት*), Department Coordinators across all 10 canonical fellowship ministries, and Fellowship Administrators in a unified real-time ecosystem with offline/demo resilience.

---

## ✨ Key Features & Modules

### 1. Spiritual Family Network & Smart Cohort Matching (`FamilyState`)
- Pairs junior students with senior **Spiritual Fathers** (always male) and **Spiritual Mothers** (always female).
- **Smart Department Cohort Matching**: Groups students by academic faculty/department so classmates study and grow together under matching senior mentors.
- Direct one-tap **Telegram family group** invitations, call, and SMS shortcuts.

### 2. 10 Canonical EOTC Fellowship Departments (`MinistryState` & `CoordinatorHubScreen`)
Dedicated coordinator control rooms and scoped Role-Based Access Control (RBAC) for all 10 departments:
1. **Education & Apostolic Ministry** (*ትምህርትና ሐዋርያዊ አገልግሎት*) — Course broadcasts, special guest preacher schedules, and curriculum roadmaps.
2. **Member Care, Counseling & Capacity** (*አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ*) — Confidential student emergency aid review & family matching.
3. **Music, Hymnography & Sacred Arts** (*መዝሙርና ስነ ጥበባት*) — Dual-wing management for Yaredic Choir (*መዝሙር*) and Sacred Arts (*ስነ ጥበባት*).
4. **Development & Fundraising** (*ልማትና ገቢ አሰባሰብ*) — Structured fundraising proposal drafting, templates, and financial ROI tracking.
5. **Accounting & Property Management** (*ሒሳብና ንብረት*) — Fellowship treasury and property tracking.
6. **Batch & Programs Coordination** (*ባችና መርሐ ግብራት ማስተባበሪያ*) — Monastery pilgrimage trip planning, bus seat assignment, and QR boarding passes.
7. **Vocational & Charitable Activities** (*ሙያና በጎ አድራጎት*) — Mutual aid campaigns, monthly dues verification, and disbursement vouchers.
8. **Language & Special Needs** (*ቋንቋና ልዩ ልዩ ፍላጎት*) — Multi-lingual ministry support and inclusive fellowship access.
9. **Planning & Monitoring** (*እቅድና ክትትል*) — Annual KPIs and strategic milestone tracking.
10. **Audit & Inspection** (*ኦዲትና ኢንስፔክሽን*) — Strict read-only inspection access across all departments and ledgers.

### 3. Monastery Pilgrimage & QR Bus Boarding (`PilgrimageState`)
- Browse upcoming monastery pilgrimages (*መንፈሳዊ ጉዞ*), view itineraries and packing checklists, and submit Telebirr / CBE Birr payment references.
- Generates a personal **QR E-Ticket Pass** with assigned Bus & Seat numbers for coordinator scanning.

### 4. Student Mutual Aid & Charity Treasury (`CharityState`)
- Confidential **Emergency Aid Requests** (Medical, Meal/Cafeteria, Educational Materials, Transport).
- Transparent inflow/outflow ledger with Telebirr, CBE Birr, and Cash receipt verification.

### 5. Spiritual Life, Liturgical Calendar & Confessor Booking (`SpiritualState` & `ConfessorState`)
- **Ethiopian Liturgical Calendar** & fasting tracker (*ሰባቱ አጽዋማት*).
- **Daily Prayer Book** (*ውዳሴ ማርያም* & *ጸሎት ዘዘወትር*) with adjustable Ethiopic typography (`NotoSansEthiopic`).
- **Confessor Father Booking** (*ንስሐ አባት*) and anonymous spiritual Q&A.
- **Faith Challenge Trivia** (`TriviaState`) with real-time Spiritual Family leaderboards.

---

## 🏗️ Modular Architecture

```text
lib/
├── main.dart                          # App entry point, Auth stream & error boundary banner
├── models/
│   ├── app_models.dart                # Barrel export for all 15 domain model files
│   ├── user_models.dart               # UserRole, FellowshipDepartmentConstants, UserModel
│   ├── family_models.dart             # SpiritualParentModel, FamilyModel
│   ├── pilgrimage_models.dart         # PilgrimageTripModel, TripRegistrationModel
│   ├── charity_models.dart            # CharityCampaignModel, DuesPaymentModel, EmergencyAidRequestModel
│   ├── ministry_models.dart           # MinistryModel, VolunteerApplicationModel, DepartmentMemberModel
│   ├── broadcast_models.dart          # DepartmentBroadcastMessageModel
│   ├── fundraising_models.dart        # FundraisingProposalModel
│   ├── confessor_models.dart          # ConfessorFatherModel, ConfessionAppointmentModel
│   ├── spiritual_models.dart          # DailyScriptureModel, EthiopianCalendarDay, PrayerBookModel
│   ├── attendance_models.dart         # AttendanceRecordModel, AttendanceSessionModel
│   ├── roadmap_models.dart            # LessonModel, RoadmapPhaseModel
│   ├── library_models.dart            # LibraryItemModel
│   ├── program_models.dart            # ChurchProgramModel
│   ├── mentorship_models.dart         # AcademicMentorModel, MentorshipRequestModel
│   └── trivia_models.dart             # TriviaQuizModel, QuizAttemptModel, FamilyLeaderboardEntry
├── state/
│   ├── fellowship_state.dart          # Root state composing feature-slice ChangeNotifiers
│   ├── auth_state.dart                # AuthState & RBAC permission guards
│   ├── family_state.dart              # FamilyState & smart cohort matching algorithm
│   ├── pilgrimage_state.dart          # PilgrimageState & QR ticket verification
│   ├── charity_state.dart             # CharityState & mutual aid ledger
│   ├── ministry_state.dart            # MinistryState & 10 department workflows
│   ├── broadcast_state.dart           # BroadcastState & liturgy countdown
│   ├── library_state.dart             # LibraryState & audio mezmur player state
│   ├── confessor_state.dart           # ConfessorState & anonymous Q&A
│   ├── spiritual_state.dart           # SpiritualState & prayer book reader
│   ├── attendance_state.dart          # AttendanceState & rolling PIN generator
│   ├── roadmap_state.dart             # RoadmapState
│   ├── mentorship_state.dart          # MentorshipState
│   ├── trivia_state.dart              # TriviaState
│   └── mock_data_seeder.dart          # Isolated demo/offline data seeder
├── views/
│   ├── admin/                         # Admin Dashboard, Family Matching, Live QR, Approvals
│   │   └── approvals/                 # Modularized approval tabs (Proposals, Priests, Aid, Roles)
│   ├── coordinator/                   # Coordinator Hub Shell
│   │   └── departments/               # 10 individual department module files
│   ├── student/                       # Student Home, Family, Roadmap, Library, Profile, Scanner
│   └── auth/                          # Firebase Login & Student Registration screens
└── firestore.rules                    # Production Firestore Security Rules (RBAC)
```

---

## 🔥 Firebase Setup & Security Rules

1. **Firebase Configuration**:
   - The project uses `lib/firebase_options.dart` and `android/app/google-services.json`.
   - Enable **Authentication** (Email/Password) and **Cloud Firestore** in the Firebase Console.
2. **Deploy Firestore Security Rules**:
   - Server-side Role-Based Access Control is defined in [`firestore.rules`](firestore.rules).
   - It prevents privilege escalation (users cannot self-assign `admin` or `volunteerCoordinator` roles) and scopes write permissions strictly to authorized department coordinators.
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.1`
- Android Studio / Android SDK (for APK builds)

### Install Dependencies & Run
```bash
flutter pub get
flutter run
```

### Run Automated Tests (Widget & Responsive Overflow Audit)
```bash
flutter test
```

### Build Release APK
```bash
flutter build apk --release
```

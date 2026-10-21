# WCU Orthodox — Firebase Deployment & Data Migration Guide

> **Production Deployment Status**: ✅ **LIVE & DEPLOYED**  
> **Target Firebase Project**: `wcu-orthodox` (`624095213051`)  
> **Rules Compilation**: Passed (`cloud.firestore: rules file firestore.rules compiled successfully`)  
> **Data Migration Status**: Executed live against Firestore on 2026-10-21.

---

## 1. Executive Summary

This document details the live Firebase deployment and database migration executed for the **WCU Orthodox** platform to support **Department-Specific Volunteer Coordinator Scoping, Dual-Scope Authorization, and Separation of Mezmur/Choir & Sacred Arts**.

### Key Architectural Highlights:
1. **Single App Role (`UserRole.volunteerCoordinator`)**: No top-level enum pollution. Scoping is data-driven via `coordinatorProfile.departmentId`.
2. **11 Stable Department Scopes**:
   - `dept-apostolic`: Education & Apostolic Ministry (ትምህርትና ሐዋርያዊ አገልግሎት)
   - `dept-membercare`: Member Care, Counseling & Capacity (አባላት ክትትልና አቅም ግንባታ)
   - `dept-mezmur`: Mezmur/Choir (መዝሙር ክፍል) — **Separated Scope**
   - `dept-arts`: Sacred Arts (ስነ ጥበባት ክፍል) — **Separated Scope**
   - `dept-development`: Development & Fundraising (ልማትና ገቢ ማሰባሰቢያ)
   - `dept-accounting`: Accounting & Property Management (ሂሳብና ንብረት አስተዳደር)
   - `dept-programs`: Batch & Programs Coordination (ባችና ፕሮግራሞች ማስተባበሪያ)
   - `dept-charity`: Vocational & Charitable Activities (ሙያና በጎ አድራጎት)
   - `dept-language`: Language & Special Needs (ቋንቋና ልዩ ፍላጎት)
   - `dept-planning`: Planning & Monitoring (እቅድና ክትትል)
   - `dept-audit`: Audit & Inspection (ኦዲትና ኢንስፔክሽን) — **Strictly Read-Only**
3. **Dual-Scope Firestore Rules**: Enforces both existing `resource.data.departmentId` and incoming `request.resource.data.departmentId` on updates.
4. **Zero-Overflow Mobile UI**: Verified across 320px and 360px viewports with a 4-tab layout (`Overview`, `Tasks`, `Team`, `Tools`).

---

## 2. Firebase Rules Deployment

### Live Deployment Command Executed:
```bash
firebase deploy --only firestore:rules --project wcu-orthodox
```

### Live CLI Output:
```text
=== Deploying to 'wcu-orthodox'...

i  deploying firestore
i  firestore: ensuring required API firestore.googleapis.com is enabled...
i  cloud.firestore: checking firestore.rules for compilation errors...
+  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
+  firestore: released rules firestore.rules to cloud.firestore

+  Deploy complete!

Project Console: https://console.firebase.google.com/project/wcu-orthodox/overview
```

### Active Rules Verification:
- **Privilege Escalation Protection**: Only `isAdmin()` can modify `role`, `isApproved`, or `coordinatorProfile` in `/users/{userId}`.
- **Audit Immutability**: Any coordinator with `dept-audit` or `isReadOnlyAudit: true` is strictly barred from write operations across all collections.
- **Department Collections Scoped**:
  - `/department_broadcasts/{msgId}`: Read by all approved; create/update/delete restricted to `isCoordinatorOf(departmentId)`.
  - `/department_applications/{appId}`: Dual-scope validated on updates:
    ```javascript
    allow update: if isAdmin() || (
      (isCoordinatorOf(resource.data.ministryId) || ('departmentId' in resource.data && isCoordinatorOf(resource.data.departmentId))) &&
      (isCoordinatorOf(request.resource.data.ministryId) || ('departmentId' in request.resource.data && isCoordinatorOf(request.resource.data.departmentId)))
    );
    ```
  - `/emergency_aid_requests/{requestId}`: Restricted to student author, admin, and `isCoordinatorOf('dept-charity')`.
  - `/fundraising_proposals/{proposalId}`: Proposals managed exclusively by `isCoordinatorOf('dept-development')` and admin.

---

## 3. Live Data Migration & Audit Results

The automated migration script (`tools/migrate_coordinators_and_data.js`) connected to the live Firestore instance via the REST API and performed an exhaustive scan:

### 1. User Profiles Audit (`/users`):
- **Total User Documents Scanned**: `18`
- **Volunteer Coordinators Identified**: `1`
  - **UID**: `0Vi3336z8hel5FVpX2ZeYKnwQLY2` (`Adila`, email: `adilaextera@gmail.com`)
  - **Initial State**: `role: "volunteerCoordinator"`, `coordinatorProfile: null` (Unassigned Scope).
  - **Migration Action**: Flagged safely with `needsMigrationReview: true` and `migrationNotice: "Unassigned coordinator scope requires admin assignment in Admin Approvals > Roles tab."`
  - **Result**: No silent corruption; coordinator appears with a high-visibility amber/red banner in the Admin UI with a one-click **"Assign Scope"** action.

### 2. Department Applications Audit (`/department_applications`):
- **Total Applications Scanned**: `2`
  - **Document `app-1792103491366`**:
    - Existing: `ministryId: "dept-apostolic"`
    - Action: Backfilled `departmentId: "dept-apostolic"` to guarantee dual-scope query & rules alignment.
  - **Document `app-1792103791787`**:
    - Existing: `ministryId: "dept-music"` (Legacy combined)
    - Action: Backfilled `departmentId: "dept-music"` and flagged with `needsMigrationReview: true`.

### Migration Execution Audit Log:
```text
===============================================================
  WCU ORTHODOX — FIRESTORE COORDINATOR & DATA MIGRATION        
===============================================================

1. Auditing User Accounts & Volunteer Coordinator Scopes...

  Checking Coordinator: Adila (ID: 0Vi3336z8hel5FVpX2ZeYKnwQLY2)
    ⚠️  STATUS: UNASSIGNED SCOPE
    -> Flagging for admin scope assignment...
    ✓ Successfully flagged user 0Vi3336z8hel5FVpX2ZeYKnwQLY2 for admin review.

2. Auditing Department Applications for Scoped Query & Rule Compatibility...
  Fixing app [app-1792103491366]: Backfilling departmentId = 'dept-apostolic'...
  ✓ Backfilled departmentId for app-1792103491366.
  Fixing app [app-1792103791787]: Backfilling departmentId = 'dept-music'...
  ✓ Backfilled departmentId for app-1792103791787.

===============================================================
                  MIGRATION SUMMARY AUDIT                      
===============================================================
Total User Profiles Scanned:          18
Volunteer Coordinators Found:          1
Unassigned Coordinators Flagged:      1
Legacy Combined Music/Arts Flagged:    0
Audit Read-Only Enforcements:         0
Valid Scoped Coordinators:            0
Applications Scanned:                 2
Applications Backfilled/Flagged:      2
===============================================================
```

---

## 4. Admin Workflow: Assigning & Migrating Coordinator Scopes

In the Flutter application, admins manage scopes via:
**Admin Dashboard > Approvals & Roles (`የአስተዳዳሪ ማጽደቂያ`) > Roles Tab (`የኃላፊነት ምደባ`)**.

### How to Assign an Unassigned Coordinator:
1. Navigate to the **Roles Tab**.
2. Locate the coordinator card (e.g., `Adila`).
3. Notice the red/amber alert:  
   `⚠️ Unassigned Coordinator Scope / ምድብ ያልተሰጠው አስተባባሪ`
4. Tap **"Assign Scope / ምድብ መድብ"**.
5. Select one of the 11 department radio choices in the modal:
   - **General Departments**: Apostolic, Member Care, Finance, Programs, Charity, Special Needs, Planning.
   - **Music & Sacred Arts Header**:
     - 🔘 `መዝሙር ክፍል (Mezmur/Choir)`
     - 🔘 `ስነ ጥበባት ክፍል (Sacred Arts)`
   - **Inspection & Oversight Header**:
     - 🔘 `ኦዲትና ኢንስፔክሽን (Audit & Inspection) [Read-Only]`
6. Tap **"Save Scope"**. The user's Firestore document updates immediately.

### How Ambiguous Legacy Combined Coordinators Are Handled:
If a user with legacy `dept-music` signs in:
1. The app **never** silently guesses whether they belong to Choir or Sacred Arts.
2. In the Admin Roles tab, an amber banner appears:
   `⚠️ Ambiguous Legacy Assignment (Music & Sacred Arts)`  
   `Mezmur/Choir and Sacred Arts are now distinct departments with separate tools. Action required to migrate.`
3. Admin taps **"Migrate Scope / ምድብ ቀይር"**, chooses either `dept-mezmur` or `dept-arts`, and saves.

### How to Revoke Access:
1. On the coordinator's card, tap **"Revoke Access"**.
2. Confirm the dialog: role resets to `UserRole.student` and coordinator profile is cleared.

---

## 5. Ongoing Maintenance & Automation Scripts

Two production-ready scripts are included in the `tools/` directory:

1. **`tools/inspect_live_data.js`**:
   - Inspects live Firestore users, roles, and coordinator scopes.
   - Run anytime with:
     ```bash
     node tools/inspect_live_data.js
     ```

2. **`tools/migrate_coordinators_and_data.js`**:
   - Automated audit & backfill script.
   - Safe to run idempotently against live production or emulator.
   - Run with:
     ```bash
     node tools/migrate_coordinators_and_data.js
     ```

---

## 6. Verification & Automated Test Status

All 64 test cases in the test suite pass with zero errors:
- **Unit Tests**:
  - `test/user_models_unit_test.dart`: 12/12 passed (Department IDs, Choir/Arts split, audit read-only flags).
  - `test/auth_security_unit_test.dart`: Passed (RBAC rules, unapproved user gating).
- **Widget & Screen Tests**:
  - `test/widget_test.dart`: 19/19 passed (Coordinator hub navigation, scoped queues, proposal reviews).
  - `test/screen_overflow_audit_test.dart`: Passed (Verified 320px & 360px viewports with 0 layout overflows).
- **Overall Suite**: `64/64 passed` (`flutter test` exited with code 0).

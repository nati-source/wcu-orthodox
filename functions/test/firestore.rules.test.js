'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { after, before, describe, it } = require('mocha');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'wcu-orthodox-security-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8'),
    },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, 'users/student-1'), {
      role: 'student', isApproved: true, fullName: 'Test Student',
    });
    await setDoc(doc(firestore, 'users/charity-1'), {
      role: 'volunteerCoordinator', isApproved: true, fullName: 'Test Coordinator',
      coordinatorProfile: { departmentId: 'dept-charity', isReadOnlyAudit: false },
    });
    await setDoc(doc(firestore, 'users/admin-1'), {
      role: 'admin', isApproved: true, fullName: 'Test Admin',
    });
    await setDoc(doc(firestore, 'trivia_public_quizzes/quiz-1'), {
      title: 'Visible quiz', questions: [{ id: 'q1', options: ['A', 'B'] }],
    });
    await setDoc(doc(firestore, 'trivia_answer_keys/quiz-1'), {
      answers: [{ id: 'q1', correctOptionIndex: 1 }],
    });
    await setDoc(doc(firestore, 'trivia_quizzes/legacy-1'), {
      title: 'Legacy', questions: [{ correctOptionIndex: 0 }],
    });
    await setDoc(doc(firestore, 'charity_campaigns/campaign-1'), {
      title: 'Campaign', targetAmount: 1000, raisedAmount: 100, donorsCount: 1,
    });
    await setDoc(doc(firestore, 'charity_disbursements/disb-1'), {
      amount: 10, beneficiaryName: 'Student',
    });
    await setDoc(doc(firestore, 'financial_dues/due-1'), {
      studentId: 'student-1', studentName: 'Test Student', amount: 5,
      transactionReference: 'x', status: 'Pending',
    });
    await setDoc(doc(firestore, 'emergency_aid_requests/aid-1'), {
      studentId: 'student-1', status: 'underReview', amountRequested: 100,
    });
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

describe('Firestore security boundaries for quiz and charity records', () => {
  it('lets approved students read sanitized quizzes but not legacy keys or answer keys', async () => {
    const firestore = testEnv.authenticatedContext('student-1').firestore();
    await assertSucceeds(getDoc(doc(firestore, 'trivia_public_quizzes/quiz-1')));
    await assertFails(getDoc(doc(firestore, 'trivia_answer_keys/quiz-1')));
    await assertFails(getDoc(doc(firestore, 'trivia_quizzes/legacy-1')));
  });

  it('blocks students from creating attempts or changing leaderboard scores', async () => {
    const firestore = testEnv.authenticatedContext('student-1').firestore();
    await assertFails(setDoc(doc(firestore, 'quiz_attempts/quiz-1_student-1'), {
      studentId: 'student-1', quizId: 'quiz-1', score: 2, totalQuestions: 2,
    }));
    await assertFails(setDoc(doc(firestore, 'trivia_scores/student-1'), {
      studentUid: 'student-1', totalScore: 500, quizzesCompleted: 1,
    }));
  });

  it('blocks coordinators from direct campaign, disbursement, payment verification, and aid writes', async () => {
    const firestore = testEnv.authenticatedContext('charity-1').firestore();
    await assertFails(updateDoc(doc(firestore, 'charity_campaigns/campaign-1'), {
      title: 'Tampered campaign', raisedAmount: 1000000,
    }));
    await assertFails(deleteDoc(doc(firestore, 'charity_campaigns/campaign-1')));
    await assertFails(setDoc(doc(firestore, 'charity_disbursements/forged'), {
      amount: 50000, beneficiaryName: 'Forged',
    }));
    await assertFails(updateDoc(doc(firestore, 'financial_dues/due-1'), { status: 'Verified' }));
    await assertFails(updateDoc(doc(firestore, 'emergency_aid_requests/aid-1'), { status: 'disbursed' }));
  });

  it('blocks client writes to answer keys even for admins', async () => {
    const firestore = testEnv.authenticatedContext('admin-1').firestore();
    await assertFails(setDoc(doc(firestore, 'trivia_answer_keys/quiz-2'), {
      answers: [{ id: 'q1', correctOptionIndex: 0 }],
    }));
  });

  it('blocks client read and write access to charity voucher refs for all roles', async () => {
    const studentDb = testEnv.authenticatedContext('student-1').firestore();
    const charityDb = testEnv.authenticatedContext('charity-1').firestore();
    const adminDb = testEnv.authenticatedContext('admin-1').firestore();

    await assertFails(getDoc(doc(studentDb, 'charity_voucher_refs/hash-1')));
    await assertFails(setDoc(doc(studentDb, 'charity_voucher_refs/hash-1'), { voucher: 'test' }));
    await assertFails(setDoc(doc(charityDb, 'charity_voucher_refs/hash-2'), { voucher: 'test' }));
    await assertFails(setDoc(doc(adminDb, 'charity_voucher_refs/hash-3'), { voucher: 'test' }));
  });

  it('blocks coordinators from creating campaigns directly without cloud callable', async () => {
    const firestore = testEnv.authenticatedContext('charity-1').firestore();
    await assertFails(setDoc(doc(firestore, 'charity_campaigns/direct-created'), {
      title: 'Direct Campaign', targetAmount: 50000, raisedAmount: 0, donorsCount: 0,
    }));
  });
});


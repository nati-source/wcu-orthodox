'use strict';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { after, before, describe, it } = require('mocha');
const admin = require('firebase-admin');
const api = require('../index');

const db = admin.firestore();
const uid = {
  student: 'api-test-student',
  unapproved: 'api-test-unapproved',
  education: 'api-test-education-coordinator',
  charity: 'api-test-charity-coordinator',
  accounting: 'api-test-accounting-coordinator',
  memberCare: 'api-test-membercare-coordinator',
};

function auth(uidValue) {
  return uidValue ? { uid: uidValue, token: {} } : null;
}

function call(functionHandler, uidValue, data = {}) {
  return functionHandler.run({ auth: auth(uidValue), data });
}

async function expectCode(promise, expectedCode) {
  await assert.rejects(promise, (error) => error.code === expectedCode);
}

function voucherKey(value) {
  return crypto.createHash('sha256').update(value.toUpperCase()).digest('hex');
}

before(async () => {
  await Promise.all([
    db.collection('users').doc(uid.student).set({
      role: 'student', isApproved: true, fullName: 'API Test Student',
    }),
    db.collection('users').doc(uid.unapproved).set({
      role: 'student', isApproved: false, fullName: 'Unapproved Test Student',
    }),
    db.collection('users').doc(uid.education).set({
      role: 'volunteerCoordinator', isApproved: true,
      coordinatorProfile: { departmentId: 'dept-education', isReadOnlyAudit: false },
    }),
    db.collection('users').doc(uid.charity).set({
      role: 'volunteerCoordinator', isApproved: true, fullName: 'Test Charity Officer',
      coordinatorProfile: { departmentId: 'dept-charity', isReadOnlyAudit: false },
    }),
    db.collection('users').doc(uid.accounting).set({
      role: 'volunteerCoordinator', isApproved: true,
      coordinatorProfile: { departmentId: 'dept-accounting', isReadOnlyAudit: false },
    }),
    db.collection('users').doc(uid.memberCare).set({
      role: 'volunteerCoordinator', isApproved: true,
      coordinatorProfile: { departmentId: 'dept-membercare', isReadOnlyAudit: false },
    }),
  ]);
});

after(async () => {
  await admin.app().delete();
});

describe('Callable API integration with the Firestore emulator', () => {
  it('rejects unauthenticated and unapproved callers', async () => {
    await expectCode(call(api.saveCharityCampaign, null), 'unauthenticated');
    await expectCode(call(api.saveCharityCampaign, uid.unapproved), 'permission-denied');
  });

  it('publishes quizzes without exposing keys and scores a student once', async () => {
    const quizId = 'api-test-quiz';
    const saved = await call(api.saveTriviaQuiz, uid.education, {
      quizId,
      weekNumber: 2,
      title: 'API integration quiz',
      description: 'Synthetic test fixture',
      questions: [{
        id: 'question-1',
        questionAmharic: 'የፈተና ጥያቄ',
        questionEnglish: 'Test question',
        options: ['Incorrect', 'Correct'],
        correctOptionIndex: 1,
        explanation: 'Synthetic answer explanation',
      }],
    });

    assert.deepEqual(saved, { quizId });
    const publicQuiz = await db.collection('trivia_public_quizzes').doc(quizId).get();
    const answerKey = await db.collection('trivia_answer_keys').doc(quizId).get();
    assert.equal(publicQuiz.get('questions')[0].correctOptionIndex, undefined);
    assert.equal(answerKey.get('answers')[0].correctOptionIndex, 1);

    const firstAttempt = await call(api.submitTriviaAttempt, uid.student, {
      quizId, selectedAnswers: [1],
    });
    const replayedAttempt = await call(api.submitTriviaAttempt, uid.student, {
      quizId, selectedAnswers: [0],
    });
    assert.equal(firstAttempt.score, 1);
    assert.deepEqual(replayedAttempt, firstAttempt);
    assert.equal((await db.collection('trivia_scores').doc(uid.student).get()).get('quizzesCompleted'), 1);
  });

  it('limits charity mutations by coordinator department', async () => {
    await expectCode(call(api.saveCharityCampaign, uid.student, {
      campaignId: 'api-test-unauthorized-campaign', title: 'Blocked',
      targetAmount: 100, deadline: '2026-12-01',
    }), 'permission-denied');

    const result = await call(api.saveCharityCampaign, uid.charity, {
      campaignId: 'api-test-campaign', title: 'API test campaign',
      targetAmount: 1000, deadline: '2026-12-01', category: 'Student Mutual Aid',
    });
    assert.deepEqual(result, { campaignId: 'api-test-campaign' });
  });

  it('verifies a payment and increments campaign totals only once', async () => {
    const campaignRef = db.collection('charity_campaigns').doc('api-test-campaign');
    const paymentRef = db.collection('financial_dues').doc('api-test-dues');
    await campaignRef.update({ raisedAmount: 20, donorsCount: 2 });
    await paymentRef.set({ amount: 25, campaignId: campaignRef.id, status: 'Pending' });

    const result = await call(api.verifyDuesPayment, uid.accounting, {
      duesId: paymentRef.id, approve: true,
    });
    assert.deepEqual(result, { duesId: paymentRef.id, status: 'Verified' });
    assert.equal((await paymentRef.get()).get('status'), 'Verified');
    assert.equal((await campaignRef.get()).get('raisedAmount'), 45);
    assert.equal((await campaignRef.get()).get('donorsCount'), 3);

    await expectCode(call(api.verifyDuesPayment, uid.accounting, {
      duesId: paymentRef.id, approve: true,
    }), 'failed-precondition');
    assert.equal((await campaignRef.get()).get('raisedAmount'), 45);
  });

  it('rejects reused voucher references for charity disbursements', async () => {
    const request = {
      amount: 10,
      beneficiaryName: 'Synthetic beneficiary',
      assistanceType: 'Meal support',
      paymentMethod: 'cash',
      voucherReference: 'API-TEST-VOUCHER-1',
    };
    const result = await call(api.createCharityDisbursement, uid.charity, request);
    assert.ok(result.disbursementId);

    await expectCode(call(api.createCharityDisbursement, uid.charity, request), 'already-exists');
    const matching = await db.collection('charity_disbursements')
      .where('voucherReference', '==', request.voucherReference).get();
    assert.equal(matching.size, 1);
    assert.equal((await db.collection('charity_voucher_refs').doc(voucherKey(request.voucherReference)).get()).exists, true);
  });

  it('enforces aid amount caps and records a successful disbursement atomically', async () => {
    const beneficiaryId = 'api-test-beneficiary';
    const aidRef = db.collection('emergency_aid_requests').doc('api-test-aid');
    await db.collection('users').doc(beneficiaryId).set({
      role: 'student', isApproved: true, fullName: 'Synthetic Beneficiary',
      phoneNumber: '0000000000',
    });
    await aidRef.set({
      studentId: beneficiaryId, status: 'underReview', amountRequested: 50,
      category: 'meal',
    });

    const overLimit = {
      requestId: aidRef.id, amount: 51, paymentMethod: 'cash',
      voucherReference: 'API-TEST-AID-OVERLIMIT',
    };
    await expectCode(call(api.disburseEmergencyAid, uid.memberCare, overLimit), 'failed-precondition');
    assert.equal((await aidRef.get()).get('status'), 'underReview');
    assert.equal((await db.collection('charity_voucher_refs')
      .doc(voucherKey(overLimit.voucherReference)).get()).exists, false);

    const valid = { ...overLimit, amount: 40, voucherReference: 'API-TEST-AID-VALID' };
    const result = await call(api.disburseEmergencyAid, uid.memberCare, valid);
    assert.ok(result.disbursementId);
    assert.equal((await aidRef.get()).get('status'), 'disbursed');
    assert.equal((await db.collection('charity_disbursements').doc(result.disbursementId).get()).get('amount'), 40);
    await expectCode(call(api.disburseEmergencyAid, uid.memberCare, valid), 'already-exists');
  });

  it('allows one valid aid review and blocks a second review', async () => {
    const aidRef = db.collection('emergency_aid_requests').doc('api-test-aid-review');
    await aidRef.set({ status: 'underReview', studentId: 'api-test-student' });

    const result = await call(api.updateEmergencyAidRequestStatus, uid.memberCare, {
      requestId: aidRef.id, status: 'approved', adminNote: 'Synthetic review',
    });
    assert.deepEqual(result, { requestId: aidRef.id, status: 'approved' });
    assert.equal((await aidRef.get()).get('status'), 'approved');
    await expectCode(call(api.updateEmergencyAidRequestStatus, uid.memberCare, {
      requestId: aidRef.id, status: 'declined',
    }), 'failed-precondition');
  });
});

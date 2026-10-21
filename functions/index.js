'use strict';

const crypto = require('node:crypto');
const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

admin.initializeApp();
const db = admin.firestore();
const { FieldValue } = admin.firestore;
const REGION = 'us-central1';
const PENDING_DUES = new Set(['Pending', 'Pending Verification', 'pendingVerification', 'pending']);
const FINANCE_DEPARTMENTS = ['dept-charity', 'dept-accounting'];
const DISBURSEMENT_METHODS = new Set([
  'Telebirr (ቴሌብር)',
  'CBE Birr (ሲቢኢ ብር)',
  'CBE Account Transfer (የንግድ ባንክ ሒሳብ)',
  'Cash in Hand (በእጅ ጥሬ ገንዘብ)',
  'telebirr', 'cbeBirr', 'cbeAccount', 'cash',
]);

function fail(code, message) {
  throw new HttpsError(code, message);
}

function requiredString(value, name, maxLength, minLength = 1) {
  if (typeof value !== 'string') fail('invalid-argument', `${name} must be text.`);
  const result = value.trim();
  if (result.length < minLength || result.length > maxLength) {
    fail('invalid-argument', `${name} must contain ${minLength}-${maxLength} characters.`);
  }
  return result;
}

function positiveAmount(value, name = 'amount') {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0 || value > 10000000) {
    fail('invalid-argument', `${name} must be greater than 0 and no more than 10,000,000.`);
  }
  return Math.round(value * 100) / 100;
}

function safeId(value, name) {
  const id = requiredString(value, name, 128);
  if (id.includes('/') || id === '.' || id === '..') fail('invalid-argument', `${name} is invalid.`);
  return id;
}

async function callerProfile(request) {
  if (!request.auth) fail('unauthenticated', 'Sign in to continue.');
  const snap = await db.collection('users').doc(request.auth.uid).get();
  if (!snap.exists || snap.get('isApproved') !== true) fail('permission-denied', 'An approved account is required.');
  return { uid: request.auth.uid, data: snap.data() };
}

function hasRole(profile, departments = []) {
  if (profile.data.role === 'admin') return true;
  return profile.data.role === 'volunteerCoordinator' &&
    profile.data.coordinatorProfile &&
    profile.data.coordinatorProfile.isReadOnlyAudit !== true &&
    departments.includes(profile.data.coordinatorProfile.departmentId);
}

async function requireRole(request, departments = []) {
  const profile = await callerProfile(request);
  if (!hasRole(profile, departments)) fail('permission-denied', 'Your assigned role cannot perform this action.');
  return profile;
}

function normalizeQuiz(data) {
  const id = safeId(data.quizId, 'quizId');
  const weekNumber = Number(data.weekNumber ?? 1);
  const timeLimitMinutes = Number(data.timeLimitMinutes ?? 5);
  if (!Number.isInteger(weekNumber) || weekNumber < 1 || weekNumber > 10000) fail('invalid-argument', 'weekNumber is invalid.');
  if (!Number.isInteger(timeLimitMinutes) || timeLimitMinutes < 1 || timeLimitMinutes > 240) fail('invalid-argument', 'timeLimitMinutes must be between 1 and 240.');
  if (!Array.isArray(data.questions) || data.questions.length < 1 || data.questions.length > 100) fail('invalid-argument', 'A quiz must contain between 1 and 100 questions.');

  const answers = [];
  const publicQuestions = data.questions.map((raw, index) => {
    if (!raw || typeof raw !== 'object') fail('invalid-argument', `Question ${index + 1} is invalid.`);
    const options = raw.options;
    if (!Array.isArray(options) || options.length < 2 || options.length > 8 || options.some(o => typeof o !== 'string' || !o.trim() || o.length > 300)) {
      fail('invalid-argument', `Question ${index + 1} needs 2-8 valid answer options.`);
    }
    const correctOptionIndex = raw.correctOptionIndex;
    if (!Number.isInteger(correctOptionIndex) || correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      fail('invalid-argument', `Question ${index + 1} has an invalid answer key.`);
    }
    answers.push({ id: requiredString(raw.id || `q${index + 1}`, `question ${index + 1} id`, 128), correctOptionIndex, explanation: typeof raw.explanation === 'string' ? raw.explanation.slice(0, 1200) : '' });
    return {
      id: requiredString(raw.id || `q${index + 1}`, `question ${index + 1} id`, 128),
      questionAmharic: requiredString(raw.questionAmharic, `question ${index + 1} Amharic text`, 1200),
      questionEnglish: typeof raw.questionEnglish === 'string' ? raw.questionEnglish.slice(0, 1200) : '',
      options: options.map(o => o.trim()),
      bibleReference: typeof raw.bibleReference === 'string' ? raw.bibleReference.slice(0, 120) : '',
    };
  });

  return {
    id,
    publicQuiz: {
      weekNumber,
      title: requiredString(data.title, 'title', 160),
      description: typeof data.description === 'string' ? data.description.slice(0, 1500) : '',
      questions: publicQuestions,
      timeLimitMinutes,
      updatedAt: FieldValue.serverTimestamp(),
    },
    answerKey: { answers, updatedAt: FieldValue.serverTimestamp() },
  };
}

async function writeQuiz(quiz, removeLegacy = false) {
  const batch = db.batch();
  batch.set(db.collection('trivia_public_quizzes').doc(quiz.id), quiz.publicQuiz);
  batch.set(db.collection('trivia_answer_keys').doc(quiz.id), quiz.answerKey);
  if (removeLegacy) batch.delete(db.collection('trivia_quizzes').doc(quiz.id));
  await batch.commit();
}

exports.saveTriviaQuiz = onCall({ region: REGION }, async (request) => {
  await requireRole(request, ['dept-apostolic', 'dept-education']);
  const quiz = normalizeQuiz(request.data || {});
  await writeQuiz(quiz);
  return { quizId: quiz.id };
});

exports.deleteTriviaQuiz = onCall({ region: REGION }, async (request) => {
  await requireRole(request, ['dept-apostolic', 'dept-education']);
  const id = safeId(request.data?.quizId, 'quizId');
  const batch = db.batch();
  batch.delete(db.collection('trivia_public_quizzes').doc(id));
  batch.delete(db.collection('trivia_answer_keys').doc(id));
  batch.delete(db.collection('trivia_quizzes').doc(id));
  await batch.commit();
  return { quizId: id };
});

exports.migrateLegacyTriviaQuizzes = onCall({ region: REGION }, async (request) => {
  await requireRole(request, []);
  const legacy = await db.collection('trivia_quizzes').limit(400).get();
  let migrated = 0;
  let skipped = 0;
  for (const doc of legacy.docs) {
    try {
      const quiz = normalizeQuiz({ ...doc.data(), quizId: doc.id });
      await writeQuiz(quiz, true);
      migrated++;
    } catch (error) {
      skipped++;
      console.warn(`Skipping invalid legacy quiz ${doc.id}`, error.message);
    }
  }
  return { migrated, skipped, remainingMayExist: legacy.size === 400 };
});

exports.submitTriviaAttempt = onCall({ region: REGION }, async (request) => {
  const student = await callerProfile(request);
  if (student.data.role !== 'student') fail('permission-denied', 'Only student accounts can submit quiz attempts.');
  const quizId = safeId(request.data?.quizId, 'quizId');
  const selectedAnswers = request.data?.selectedAnswers;
  if (!Array.isArray(selectedAnswers) || selectedAnswers.length < 1 || selectedAnswers.length > 100 || selectedAnswers.some(a => !Number.isInteger(a))) {
    fail('invalid-argument', 'Submit one selected option index per quiz question.');
  }

  const quizRef = db.collection('trivia_public_quizzes').doc(quizId);
  const keyRef = db.collection('trivia_answer_keys').doc(quizId);
  const attemptRef = db.collection('quiz_attempts').doc(`${quizId}_${student.uid}`);
  const scoreRef = db.collection('trivia_scores').doc(student.uid);
  const familyId = typeof student.data.assignedFamilyId === 'string' ? student.data.assignedFamilyId : '';
  const familyRef = familyId ? db.collection('families').doc(familyId) : null;

  return db.runTransaction(async (tx) => {
    const [quizSnap, keySnap, attemptSnap, scoreSnap, familySnap] = await Promise.all([
      tx.get(quizRef), tx.get(keyRef), tx.get(attemptRef), tx.get(scoreRef),
      familyRef ? tx.get(familyRef) : Promise.resolve(null),
    ]);
    if (!quizSnap.exists || !keySnap.exists) fail('not-found', 'This quiz is unavailable.');
    const questions = quizSnap.get('questions');
    const answerKey = keySnap.get('answers');
    if (!Array.isArray(questions) || !Array.isArray(answerKey) || questions.length !== answerKey.length || selectedAnswers.length !== questions.length) {
      fail('failed-precondition', 'The submitted answers do not match this quiz.');
    }
    if (attemptSnap.exists) {
      if (attemptSnap.get('trustedScoreVersion') !== 1) {
        fail('failed-precondition', 'This quiz was already completed before secure scoring was enabled.');
      }
      return {
        score: Number(attemptSnap.get('score') || 0),
        totalQuestions: Number(attemptSnap.get('totalQuestions') || questions.length),
        familyId: String(attemptSnap.get('familyId') || ''),
        familyName: String(attemptSnap.get('familyName') || ''),
      };
    }
    let score = 0;
    for (let i = 0; i < questions.length; i++) {
      if (!Array.isArray(questions[i].options) || selectedAnswers[i] < 0 || selectedAnswers[i] >= questions[i].options.length) {
        fail('invalid-argument', `The selected answer for question ${i + 1} is invalid.`);
      }
      if (answerKey[i].id !== questions[i].id || !Number.isInteger(answerKey[i].correctOptionIndex)) fail('failed-precondition', 'This quiz answer key is invalid.');
      if (selectedAnswers[i] === answerKey[i].correctOptionIndex) score++;
    }
    const familyName = familySnap?.exists ? String(familySnap.get('name') || '') : '';
    const name = String(student.data.fullName || '');
    tx.create(attemptRef, {
      studentId: student.uid,
      studentName: name,
      familyId,
      familyName,
      quizId,
      score,
      totalQuestions: questions.length,
      completedAt: FieldValue.serverTimestamp(),
      trustedScoreVersion: 1,
    });
    if (scoreSnap.exists && scoreSnap.get('trustedScoreVersion') === 1) {
      tx.update(scoreRef, {
        studentName: name,
        totalScore: Number(scoreSnap.get('totalScore') || 0) + score,
        quizzesCompleted: Number(scoreSnap.get('quizzesCompleted') || 0) + 1,
        lastActive: FieldValue.serverTimestamp(),
      });
    } else {
      tx.set(scoreRef, {
        studentUid: student.uid,
        studentName: name,
        totalScore: score,
        quizzesCompleted: 1,
        lastActive: FieldValue.serverTimestamp(),
        trustedScoreVersion: 1,
      });
    }
    return { score, totalQuestions: questions.length, familyId, familyName };
  });
});

function campaignFields(data) {
  const targetAmount = positiveAmount(data.targetAmount, 'targetAmount');
  const deadline = requiredString(data.deadline, 'deadline', 64);
  if (!Number.isFinite(Date.parse(deadline))) fail('invalid-argument', 'deadline must be a valid date.');
  return {
    title: requiredString(data.title, 'title', 160),
    description: typeof data.description === 'string' ? data.description.slice(0, 2000) : '',
    targetAmount,
    deadline,
    isEmergency: data.isEmergency === true,
    category: requiredString(data.category || 'Student Mutual Aid', 'category', 100),
  };
}

exports.saveCharityCampaign = onCall({ region: REGION }, async (request) => {
  const user = await requireRole(request, ['dept-charity']);
  const id = safeId(request.data?.campaignId, 'campaignId');
  const fields = campaignFields(request.data || {});
  const ref = db.collection('charity_campaigns').doc(id);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      if (fields.targetAmount < Number(snap.get('raisedAmount') || 0)) {
        fail('failed-precondition', 'Campaign target cannot be lower than its recorded donations.');
      }
      tx.update(ref, { ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: user.uid });
    } else {
      tx.create(ref, {
        ...fields,
        raisedAmount: 0,
        donorsCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        createdBy: user.uid,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: user.uid,
      });
    }
  });
  return { campaignId: id };
});

exports.deleteCharityCampaign = onCall({ region: REGION }, async (request) => {
  await requireRole(request, ['dept-charity']);
  const id = safeId(request.data?.campaignId, 'campaignId');
  const ref = db.collection('charity_campaigns').doc(id);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    if (Number(snap.get('raisedAmount') || 0) > 0 || Number(snap.get('donorsCount') || 0) > 0) {
      fail('failed-precondition', 'A campaign with recorded donations cannot be deleted.');
    }
    const dues = await tx.get(db.collection('financial_dues').where('campaignId', '==', id).limit(1));
    if (!dues.empty) fail('failed-precondition', 'A campaign linked to a payment record cannot be deleted.');
    tx.delete(ref);
  });
  return { campaignId: id };
});

exports.verifyDuesPayment = onCall({ region: REGION }, async (request) => {
  const verifier = await requireRole(request, FINANCE_DEPARTMENTS);
  const duesId = safeId(request.data?.duesId, 'duesId');
  if (typeof request.data?.approve !== 'boolean') fail('invalid-argument', 'approve must be true or false.');
  const paymentRef = db.collection('financial_dues').doc(duesId);
  await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (!paymentSnap.exists) fail('not-found', 'Payment record not found.');
    if (!PENDING_DUES.has(String(paymentSnap.get('status')))) fail('failed-precondition', 'This payment has already been reviewed.');
    const campaignId = paymentSnap.get('campaignId');
    let campaignSnap = null;
    let campaignRef = null;
    const amount = positiveAmount(Number(paymentSnap.get('amount')), 'payment amount');
    if (request.data.approve && typeof campaignId === 'string' && campaignId) {
      campaignRef = db.collection('charity_campaigns').doc(campaignId);
      campaignSnap = await tx.get(campaignRef);
      if (!campaignSnap.exists) fail('failed-precondition', 'The linked campaign no longer exists.');
    }
    tx.update(paymentRef, {
      status: request.data.approve ? 'Verified' : 'Declined',
      verifiedAt: FieldValue.serverTimestamp(),
      verifiedBy: verifier.uid,
    });
    if (campaignSnap && campaignRef) {
      tx.update(campaignRef, {
        raisedAmount: Number(campaignSnap.get('raisedAmount') || 0) + amount,
        donorsCount: Number(campaignSnap.get('donorsCount') || 0) + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  return { duesId, status: request.data.approve ? 'Verified' : 'Declined' };
});

function voucherRefFor(value) {
  const voucher = requiredString(value, 'voucherReference', 100, 2);
  return { voucher, key: crypto.createHash('sha256').update(voucher.toUpperCase()).digest('hex') };
}

exports.createCharityDisbursement = onCall({ region: REGION }, async (request) => {
  const officer = await requireRole(request, ['dept-charity', 'dept-accounting']);
  const amount = positiveAmount(request.data?.amount);
  const beneficiaryName = requiredString(request.data?.beneficiaryName, 'beneficiaryName', 200, 2);
  const assistanceType = requiredString(request.data?.assistanceType, 'assistanceType', 120, 2);
    const paymentMethod = requiredString(request.data?.paymentMethod, 'paymentMethod', 100);
    if (!DISBURSEMENT_METHODS.has(paymentMethod)) fail('invalid-argument', 'Choose a supported disbursement channel.');
  const { voucher, key } = voucherRefFor(request.data?.voucherReference);
  const notes = typeof request.data?.notes === 'string' ? request.data.notes.slice(0, 1000) : '';
  const disbursementRef = db.collection('charity_disbursements').doc();
  const voucherRef = db.collection('charity_voucher_refs').doc(key);
  await db.runTransaction(async (tx) => {
    const currentVoucher = await tx.get(voucherRef);
    if (currentVoucher.exists) fail('already-exists', 'This voucher reference has already been used.');
    tx.create(voucherRef, { createdAt: FieldValue.serverTimestamp(), disbursementId: disbursementRef.id });
    tx.create(disbursementRef, {
      beneficiaryName,
      assistanceType,
      amount,
        paymentMethod,
      voucherReference: voucher,
      approvedBy: String(officer.data.fullName || 'Authorized Officer'),
      approvedByUid: officer.uid,
      disbursedAt: FieldValue.serverTimestamp(),
      notes,
      createdBy: officer.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { disbursementId: disbursementRef.id };
});

exports.disburseEmergencyAid = onCall({ region: REGION }, async (request) => {
  const officer = await requireRole(request, ['dept-charity', 'dept-membercare', 'dept-accounting']);
  const requestId = safeId(request.data?.requestId, 'requestId');
  const amount = positiveAmount(request.data?.amount);
  const { voucher, key } = voucherRefFor(request.data?.voucherReference);
  const paymentMethod = requiredString(request.data?.paymentMethod, 'paymentMethod', 100);
  if (!DISBURSEMENT_METHODS.has(paymentMethod)) fail('invalid-argument', 'Choose a supported disbursement channel.');
  const notes = typeof request.data?.note === 'string' ? request.data.note.slice(0, 1000) : '';
  const aidRef = db.collection('emergency_aid_requests').doc(requestId);
  const officerRef = db.collection('users').doc(officer.uid);
  const voucherRef = db.collection('charity_voucher_refs').doc(key);
  const disbursementRef = db.collection('charity_disbursements').doc();

  await db.runTransaction(async (tx) => {
    const [aidSnap, voucherSnap] = await Promise.all([tx.get(aidRef), tx.get(voucherRef)]);
    if (!aidSnap.exists) fail('not-found', 'Emergency aid request not found.');
    if (voucherSnap.exists) fail('already-exists', 'This voucher reference has already been used.');
    const aidStatus = String(aidSnap.get('status') || '');
    const adminApproveAndDisburse = officer.data.role === 'admin' &&
      ['underReview', 'submitted', 'pending'].includes(aidStatus);
    if (aidStatus !== 'approved' && !adminApproveAndDisburse) {
      fail('failed-precondition', 'Approve the aid request before disbursing it.');
    }
    const requestedAmount = Number(aidSnap.get('amountRequested'));
    if (!Number.isFinite(requestedAmount) || requestedAmount <= 0 || amount > requestedAmount) {
      fail('failed-precondition', 'Disbursement cannot exceed the approved request amount.');
    }
    const beneficiaryId = String(aidSnap.get('studentId') || '');
    if (!beneficiaryId) fail('failed-precondition', 'The aid request has no beneficiary.');
    const beneficiaryRef = db.collection('users').doc(beneficiaryId);
    const [beneficiarySnap, officerSnap] = await Promise.all([tx.get(beneficiaryRef), tx.get(officerRef)]);
    if (!beneficiarySnap.exists) fail('failed-precondition', 'Beneficiary account not found.');
    const fullName = String(beneficiarySnap.get('fullName') || 'Student');
    const baptismalName = String(beneficiarySnap.get('baptismalName') || '');
    const phone = String(beneficiarySnap.get('phoneNumber') || '');
    const category = String(aidSnap.get('category') || 'other');
    const note = notes || `Emergency aid disbursed via ${paymentMethod}.`;
    tx.create(voucherRef, { createdAt: FieldValue.serverTimestamp(), disbursementId: disbursementRef.id });
    tx.create(disbursementRef, {
      beneficiaryId,
      aidRequestId: requestId,
      beneficiaryName: [fullName, baptismalName, phone].filter(Boolean).join(' • '),
      assistanceType: category,
      amount,
      paymentMethod,
      voucherReference: voucher,
      approvedBy: String(officerSnap.get('fullName') || 'Authorized Officer'),
      approvedByUid: officer.uid,
      disbursedAt: FieldValue.serverTimestamp(),
      notes: note,
      createdBy: officer.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(aidRef, {
      status: 'disbursed',
      adminNote: note,
      ...(adminApproveAndDisburse ? { reviewedBy: officer.uid, reviewedAt: FieldValue.serverTimestamp() } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { disbursementId: disbursementRef.id };
});

exports.updateEmergencyAidRequestStatus = onCall({ region: REGION }, async (request) => {
  const reviewer = await requireRole(request, ['dept-membercare']);
  const requestId = safeId(request.data?.requestId, 'requestId');
  const status = request.data?.status;
  if (!['approved', 'declined'].includes(status)) fail('invalid-argument', 'Aid requests may be approved or declined.');
  const adminNote = typeof request.data?.adminNote === 'string' ? request.data.adminNote.slice(0, 1000) : '';
  const ref = db.collection('emergency_aid_requests').doc(requestId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) fail('not-found', 'Emergency aid request not found.');
    if (!['underReview', 'submitted', 'pending'].includes(String(snap.get('status')))) fail('failed-precondition', 'This request has already been reviewed.');
    tx.update(ref, {
      status,
      adminNote,
      reviewedBy: reviewer.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { requestId, status };
});

const express = require('express');
const router = express.Router();
const reminderController = require('./reminder.controller');
const { protect } = require('../../middlewares/authMiddleware');

router.route('/')
    .post(protect, reminderController.createReminder)
    .get(protect, reminderController.getReminders);

router.route('/:id')
    .get(protect, reminderController.getReminderById)
    .put(protect, reminderController.updateReminder)
    .delete(protect, reminderController.deleteReminder);

module.exports = router;
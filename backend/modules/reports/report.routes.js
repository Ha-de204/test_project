const express = require('express');
const router = express.Router();
const reportController = require('./report.controller');
const { protect } = require('../../middlewares/authMiddleware');

router.get('/summary', protect, reportController.getSummary);
router.get('/category-breakdown', protect, reportController.getCategoryBreakdown);
router.get('/monthly-flow', protect, reportController.getMonthlyFlow);

module.exports = router;
const express = require('express');
const router = express.Router();
const budgetController = require('./budget.controller');
const { protect } = require('../../middlewares/authMiddleware');

router.post('/upsert', protect, budgetController.upsertBudget);
router.get('/details', protect, budgetController.getBudgets);
router.delete('/:id', protect, budgetController.deleteBudget);

module.exports = router;
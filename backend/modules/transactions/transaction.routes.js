const express = require('express');
const router = express.Router();
const transactionController = require('./transaction.controller');
const { protect } = require('../../middlewares/authMiddleware');

router.post('/create', protect, transactionController.createTransaction);
router.get('/list',protect, transactionController.getTransactions);

router.route('/:id')
    .get(protect, transactionController.getTransactionById)
    .put(protect, transactionController.updateTransaction)
    .delete(protect, transactionController.deleteTransaction);

module.exports = router;
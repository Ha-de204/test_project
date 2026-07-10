const express = require('express');
const router = express.Router();
const categoryController = require('./category.controller');
const { protect } = require('../../middlewares/authMiddleware');

router.get('/list', protect, categoryController.getCategories);
router.post('/create', protect, categoryController.createCategory);
router.route('/:id')
    .put(protect, categoryController.updateCategory)
    .delete(protect, categoryController.deleteCategory);

module.exports = router;
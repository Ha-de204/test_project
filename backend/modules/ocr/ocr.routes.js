const express = require('express');
const router = express.Router();
const ocrController = require('./ocr.controller');
const upload = require('../../middlewares/upload');

router.post('/scan', upload.single('image'), ocrController.scanReceipt);

module.exports = router;

const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const authRoutes = require('./modules/auth/auth.routes');
const categoryRoutes = require('./modules/categories/category.routes');
const transactionRoutes = require('./modules/transactions/transaction.routes');
const reportRoutes = require('./modules/reports/report.routes');
const budgetRoutes = require('./modules/budgets/budget.routes');
const reminderRoutes = require('./modules/reminders/reminder.routes');
const ocrRoutes = require('./modules/ocr/ocr.routes');
const { connectDB } = require('./services/db.service');
const { initWorker } = require('./tesseractWorker');

const uploadDir = path.join(__dirname, 'uploads');

dotenv.config();
const app = express();

if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
    console.log('✅ Đã tạo thư mục uploads tại:', uploadDir);
}

app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/ocr', ocrRoutes);

const PORT = process.env.PORT || 5000;

connectDB().then(async () => {
    await initWorker();

    app.listen(PORT, () => {
        console.log(`Server chạy trên http://localhost:${PORT}`);
    });
}).catch(err => {
    console.error("Server không thể khởi động do lỗi DB:", err);
});
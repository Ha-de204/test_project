const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

const authRoutes = require('./modules/auth/auth.routes');
const categoryRoutes = require('./modules/categories/category.routes');
const transactionRoutes = require('./modules/transactions/transaction.routes');
const reportRoutes = require('./modules/reports/report.routes');
const budgetRoutes = require('./modules/budgets/budget.routes');
const reminderRoutes = require('./modules/reminders/reminder.routes');
const ocrRoutes = require('./modules/ocr/ocr.routes');
const { connectDB } = require('./services/db.service');

dotenv.config();
const app = express();

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

connectDB().then(() => {
    app.listen(PORT, () => {
        console.log(`Server chạy trên http://localhost:${PORT}`);
    });
}).catch(err => {
    console.error("Server không thể khởi động do lỗi DB:", err);
});
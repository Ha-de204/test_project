const mongoose = require('mongoose');

let isConnected = false;

const connectDB = async () => {
    try {
        if (!isConnected) {
            const dbUri = process.env.MONGO_URI;

            if (!dbUri) {
                throw new Error("MONGO_URI không tồn tại trong biến môi trường!");
            }

            await mongoose.connect(dbUri);
            isConnected = true;
            console.log('Kết nối MongoDB Atlas thành công!');
        }
        return mongoose.connection;
    } catch (err) {
        isConnected = false;
        console.error('Lỗi kết nối MongoDB:', err.message);
    }
};

const executeQuery = async (modelAction) => {
    await connectDB();
    try {
        return await modelAction();
    } catch (err) {
        console.error('Lỗi thực thi dữ liệu MongoDB:', err.message);
        throw err;
    }
};

module.exports = { connectDB, executeQuery, mongoose };
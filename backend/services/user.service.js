const User = require('../models/User');
const mongoose = require('mongoose');

// 1. Tìm người dùng bằng tên (Dùng khi Đăng nhập)
const findUserByUserName = async (userName) => {
    return await User.findOne({ userName: userName });
};

// 2. Tạo người dùng mới (Dùng khi Đăng ký)
const createUser = async (userName, password) => {
    const newUser = new User({
        userName: userName,
        password: password
    });

    const result = await newUser.save();
    return result._id;
};

// 3. Lấy thông tin user bằng ID
const getUserById = async (user_id) => {
    try {
        return await User.findById(user_id).select('-password');
    } catch (err) {
        return null;
    }
};

module.exports = { findUserByUserName, createUser, getUserById };
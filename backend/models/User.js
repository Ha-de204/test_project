const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    password: { type: String, required: true },
    userName: { type: String, required: true, unique: true, min:3, max:100 },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    resetPasswordToken: { type: String, default: null },
    resetPasswordExpires: { type: Date, default: null },
    created_at: { type: Date, default: Date.now }
}, { collection: 'User' });

module.exports = mongoose.model('User', UserSchema);
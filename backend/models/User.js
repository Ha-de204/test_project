const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    password: { type: String, required: true },
    userName: { type: String, required: true, unique: true, min:3, max:100 },
    created_at: { type: Date, default: Date.now }
}, { collection: 'User' });

module.exports = mongoose.model('User', UserSchema);
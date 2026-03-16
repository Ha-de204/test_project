const mongoose = require('mongoose');

const CategorySchema = new mongoose.Schema({
    user_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    name: { type: String, required: true },
    icon_code_point: { type: Number, required: true },
    type: {
        type: String,
        enum: ['expense', 'income'],
        default: 'expense'
    },
    is_default: { type: Boolean, default: false }
}, { collection: 'Category' });

module.exports = mongoose.model('Category', CategorySchema);
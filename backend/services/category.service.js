const Category = require('../models/Category');
const mongoose = require('mongoose');

// 1. Lấy danh mục mặc định và danh mục của user
const getCategoriesByUser = async (user_id) => {
    return await Category.find({
        $or: [
            { is_default: true },
            { user_id: new mongoose.Types.ObjectId(user_id) }
        ]
    }).sort({ is_default: -1, name: 1 });
};

// 2. Tao danh muc mac dinh
const createDefaultCategories = async (user_id) => {
    const defaultCategories = [
        { name: 'Mua sắm', icon_code_point: 0xe59c, type: 'expense' },
        { name: 'Đồ ăn', icon_code_point: 0xe25a, type: 'expense' },
        { name: 'Quần áo', icon_code_point: 0xf5d1, type: 'expense' },
        { name: 'Nhà ở', icon_code_point: 0xe318, type: 'expense' },
        { name: 'Sức khỏe', icon_code_point: 0xe25b, type: 'expense' },
        { name: 'Học tập', icon_code_point: 0xe0ef, type: 'expense' },
        { name: 'Du lịch', icon_code_point: 0xe295, type: 'expense' },
        { name: 'Giải trí', icon_code_point: 0xe6a1, type: 'expense' },
        { name: 'Sửa chữa', icon_code_point: 0xe0af, type: 'expense' },
        { name: 'Sắc đẹp', icon_code_point:0xeb4c, type: 'expense' },
        { name: 'Điện thoại', icon_code_point: 0xe4e2, type: 'expense' },
        { name: 'Cài đặt', icon_code_point: 0xe57f, type: 'expense' },

        { name: 'Lương', icon_code_point: 0xe227, type: 'income' },
        { name: 'Làm thêm', icon_code_point: 0xe8f9, type: 'income' },
        { name: 'Tiền thưởng', icon_code_point: 0xe263, type: 'income' },

    ];

    const categoriesWithUser = defaultCategories.map(cat => ({
        ...cat,
        user_id: new mongoose.Types.ObjectId(user_id),
        is_default: true
    }));

    return await Category.insertMany(categoriesWithUser);
};

// 3. Tạo danh mục mới
const createCategory = async (user_id, name, iconCodePoint, type) => {
    const newCategory = new Category({
        user_id: new mongoose.Types.ObjectId(user_id),
        name: name,
        icon_code_point: iconCodePoint,
         type: type,
        is_default: false
    });

    const result = await newCategory.save();
    return result._id;
};

// 4. Cập nhật danh mục (Chỉ cho phép sửa danh mục riêng của user)
const updateCategory = async (categoryId, user_id, name, iconCodePoint, type) => {
    const result = await Category.updateOne(
        {
            _id: new mongoose.Types.ObjectId(categoryId),
            user_id: new mongoose.Types.ObjectId(user_id),
            is_default: false
        },
        {
            name: name,
            icon_code_point: iconCodePoint,
            type: type
        }
    );

    return result.modifiedCount > 0;
};

// 5. Xóa danh mục
const deleteCategory = async (categoryId, user_id) => {
    const result = await Category.deleteOne({
        _id: new mongoose.Types.ObjectId(categoryId),
        user_id: new mongoose.Types.ObjectId(user_id),
        is_default: false
    });

    return result.deletedCount > 0;
};

module.exports = {
    getCategoriesByUser,
    createCategory,
    updateCategory,
    deleteCategory
};
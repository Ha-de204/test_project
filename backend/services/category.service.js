const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
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

// 2. Tạo danh mục mới
const createCategory = async (user_id, name, iconCodePoint, type) => {
    // Kiểm tra trùng tên
    name = name.trim();

    const existed = await Category.findOne({
        $or: [
            { user_id: new mongoose.Types.ObjectId(user_id) },
            { is_default: true }
        ],
        name,
        type
    });

    if (existed) {
        return {
            success: false,
            message: "Danh mục đã tồn tại."
        };
    }

    const newCategory = new Category({
        user_id: new mongoose.Types.ObjectId(user_id),
        name: name,
        icon_code_point: iconCodePoint,
        type: type,
        is_default: false
    });

    await newCategory.save();
    return {
       success: true
    };
};

// 3. Cập nhật danh mục (Chỉ cho phép sửa danh mục riêng của user)
const updateCategory = async (
    categoryId,
    user_id,
    name,
    iconCodePoint,
    type
) => {

    const category = await Category.findOne({
        _id: new mongoose.Types.ObjectId(categoryId),
        user_id: new mongoose.Types.ObjectId(user_id)
    });

    if (!category) {
        return {
            success: false,
            message: "Không tìm thấy danh mục."
        };
    }

    if (category.is_default) {
        return {
            success: false,
            message: "Danh mục mặc định không thể sửa."
        };
    }

    name = name.trim();

    const existed = await Category.findOne({
        _id: { $ne: category._id },
        $or: [
            { user_id: new mongoose.Types.ObjectId(user_id) },
            { is_default: true }
        ],
        name,
        type
    });

    if (existed) {
        return {
            success: false,
            message: "Danh mục đã tồn tại."
        };
    }

    category.name = name;
    category.icon_code_point = iconCodePoint;
    category.type = type;

    await category.save();

    return {
        success: true
    };
};

// 4. Kiểm tra danh mục đã có giao dịch hay chưa
const isCategoryUsed = async (categoryId) => {
    const transaction = await Transaction.findOne({
        category_id: new mongoose.Types.ObjectId(categoryId)
    });

    return transaction !== null;
};

// 5. Xóa danh mục
const deleteCategory = async (categoryId, user_id) => {

     console.log("categoryId:", categoryId);
     console.log("userId:", user_id);
     const categoryDebug = await Category.findById(categoryId);

    console.log(categoryDebug);
    console.log("category.user_id =", categoryDebug?.user_id?.toString());
    console.log("token.user_id    =", user_id.toString());

    // Lấy thông tin danh mục
    const category = await Category.findOne({
        _id: new mongoose.Types.ObjectId(categoryId),
        user_id: new mongoose.Types.ObjectId(user_id)
    });

    if (!category) {
        return {
            success: false,
            message: "Không tìm thấy danh mục."
        };
    }

    // Không cho xóa danh mục mặc định
    if (category.is_default) {
        return {
            success: false,
            message: "Danh mục mặc định không thể xóa."
        };
    }

    // Kiểm tra đã được dùng chưa
    const used = await isCategoryUsed(categoryId);

    if (used) {
        return {
            success: false,
            message: "Danh mục đã có giao dịch nên không thể xóa."
        };
    }

    await Category.deleteOne({
        _id: category._id
    });

    return {
        success: true
    };
};

module.exports = {
    getCategoriesByUser,
    createCategory,
    updateCategory,
    deleteCategory,
    isCategoryUsed
};
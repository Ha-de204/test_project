const categoryService = require('../../services/category.service');

const getCategories = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";

    try {
        const categories = await categoryService.getCategoriesByUser(user_id);
        res.status(200).json(categories);
    } catch (error) {
        console.error('Lỗi lấy danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi lấy danh mục.' });
    }
};

const createCategory = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const { name, iconCodePoint } = req.body;

    console.log('ID người dùng nhận được trong Controller:', user_id);

    if (!user_id) {
        return res.status(401).json({ message: 'Không được phép. Vui lòng đăng nhập lại.' });
    }

    if (!name || iconCodePoint === undefined) {
        return res.status(400).json({ message: 'Vui lòng cung cấp tên và mã icon.' });
    }

    try {
        const categoryId = await categoryService.createCategory(user_id, name, iconCodePoint);

        res.status(201).json({
            category_id: categoryId,
            name,
            icon_code_point: iconCodePoint,
            message: 'Tạo danh mục thành công.'
        });
    } catch (error) {
        console.error('Lỗi tạo danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi tạo danh mục.' });
    }
};

// update danh muc
const updateCategory = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const categoryId = req.params.id;
    const { name, iconCodePoint } = req.body;

    if (!categoryId || categoryId.length !== 24 || !name || iconCodePoint === undefined) {
        return res.status(400).json({ message: 'Dữ liệu cập nhật hoặc ID danh mục không hợp lệ.' });
    }

    try {
        const updated = await categoryService.updateCategory(
            categoryId,
            user_id,
            name,
            iconCodePoint
        );

        if (!updated) {
            return res.status(404).json({ message: 'Không tìm thấy danh mục để cập nhật hoặc danh mục này là mặc định.' });
        }

        res.status(200).json({ message: 'Cập nhật danh mục thành công.' });
    } catch (error) {
        console.error('Lỗi cập nhật danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// delete danh muc
const deleteCategory = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const categoryId = req.params.id;

    if (!categoryId || categoryId.length !== 24) {
        return res.status(400).json({ message: 'ID danh mục không hợp lệ.' });
    }

    try {
        const deleted = await categoryService.deleteCategory(categoryId, user_id);

        if (!deleted) {
            return res.status(404).json({ message: 'Không tìm thấy danh mục để xóa hoặc danh mục này là mặc định.' });
        }

        res.status(200).json({ message: `Xóa danh mục thành công.` });
    } catch (error) {
        console.error('Lỗi xóa danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

module.exports = {
    getCategories,
    createCategory,
    updateCategory,
    deleteCategory
};
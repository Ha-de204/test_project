const categoryService = require('../../services/category.service');

const getCategories = async (req, res) => {
    const user_id = req.user_id;

    try {
        const categories = await categoryService.getCategoriesByUser(user_id);
        const mapped = await Promise.all(
            categories.map(async (cat) => {

                const used = await categoryService.isCategoryUsed(cat._id);

                return {
                    id: cat._id,
                    label: cat.name,
                    icon: cat.icon_code_point,
                    type: cat.type,
                    isDefault: cat.is_default,
                    canEdit: !cat.is_default,
                    canDelete: !cat.is_default && !used,
                    isSetting: cat.name === "Cài đặt"
                };
            })
        );

        res.json(mapped);
    } catch (error) {
        console.error('Lỗi lấy danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi lấy danh mục.' });
    }
};

const createCategory = async (req, res) => {
    const user_id = req.user_id;
    const { name, iconCodePoint, type } = req.body;

    if (!user_id) {
        return res.status(401).json({ message: 'Không được phép. Vui lòng đăng nhập lại.' });
    }

    if (!name || iconCodePoint === undefined || !type) {
        return res.status(400).json({ message: 'Thiếu dữ liệu.' });
    }

    try {
        const result = await categoryService.createCategory(user_id, name, iconCodePoint, type);
        if(!result.success){
            return res.status(400).json({
                message: result.message
            });
        }

        return res.status(201).json({
            message: "Tạo danh mục thành công."
        });
    } catch (error) {
        console.error('Lỗi tạo danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi tạo danh mục.' });
    }
};

// update danh muc
const updateCategory = async (req, res) => {
    const user_id = req.user_id;
    const categoryId = req.params.id;
    const { name, iconCodePoint, type } = req.body;

    if (!categoryId || categoryId.length !== 24 || !name || iconCodePoint === undefined || !type) {
        return res.status(400).json({ message: 'Dữ liệu cập nhật hoặc ID danh mục không hợp lệ.' });
    }

    try {
        const result = await categoryService.updateCategory(categoryId, user_id, name, iconCodePoint, type);

        if (!result.success) {
            return res.status(400).json({
                message: result.message
            });
        }

        return res.json({
            message: "Cập nhật thành công."
        });
    } catch (error) {
        console.error('Lỗi cập nhật danh mục:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// delete danh muc
const deleteCategory = async (req, res) => {
    const user_id = req.user_id;
    const categoryId = req.params.id;

    if (!categoryId || categoryId.length !== 24) {
        return res.status(400).json({ message: 'ID danh mục không hợp lệ.' });
    }

    try {
        const result = await categoryService.deleteCategory(
            categoryId,
            user_id
        );

        if (!result.success) {
            return res.status(400).json({
                message: result.message
            });
        }

        return res.status(200).json({
            message: "Xóa danh mục thành công."
        });
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
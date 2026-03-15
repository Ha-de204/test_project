const reminderService = require('../../services/reminder.service');

const createReminder = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const { title, message, due_date, frequency} = req.body;

    if (!title || !due_date || !frequency) {
        return res.status(400).json({ message: 'Thiếu dữ liệu bắt buộc (title, due_date, frequency).'});
    }

    try {
        const reminderId = await reminderService.createReminder(
            user_id,
            title,
            message,
            due_date,
            frequency
        );
        res.status(201).json({
            reminder_id: reminderId,
            message: 'Tạo lời nhắc thành công.'
        });

    } catch (error) {
        console.error('Lỗi tạo lời nhắc:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi tạo lời nhắc.' });
    }
};

// lay tat ca loi nhac
const getReminders = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";

    try {
        const reminders = await reminderService.getRemindersByUserId(user_id);
        res.status(200).json(reminders);
    } catch (error) {
        console.error('Lỗi lấy lời nhắc:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ khi lấy lời nhắc.' });
    }
};

// lay chi tiet 1 loi nhac
const getReminderById = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const reminderId = req.params.id;

    if (!reminderId || reminderId.length !== 24) {
        return res.status(400).json({ message: 'ID lời nhắc không hợp lệ.' });
    }

    try {
        const reminder = await reminderService.getReminderById(reminderId, user_id);

        if (!reminder) {
            return res.status(404).json({ message: 'Không tìm thấy lời nhắc hoặc bạn không có quyền truy cập.' });
        }

        res.status(200).json(reminder);
    } catch (error) {
        console.error('Lỗi lấy chi tiết lời nhắc:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

//update loi nhac
const updateReminder = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const reminderId = req.params.id;
    const { title, message, due_date, frequency, is_enabled } = req.body;

    if (!reminderId || reminderId.length !== 24 || !title || !due_date || !frequency || is_enabled === undefined) {
        return res.status(400).json({ message: 'Dữ liệu cập nhật hoặc ID lời nhắc không hợp lệ.', received: req.body});
    }

    try {
        const updated = await reminderService.updateReminder(
            reminderId,
            user_id,
            title,
            message,
            due_date,
            frequency,
            is_enabled
        );

        if (!updated) {
            return res.status(404).json({ message: 'Không tìm thấy lời nhắc để cập nhật hoặc không có thay đổi.' });
        }

        res.status(200).json({ message: 'Cập nhật lời nhắc thành công.' });
    } catch (error) {
        console.error('Lỗi cập nhật lời nhắc:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// delete loi nhac
const deleteReminder = async (req, res) => {
    const user_id = req.user_id;
    //const user_id = "658123456789012345678901";
    const reminderId = req.params.id;

    if (!reminderId || reminderId.length !== 24) {
        return res.status(400).json({ message: 'ID lời nhắc không hợp lệ.' });
    }

    try {
        const deleted = await reminderService.deleteReminder(reminderId, user_id);

        if (!deleted) {
            return res.status(404).json({ message: 'Không tìm thấy lời nhắc để xóa hoặc bạn không có quyền.' });
        }

        res.status(200).json({ message: 'Xóa lời nhắc thành công.' });
    } catch (error) {
        console.error('Lỗi xóa lời nhắc:', error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

module.exports = {
    createReminder,
    getReminders,
    getReminderById,
    updateReminder,
    deleteReminder
};
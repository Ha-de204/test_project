const userService = require('../../services/user.service');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');


const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_key';

const generateToken = (user_id) => {
    return jwt.sign({ id: user_id.toString() }, JWT_SECRET, { expiresIn: '1h' });
};

// đăng ký
const registerUser = async (req, res) => {
    const { userName, password } = req.body;
    if (!userName || !password) {
        return res.status(400).json({ message: 'Vui lòng cung cấp tên và mật khẩu.' });
    }
    try {
        const existingUser = await userService.findUserByUserName(userName);
        if (existingUser) {
            return res.status(409).json({ message: 'Tên người dùng đã tồn tại' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPass = await bcrypt.hash(password, salt);

        const user_id = await userService.createUser( userName, hashedPass);
        //const user_id = "658123456789012345678901";
        const token = generateToken(user_id);

        res.status(201).json({
            token,
            user_id: user_id,
            userName: userName,
            message: 'Đăng ký tài khoản thành công!'
        });

    } catch (error) {
        console.error("Lỗi Đăng ký tài khoản:", error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// đăng nhập
const loginUser = async (req, res) => {
    const { userName, password } = req.body;

    if (!userName || !password) {
        return res.status(400).json({ message: 'Vui lòng cung cấp tên và mật khẩu.' });
    }

    try {
        const user = await userService.findUserByUserName(userName);

        if (!user) {
            return res.status(404).json({ message: 'Tên hoặc mật khẩu không chính xác.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Tên hoặc mật khẩu không chính xác.' });
        }

        const token = generateToken(user._id);

        res.status(200).json({
            token,
            user_id: user._id,
            userName: user.userName,
            message: 'Đăng nhập thành công!'
        });

    } catch (error) {
        console.error("Lỗi Đăng nhập:", error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

const getProfile = async (req, res) => {
    const user_id = req.user.id || req.user_id;
    //const user_id = "658123456789012345678901";
    try {
        const user = await userService.getUserById(user_id);

        if (!user) {
            return res.status(404).json({ message: "Người dùng không tồn tại." });
        }

        res.status(200).json({
            user_id: user._id || user.user_id,
            userName: user.userName,
            created_at: user.created_at
        });
    } catch (error) {
        console.error('Lỗi lấy profile:', error);
        res.status(500).json({ message: "Lỗi máy chủ nội bộ." });
    }
};

module.exports = { registerUser, loginUser, getProfile };
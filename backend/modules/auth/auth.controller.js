const userService = require('../../services/user.service');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../../models/User')
const nodemailer = require('nodemailer');
const { Resend } = require('resend');
const axios = require('axios');

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_key';

const generateToken = (user_id) => {
    return jwt.sign({ id: user_id.toString() }, JWT_SECRET, { expiresIn: '1h' });
};

// đăng ký
const registerUser = async (req, res) => {
    const { userName, password, email } = req.body;
    if (!userName || !password || !email) {
        return res.status(400).json({ message: 'Vui lòng cung cấp tên, mật khẩu và email.' });
    }
    try {
        const existingUser = await userService.findUserByUserName(userName);
        if (existingUser) {
            return res.status(409).json({ message: 'Tên người dùng đã tồn tại' });
        }

        const existingEmail = await User.findOne({ email: email.toLowerCase() });
        if (existingEmail) {
            return res.status(409).json({ message: 'Email này đã được sử dụng bởi tài khoản khác.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPass = await bcrypt.hash(password, salt);

        const user_id = await userService.createUser( userName, hashedPass, email.toLowerCase());
        //const user_id = "658123456789012345678901";
        const token = generateToken(user_id);

        res.status(201).json({
            token,
            user_id: user_id,
            userName: userName,
            email: email.toLowerCase(),
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

// quên password
// quên password
const forgotPassword = async (req, res) => {
    const { email } = req.body;
    if (!email) {
        return res.status(400).json({ message: 'Vui lòng nhập email để nhận mã OTP.' });
    }
    try {
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(404).json({ message: 'Không tìm thấy người dùng sở hữu email này.' });
        }

        // Tạo mã OTP
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

        const salt = await bcrypt.genSalt(10);
        const hashedOtp = await bcrypt.hash(otpCode, salt);

        user.resetPasswordToken = hashedOtp;
        user.resetPasswordExpires = Date.now() + 10 * 60 * 1000;
        await user.save();

        // 🔥 Gửi Mail bằng HTTP POST API xuyên qua tường lửa Render (Cổng 443 không bị chặn)
        const response = await axios.post(
            'https://api.brevo.com/v3/smtp/email',
            {
                sender: {
                    name: "Hệ thống Quản lý Thu chi",
                    email: "ngha17012004@gmail.com"
                },
                to: [{ email: email.toLowerCase() }],
                subject: 'Mã OTP khôi phục mật khẩu tài khoản',
                htmlContent: `
                  <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #f0f0f0; max-width: 500px; border-radius: 10px;">
                     <h2 style="color: #E91E63; text-align: center;">Khôi Phục Mật Khẩu</h2>
                     <p>Chào bạn,</p>
                     <p>Bạn nhận được email này vì đã yêu cầu khôi phục mật khẩu cho tài khoản ứng dụng Quản lý thu chi.</p>
                     <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
                        <span style="font-size: 24px; font-weight: bold; color: #333; letter-spacing: 5px;">${otpCode}</span>
                     </div>
                     <p style="color: #777; font-size: 13px;">Mã OTP này có hiệu lực trong vòng <b>10 phút</b>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                     <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                     <p style="font-size: 11px; color: #aaa; text-align: center;">Đây là email tự động, vui lòng không phản hồi lại email này.</p>
                  </div>
               `
            },
            {
                headers: {
                    'accept': 'application/json',
                    'api-key': process.env.EMAIL_PASS,
                    'content-type': 'application/json'
                }
            }
        );

        console.log("Gửi OTP thành công qua Brevo API:", response.data);

        res.status(200).json({
            success: true,
            message: 'Mã OTP khôi phục mật khẩu đã được gửi đến email của bạn.'
        });
    } catch (error) {
        console.error("Lỗi Yêu cầu OTP qua API:", error.response ? error.response.data : error.message);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ không thể gửi mail.' });
    }
};

// Xác thực OTP + set lại password
const resetPassword = async (req, res) => {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
        return res.status(400).json({ message: 'Vui lòng nhập đầy đủ email, mã OTP và mật khẩu mới.' });
    }
    try {
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user || !user.resetPasswordToken || !user.resetPasswordExpires) {
            return res.status(400).json({ message: 'Yêu cầu đổi mật khẩu không hợp lệ hoặc không tồn tại.' });
        }

        if (Date.now() > user.resetPasswordExpires) {
            return res.status(400).json({ message: 'Mã OTP đã hết hạn hiệu lực (quá 10 phút).' });
        }

        const isOtpMatch = await bcrypt.compare(otp, user.resetPasswordToken);
        if (!isOtpMatch) {
            return res.status(400).json({ message: 'Mã OTP không chính xác. Vui lòng thử lại.' });
        }

        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(newPassword, salt);

        user.resetPasswordToken = null;
        user.resetPasswordExpires = null;
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.'
        });
    } catch (error) {
        console.error("Lỗi Đặt lại mật khẩu:", error);
        res.status(500).json({ message: 'Lỗi máy chủ nội bộ.' });
    }
};

// lấy profile
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

module.exports = {
    registerUser,
    loginUser,
    forgotPassword,
    resetPassword,
    getProfile
};
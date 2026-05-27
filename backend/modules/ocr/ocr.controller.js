const fs = require('fs');
const { sendToOCRServer } = require('../../services/ocrClient');

exports.scanReceipt = async (req, res) => {
    if (!req.file) {
        return res.status(400).json({
            message: "Vui lòng tải lên hình ảnh"
        });
    }

    const filePath = req.file.path;

    const timerLabel = `OCR_${Date.now()}`;


    try {
        console.time(timerLabel);

        const fileBuffer = fs.readFileSync(filePath);

        // 1. forward sang OCR server
        const ocrResult = await sendToOCRServer(
            fileBuffer,
            req.file.originalname
        );

        // 2. xóa file local backend
        fs.unlinkSync(filePath);

        // 3. trả về frontend
        return res.status(200).json({
            success: true,
            ...ocrResult
        });

    } catch (error) {
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }

        return res.status(500).json({
            success: false,
            message: "OCR processing failed",
            error: error.message
        });
    } finally {
        console.timeEnd(timerLabel);
    }
};
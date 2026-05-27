const axios = require('axios');
const FormData = require('form-data');

const OCR_SERVER_URL =  "http://127.0.0.1:8000/scan";
//const OCR_SERVER_URL = "https://ocr-server-hsoq.onrender.com/scan";
//const OCR_SERVER_URL = "https://ha07nguyen-smart-finance-ocr.hf.space/scan";

const sendToOCRServer = async (fileBuffer, filename) => {
  try {
    const form = new FormData();

    form.append("file", fileBuffer, {
      filename: filename || "image.jpg",
      contentType: "image/jpeg",
    });

    const response = await axios.post(OCR_SERVER_URL, form, {
      headers: {
        ...form.getHeaders(),
        "Connection": "keep-alive"
      },
      timeout: 200000,
    });

    console.log("=== DỮ LIỆU TỪ HUGGING FACE ===");
    console.log(JSON.stringify(response.data, null, 2))

    return response.data;
  } catch (error) {
    console.log("STATUS:", error.response?.status);
    console.log("DATA:", error.response?.data);
    console.error("OCR Server Error:", error.message);
    throw error;
  }
};

module.exports = { sendToOCRServer };
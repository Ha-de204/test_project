const tesseract = require('tesseract.js');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp')
const { getWorker } = require('../../tesseractWorker');

/**
 * Tiền xử lý ảnh
 */
const preprocessImage = async (inputPath) => {
    const outputPath = path.join(path.dirname(inputPath), 'processed_' + path.basename(inputPath));

    await sharp(inputPath)
        .grayscale()
        .normalize()
        .resize({ width: 1200 })
        .sharpen()
        .linear(1.2, -10)
        .toFile(outputPath);
    return outputPath;
}

/**
 * Hàm hỗ trợ trích xuất title
 */
const extractTitle = (text) => {
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2);

  // 1. Ưu tiên: Tìm từ khóa đặc trưng của cửa hàng trong toàn bộ văn bản
  const rawTextLower = text.toLowerCase();
  if (rawTextLower.includes('thanhdo') || rawTextLower.includes('thanh do')) return "Thành Đô Mart";
  if (rawTextLower.includes('winmart')) return "WinMart";
  if (rawTextLower.includes('circle k')) return "Circle K";

  // 2. Ưu tiên 2: Lấy dòng có chữ hoa dài nhất ở 5 dòng đầu tiên
  const topLines = lines.slice(0, 5);
  for (let line of topLines) {
    const cleanLine = line.replace(/[^a-zA-Z0-9À-ỹ\s]/g, '').trim();
    if (cleanLine.length > 5 && cleanLine === cleanLine.toUpperCase()) {
      return cleanLine;
    }
  }

  // 3. Cuối cùng mới lấy dòng đầu tiên hợp lệ
  return lines.length > 0 ? lines[0].replace(/[^a-zA-Z0-9À-ỹ\s]/g, '').trim() : "Hóa đơn mới";
};


/**
 * Hàm hỗ trợ trích xuất số tiền
 */
const extractAmount = (text) => {
  // Loại bỏ khoảng trắng nằm giữa các con số
  const cleanText = text.replace(/(?<=\d)\s+(?=\d)/g, '');
  const lines = cleanText.split('\n');

  const anchors = ['thanh toán', 'tổng cộng', 'tổng tiền', 'thành tiền', 'tiền hàng', 'tiền thanh toán', 'phải trả', 'thanh toan', 'tong cong', 'tong tien'];
  let potentialAmounts = [];

  for (let line of lines.reverse()) {
      const lowerLine = line.toLowerCase();

      // Kiểm tra xem dòng này có chứa từ khóa mục tiêu không
      const normalize = (s) =>
        s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

      const normLine = normalize(line);

      const hasAnchor = anchors.some(anchor =>
        normLine.includes(normalize(anchor))
      );

      if (hasAnchor) {
        const amountRegex = /\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?/g;
        const matches = line.match(amountRegex);

        if (matches) {
          matches.forEach(m => {
            const val = parseFloat(m.replace(/[.,]/g, ''));
            if (val >= 1000) potentialAmounts.push(val);
          });
        }
      }
    }

    // 3. Nếu tìm thấy các số đi kèm từ khóa, lấy số lớn nhất trong nhóm đó
    if (potentialAmounts.length > 0) {
      return Math.max(...potentialAmounts);
    }

    // 4. PHƯƠNG ÁN DỰ PHÒNG (Nếu không thấy từ khóa)
    // Lấy tất cả số tiền hợp lệ, nhưng thay vì lấy Max, hãy lấy số xuất hiện cuối cùng
    const allMatches = cleanText.match(/\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?/g) || [];
    const allNumbers = allMatches
      .map(m => parseFloat(m.replace(/[.,]/g, '')))
      .filter(n => n >= 1000 && n < 10000000);

    return allNumbers.length > 0 ? allNumbers[allNumbers.length - 1] : 0;
};

/**
 * Hàm hỗ trợ trích xuất ngày tháng
 */
const extractDate = (text) => {
  // Bắt các định dạng dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
  const dateRegex = /(\d{1,2})\s*[\/\.\-]\s*(\d{1,2})\s*[\/\.\-]\s*(\d{2,4})/;
  const match = text.match(dateRegex);
  if (match) {
      let day = match[1].padStart(2, '0');
      let month = match[2].padStart(2, '0');
      let year = match[3];

      // Chuẩn hóa năm 2 chữ số thành 4 chữ số
      if (year.length === 2) year = '20' + year;

      const result = `${year}-${month}-${day}`;
      console.log("Date trích xuất được:", result);
      return result;
    }

  return null;
};

/**
 * Hàm gợi ý danh mục dựa trên từ khóa trong text
 */
const suggestCategory = (text) => {
  const content = text.toLowerCase();
  const categories = {
    'Đồ ăn': ['coffee', 'highlands', 'phúc long', 'starbucks', 'nhà hàng', 'trà sữa', 'mì', 'cơm', 'ăn sáng', 'nước uống', 'gà', 'cá', 'thịt', 'tôm', 'chả', 'ốc', 'xúc xích', 'rau', 'món', 'củ', 'quả'],
    'Di chuyển': ['grab', 'be', 'xăng', 'gas', 'taxi', 'vận tải', 'phí gửi xe'],
    'Mua sắm': ['siêu thị', 'mart', 'mall', 'shopee', 'lazada', 'tiki', 'winmart', 'circle k', 'tạp hóa'],
    'Giải trí': ['cinema', 'rạp chiếu phim', 'cgv', 'lotte', 'vé xem phim', 'karaoke'],
    'Sức khỏe': ['nhà thuốc', 'pharmacity', 'long châu', 'bệnh viện', 'phòng khám', 'thuốc']
  };

  for (const [name, keys] of Object.entries(categories)) {
    if (keys.some(key => content.includes(key))) return name;
  }
  return 'Khác';
};

exports.scanReceipt = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'Vui lòng tải lên hình ảnh hóa đơn.' });
  }

  const originalPath = req.file.path;
  let processedPath = null;

  try {
    console.time("OCR_Duration");
    processedPath = await preprocessImage(originalPath);
    const worker = getWorker();

    // 1. Chạy Tesseract OCR
    const { data: { text } } = await worker.recognize(processedPath);

    console.log("--------- DỮ LIỆU THÔ TESSERACT ĐỌC ĐƯỢC ---------");
    console.log(text);
    console.log("--------------------------------------------------");

    // 2. Trích xuất thông tin bằng Regex
    const amount = extractAmount(text);
    const date = extractDate(text);
    const categoryName = suggestCategory(text);
    const title = extractTitle(text);

    // 3. Xóa file ảnh tạm sau khi xử lý để giải phóng bộ nhớ server
    if (fs.existsSync(originalPath)) fs.unlinkSync(originalPath);
    if (fs.existsSync(processedPath)) fs.unlinkSync(processedPath);

    console.timeEnd("OCR_Duration");

    // 4. Trả kết quả về Frontend
    res.status(200).json({
      amount: amount,
      type: 'expense',
      title: title,
      note: 'Dữ liệu quét tự động',
      date: date,
      category_name: categoryName,
    });

  } catch (error) {
    console.error('Lỗi xử lý OCR:', error);

    // Đảm bảo xóa file ngay cả khi gặp lỗi
    if (fs.existsSync(originalPath)) fs.unlinkSync(originalPath);
    if (processedPath && fs.existsSync(processedPath)) fs.unlinkSync(processedPath);

    res.status(500).json({
      message: 'Không thể xử lý hình ảnh.',
      error: error.message
    });
  }
};
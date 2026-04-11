const tesseract = require('tesseract.js');

exports.scanReceipt = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No file uploaded.' });
  }

  try {
    const { data: { text } } = await tesseract.recognize(
      req.file.buffer,
      'vie', 
      { logger: m => console.log(m) } 
    );

    // Logic to parse the extracted text and identify amount, title, date, etc.
    // This is a simplified example. We'll need to use regex and patterns.

    const lines = text.split('\n');

    let amount = null;
    let date = null;
    let title = lines.length > 0 ? lines[0] : 'N/A'; 
    let note = 'N/A';
    let category_name = 'Khác';

    const amountRegex = /(?:T\u1ed5ng c\u1ed9ng|Total|Thanh to\u00e1n)\s*[: ]?\s*([\d., ]+)/i;
    const dateRegex = /(\d{2}[\/\.-]\d{2}[\/\.-]\d{4})/;

    lines.forEach(line => {
      const amountMatch = line.match(amountRegex);
      if (amountMatch && !amount) {
        amount = parseFloat(amountMatch[1].replace(/[., ]/g, ''));
      }

      const dateMatch = line.match(dateRegex);
      if (dateMatch && !date) {
        date = dateMatch[1];
      }
    });
    

    res.status(200).json({
      amount: amount || 0,
      type: 'expense',
      title: title,
      note: text, 
      date: date || new Date().toISOString(),
      category_name: category_name,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error processing image.', error: error.message });
  }
};
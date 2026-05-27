from fastapi import FastAPI, UploadFile, File
import pytesseract
import cv2
import numpy as np
import re
import unicodedata
import gc
import platform
from datetime import datetime

if platform.system() == "Windows":
    pytesseract.pytesseract.tesseract_cmd = (
       r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    )

app = FastAPI()

@app.get("/ping")
def ping():
    return {"status": "ok"}

# PREPROCESS
def preprocess_image(file_bytes):
    np_arr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    # resize giống sharp
    img = cv2.resize(img, None, fx=1.2, fy=1.2)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.normalize(gray, None, 0, 255, cv2.NORM_MINMAX)

    gray = cv2.GaussianBlur(gray, (3, 3), 0)

    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)

    return thresh


# TITLE
def extract_title(text):
    lines = [
        l.strip()
        for l in text.split("\n")
        if len(l.strip()) > 2
    ]

    raw = text.lower()

    # BRAND KEYWORDS
    brands = {
        "winmart": "WinMart",
        "circle k": "Circle K",
        "thanhdo": "Thành Đô Mart",
        "thanh do": "Thành Đô Mart",
        "highlands": "Highlands Coffee",
        "phuc long": "Phúc Long",
        "phúc long": "Phúc Long",
        "starbucks": "Starbucks",
        "coopmart": "Co.opmart",
        "bach hoa xanh": "Bách Hóa Xanh",
        "bhx": "Bách Hóa Xanh",
        "gs25": "GS25",
    }

    for key, value in brands.items():
        if key in raw:
            return value

    blacklist = ["mst", "mã số thuế", "tax", "địa chỉ", "dia chi", "tel", "sdt", "điện thoại", "hotline", "cảm ơn", "thank", "receipt",
                 "hóa đơn", "hoa don", "website", "thu ngân", "số giao dịch"]

    scored = []

    for i, line in enumerate(lines[:10]):

        clean = re.sub(
            r'[^a-zA-Z0-9À-ỹ\s]',
            '',
            line
        ).strip()

        lower = clean.lower()

        if len(clean) < 3:
            continue

        # bỏ các dòng trong blacklist
        if any(b in lower for b in blacklist):
            continue

        score = 0

        # ưu tiên dòng đầu
        score += max(0, 10 - i)

        # tên thường ngắn
        if len(clean) <= 30:
            score += 5

        # ít số
        digit_ratio = sum(c.isdigit() for c in clean) / max(len(clean), 1)
        if digit_ratio < 0.2:
            score += 5

        # có chữ cái
        if any(c.isalpha() for c in clean):
            score += 5

        scored.append((score, clean))

    if scored:
        scored.sort(reverse=True)
        return scored[0][1]

    return "Hóa đơn"


# AMOUNT
def extract_amount(text):
    clean_text = text.replace('O', '0').replace('o', '0').replace('I', '1')
    clean_text = re.sub(r'(?<=\d)\s+(?=\d)', '', clean_text)
    lines = clean_text.split("\n")

    anchors = [
        'thanh toán', 'tổng cộng', 'tổng tiền', 'thành tiền',
        'tiền hàng', 'phải trả', 'thanh toan', 'tong cong', 'tong tien', 'tổng'
    ]

    def normalize(s):
        return re.sub(r'[\u0300-\u036f]', '', s.lower())

    potential = []

    for line in reversed(lines):
        norm_line = normalize(line)

        if any(normalize(a) in norm_line for a in anchors):
            matches = re.findall(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?', line)

            for m in matches:
                val = float(re.sub(r'[.,]', '', m))
                if val >= 1000:
                    potential.append(val)

    if potential:
        return max(potential)

    all_matches = re.findall(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?', clean_text)
    numbers = [
        float(re.sub(r'[.,]', '', m))
        for m in all_matches
        if 1000 <= float(re.sub(r'[.,]', '', m)) < 10000000
    ]

    return numbers[-1] if numbers else 0


# DATE
def extract_date(text):
    match = re.search(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})', text)

    if match:
        d, m, y = match.groups()
        d = d.zfill(2)
        m = m.zfill(2)

        if len(y) == 2:
            y = "20" + y

        return f"{y}-{m}-{d}"

    return None


# CATEGORY
#Normal text
def normalize_text(text):
    text = text.lower()

    # bỏ dấu tiếng Việt
    text = unicodedata.normalize('NFD', text)

    text = ''.join(
        c for c in text
        if unicodedata.category(c) != 'Mn'
    )

    return text

MERCHANT_CATEGORY = {

    # MUA SẮM
    "winmart": "Mua sắm",
    "win mart": "Mua sắm",
    "circle k": "Mua sắm",
    "bach hoa xanh": "Mua sắm",
    "coopmart": "Mua sắm",
    "go": "Mua sắm",
    "lotte mart": "Mua sắm",
    "emart": "Mua sắm",
    "mini mart": "Mua sắm",
    "tap hoa": "Mua sắm",

    # ĐỒ ĂN
    "highlands": "Đồ ăn",
    "phuc long": "Đồ ăn",
    "starbucks": "Đồ ăn",
    "the coffee house": "Đồ ăn",
    "gong cha": "Đồ ăn",
    "tocotoco": "Đồ ăn",
    "kfc": "Đồ ăn",
    "lotteria": "Đồ ăn",
    "pizza hut": "Đồ ăn",
    "jollibee": "Đồ ăn",

    # DI CHUYỂN
    "grab": "Di chuyển",
    "be": "Di chuyển",
    "xanh sm": "Di chuyển",
    "taxi": "Di chuyển",

    # GIẢI TRÍ
    "cgv": "Giải trí",
    "lotte cinema": "Giải trí",
    "galaxy cinema": "Giải trí",

    # SỨC KHỎE
    "pharmacity": "Sức khỏe",
    "long chau": "Sức khỏe",
    "nha thuoc": "Sức khỏe",
}

# Detect Merchant
def detect_merchant_category(text):
    content = normalize_text(text)

    for merchant, category in MERCHANT_CATEGORY.items():
        if merchant in content:
            return category

    return None

CATEGORIES = {
    'Đồ ăn': ['coffee', 'tra sua', 'quan an', 'nha hang', 'bun', 'pho', 'com', 'mi', 'pizza', 'do an', 'nuoc ngot', 'ga ran', 'do uong', 'an vat',
              'lau', 'nuong', 'banh mi', 'ca phe', 'mon', 'mart'],

    'Di chuyển': ['grab', 'be', 'taxi', 'xang', 'tram xang', 'phi gui xe', 've xe', 'bus', 'vinfast'],

    'Mua sắm': ['sieu thi', 'mart', 'mall', 'tap hoa', 'cua hang', 'shopee', 'lazada', 'tiki', 'mini mart'],

    'Giải trí': ['cinema', 'karaoke', 'game', 'netflix', 'spotify', 've xem phim'],

    'Sức khỏe': ['benh vien', 'phong kham', 'thuoc', 'y te', 'nha thuoc'],

    'Học tập': ['nha sach', 'fahasa', 'hoc phi', 'khoa hoc', 'sach', 'van phong pham'],

    'Hóa đơn': ['tien dien', 'tien nuoc', 'wifi', 'internet', 'viettel', 'mobifone', 'vinaphone', 'fpt']
}

def suggest_category(text):

    # 1. ưu tiên merchant detection
    merchant_category = detect_merchant_category(text)

    if merchant_category:
        return merchant_category

    # 2. fallback keyword scoring
    content = normalize_text(text)

    scores = {}

    for category, keywords in CATEGORIES.items():

        score = 0

        for keyword in keywords:
            if keyword in content:
                score += 1

        scores[category] = score

    best_category = max(scores, key=scores.get)

    if scores[best_category] > 0:
        return best_category

    return "Khác"

# API
@app.post("/scan")
def scan_receipt(file: UploadFile = File(...)):
    try:
        contents = file.file.read()

        if not contents or len(contents) == 0:
            return {"error": "File dữ liệu tải lên bị rỗng"}

        img = preprocess_image(contents)

        config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(img, lang='eng+vie', config=config)

        amount = extract_amount(text)
        date = extract_date(text)
        category = suggest_category(text)
        title = extract_title(text)

        del img
        del contents
        gc.collect()

        return {
            "amount": amount,
            "type": "expense",
            "title": title,
            "note": "OCR auto",
            "date": date,
            "category_name": category,
            "raw_text": text
        }
    except Exception as e:
        return {"error": str(e)}

const mongoose = require("mongoose");
require("dotenv").config();

const Category = require("./models/Category");

async function seed() {
    try {
        await mongoose.connect(process.env.MONGO_URI);

        await Category.deleteMany({ is_default: true });

        await Category.insertMany([
              { user_id: null, name: "Mua sắm",    icon_code_point: 62335, type: "expense", is_default: true },
              { user_id: null, name: "Đồ ăn",      icon_code_point: 61513, type: "expense", is_default: true },
              { user_id: null, name: "Quần áo",    icon_code_point: 61260, type: "expense", is_default: true },
              { user_id: null, name: "Nhà ở",      icon_code_point: 61703, type: "expense", is_default: true },
              { user_id: null, name: "Sức khỏe",   icon_code_point: 57948, type: "expense", is_default: true },
              { user_id: null, name: "Học tập",    icon_code_point: 61151, type: "expense", is_default: true },
              { user_id: null, name: "Du lịch",    icon_code_point: 61573, type: "expense", is_default: true },
              { user_id: null, name: "Giải trí",   icon_code_point: 62606, type: "expense", is_default: true },
              { user_id: null, name: "Sửa chữa",   icon_code_point: 61190, type: "expense", is_default: true },
              { user_id: null, name: "Sắc đẹp",    icon_code_point: 62395, type: "expense", is_default: true },
              { user_id: null, name: "Điện thoại", icon_code_point: 62086, type: "expense", is_default: true },

              { user_id: null, name: "Lương",       icon_code_point: 62054, type: "income", is_default: true },
              { user_id: null, name: "Làm thêm",    icon_code_point: 59124, type: "income", is_default: true },
              { user_id: null, name: "Tiền thưởng", icon_code_point: 57662, type: "income", is_default: true },

              //{ user_id: null, name: "Thêm danh mục", icon_code_point: 57424, type: "expense", is_default: true }

        ]);

        console.log("Seed thành công!");
    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
        process.exit();
    }
}

seed();
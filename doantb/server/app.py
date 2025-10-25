import os
from label_map import label_map
from flask import Flask, request, jsonify,send_from_directory
from werkzeug.utils import secure_filename
from models import *
from utils import *
from config import *
from werkzeug.security import generate_password_hash, check_password_hash
from PIL import Image
# Thư viện cho JWT
import jwt
import datetime
from datetime import timedelta


app = Flask(__name__)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
upload = FOLDER_UPLOAD
food_images_folder = FOOD_IMAGES_FOLDER
conn_str = SQL_SERVER_CONN_STR
app.config['JSON_AS_ASCII'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024

# ==========================================================
# CẤU HÌNH JWT
# THAY THẾ CHUỖI NÀY BẰNG MỘT CHUỖI BÍ MẬT CỰC KỲ PHỨC TẠP CỦA BẠN!
# ==========================================================
app.config['SECRET_KEY'] = "DAY_LA_MOT_CHUOI_BI_MAT_RAT_QUAN_TRONG_HAY_THAY_DOI_NO"

@app.route("/api/predict", methods=["POST"])
def predict():
    if "image" not in request.files:
        return jsonify({"status": "fail", "message": "No image"}), 400

    image = request.files["image"]
    image_name = secure_filename(image.filename)
    image_path = os.path.join(upload, image_name)

    image.save(image_path)
    try:
        image_tensor = preprocess_image(image_path).to(device)

        with torch.no_grad():
            probs_list = []
            for model in models:
                outputs = model(image_tensor)
                probs = torch.softmax(outputs, dim=1)
                probs_list.append(probs)

            avg_probs = torch.stack(probs_list).mean(dim=0)
            predicted = torch.argmax(avg_probs, dim=1)
            prediction_idx = predicted.item()
            confidence = avg_probs[0][prediction_idx].item()
            predicted_label = label_map[prediction_idx]

            key_name = predicted_label
            id = key_to_id(key_name)
            food_info = get_food_info_by_id(id)

            print(f"{predicted}:{confidence}:{predicted_label}")
            print(f"{food_info}")

            CONFIDENCE_THRESHOLD = 0.6
            if not food_info or confidence < CONFIDENCE_THRESHOLD:
                return jsonify({
                    "status": "fail",
                    "message": "Chưa dự đoán được món ăn, vui lòng thử lại"
                }), 200
        return jsonify(food_info)

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/api/dishes", methods=["GET"])
def get_all_dishes():
    dishes = get_all()
    return jsonify(dishes)

@app.route("/api/dish/<int:dish_id>", methods=["GET"])
def get_dish_detail(dish_id):
    dish_info = get_food_info_by_id(dish_id)
    return jsonify(dish_info), 200

@app.route("/food_images/<path:filename>")
def food_images(filename):
    return send_from_directory(FOOD_IMAGES_FOLDER, filename)

@app.route("/")
def home():
    return "Flask server running. Use /predict, /api/dishes, /api/dish/<int:dish_id> or /food_images/<file>"

from PIL import Image

@app.route("/resize_images", methods=["GET"])
def resize_images():
    """
    Resize toàn bộ ảnh trong thư mục food_images về 512x512
    Chỉ cần chạy 1 lần để đồng bộ kích thước ảnh.
    """
    resized_count = 0
    skipped_count = 0
    errors = []

    for filename in os.listdir(FOOD_IMAGES_FOLDER):
        file_path = os.path.join(FOOD_IMAGES_FOLDER, filename)
        if not os.path.isfile(file_path):
            continue

        try:
            with Image.open(file_path) as img:
                if img.size == (512, 512):
                    skipped_count += 1
                    continue

                img = img.convert("RGB")
                img = img.resize((512, 512), Image.Resampling.LANCZOS)
                img.save(file_path, quality=90)
                resized_count += 1
        except Exception as e:
            errors.append(f"{filename}: {e}")

    return jsonify({
        "status": "success",
        "message": f"Đã resize {resized_count} ảnh (bỏ qua {skipped_count}).",
        "errors": errors
    })

# ==========================================================
# API 3: Đăng ký tài khoản mới
# ==========================================================
@app.route("/api/register", methods=["POST"])
def register_user():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password') or not data.get('username'):
        return jsonify({"status": "fail", "message": "Thiếu thông tin username, email hoặc password"}), 400

    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Kiểm tra xem email hoặc username đã tồn tại chưa
        cursor.execute("SELECT * FROM users WHERE email = ? OR username = ?", (email, username))
        if cursor.fetchone():
            return jsonify({"status": "fail", "message": "Email hoặc Username đã tồn tại"}), 409

        # Băm mật khẩu để bảo mật
        password_hash = generate_password_hash(password)

        # Thêm người dùng mới vào database
        cursor.execute("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)", (username, email, password_hash))

        # Lấy ID của người dùng vừa tạo
        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        user_id_row = cursor.fetchone()
        if not user_id_row:
            raise Exception("Không thể lấy ID người dùng vừa tạo")
        new_user_id = user_id_row.id

        # Lấy ID của vai trò 'user' (Giả sử vai trò 'user' có trong bảng 'roles')
        cursor.execute("SELECT id FROM roles WHERE name = 'user'")
        role_id_row = cursor.fetchone()
        if not role_id_row:
            # Nếu không có vai trò 'user', hãy tạo nó (hoặc báo lỗi)
            # Tạm thời ở đây sẽ báo lỗi để bạn biết mà thêm vai trò 'user' vào DB
            raise Exception("Vai trò 'user' không tồn tại trong database. Vui lòng thêm vào bảng 'roles'.")
        default_role_id = role_id_row.id

        # Gán vai trò 'user' cho người dùng mới trong bảng user_roles
        cursor.execute("INSERT INTO user_roles (user_id, role_id) VALUES (?, ?)", (new_user_id, default_role_id))

        conn.commit()

        return jsonify({"status": "success", "message": "Đăng ký tài khoản thành công"}), 201

    except Exception as e:
        conn.rollback() # Hoàn tác lại nếu có lỗi
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        conn.close()


# ==========================================================
# API 4: Đăng nhập
# ==========================================================
@app.route("/api/login", methods=["POST"])
def login_user():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"status": "fail", "message": "Thiếu email hoặc password"}), 400

    email = data.get('email')
    password = data.get('password')

    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Tìm người dùng bằng email
        cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"status": "fail", "message": "Email hoặc mật khẩu không chính xác"}), 401

        # Kiểm tra mật khẩu đã được băm
        if not check_password_hash(user.password_hash, password):
            return jsonify({"status": "fail", "message": "Email hoặc mật khẩu không chính xác"}), 401

        # === LẤY THÔNG TIN ROLE ĐỂ ĐƯA VÀO JWT ===
        cursor.execute("""
            SELECT r.name 
            FROM roles r
            INNER JOIN user_roles ur ON r.id = ur.role_id
            WHERE ur.user_id = ?
        """, (user.id,))

        roles_records = cursor.fetchall()
        # Tạo một danh sách các vai trò (ví dụ: ['user'] hoặc ['admin', 'moderator'])
        roles = [row.name for row in roles_records]

        # === TẠO JWT PAYLOAD ===
        expiration_time = datetime.datetime.now(datetime.timezone.utc) + timedelta(days=7)

        payload = {
            'sub': user.id,  # 'sub' (subject) là claim tiêu chuẩn cho user ID
            'email': user.email,
            'roles': roles, # Danh sách các vai trò của người dùng
            'exp': expiration_time
        }

        # Tạo token
        token = jwt.encode(payload, app.config['SECRET_KEY'], algorithm="HS256")

        return jsonify({
            "status": "success",
            "message": "Đăng nhập thành công",
            "token": token  # Trả về token thay vì thông tin user
        }), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

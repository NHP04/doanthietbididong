import os
from label_map import label_map
from flask import Flask, request, jsonify,send_from_directory
from werkzeug.utils import secure_filename
from models import *
from utils import *
from config import *
from PIL import Image

app = Flask(__name__)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
upload = FOLDER_UPLOAD
food_images_folder = FOOD_IMAGES_FOLDER
conn_str = SQL_SERVER_CONN_STR
app.config['JSON_AS_ASCII'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024

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
        "message": f"✅ Đã resize {resized_count} ảnh (bỏ qua {skipped_count}).",
        "errors": errors
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

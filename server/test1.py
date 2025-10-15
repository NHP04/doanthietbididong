import requests

# URL endpoint của Flask server
url = "http://127.0.0.1:5000/predict"

# Đường dẫn đến file ảnh cần test
image_path = "food_images/banh_bao.jpg"  # thay bằng ảnh của bạn

# Mở file ảnh ở chế độ nhị phân
with open(image_path, "rb") as img_file:
    files = {"image": img_file}

    # Gửi POST request
    response = requests.post(url, files=files)

# In kết quả
if response.status_code == 200:
    data = response.json()
    print("Predicted label:", data.get("predicted_label"))
    print("Confidence:", data.get("confidence"))
    print("Food info:", data.get("food_info"))
else:
    print("Error:", response.status_code, response.text)

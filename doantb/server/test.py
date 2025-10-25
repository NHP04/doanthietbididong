# test_predict.py
import requests

# URL của API Flask, thay IP:PORT theo máy bạn
url = "http://127.0.0.1:5000/api/predict"

# Đường dẫn tới ảnh muốn test
image_path = "food_images/banh_mi.jpg"

# Mở file và gửi POST request
with open(image_path, "rb") as f:
    files = {"image": f}
    response = requests.post(url, files=files)

try:
    print("Status code:", response.status_code)
    print("Response JSON:", response.json())
except Exception as e:
    print("Error parsing response:", e)
    print(response.text)

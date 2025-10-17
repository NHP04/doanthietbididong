import pyodbc
from PIL import Image
from torchvision import transforms
from config import SQL_SERVER_CONN_STR

conn_str = SQL_SERVER_CONN_STR

def convert_image_mode(img):
    if img.mode == 'P' or img.mode == 'LA':
        img = img.convert('RGB')
    return img

test_transform = transforms.Compose([
    transforms.Lambda(convert_image_mode),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])

def preprocess_image(image_bytes):
    image = Image.open(image_bytes)
    image = test_transform(image)
    return image.unsqueeze(0)

def get_connection():
    return pyodbc.connect(conn_str)

def get_food_info_by_key(key):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, key_name, name, description FROM dishes WHERE key_name = ?", (key,))
    row = cursor.fetchone()

    if not row:
        conn.close()
        return None
    dish_id = row[0]
    cursor = conn.cursor()
    cursor.execute("SELECT ingredient FROM ingredients WHERE dish_id = ?", (dish_id,))
    ingredients = [r[0] for r in cursor.fetchall()]
    cursor.execute("SELECT instruction FROM instructions WHERE dish_id = ? ORDER BY id", (dish_id,))
    instructions = [r[0] for r in cursor.fetchall()]
    conn.close()

    return {
            "id": dish_id,
            "key": row[1],
            "name": row[2],
            "description": row[3],
            "image": f"/food_images/{row[1]}.jpg",
            "ingredients": ingredients,
            "instructions": instructions
    }

def get_all():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, key_name, name, description FROM dishes")
    dishes_data = cursor.fetchall()

    dishes = []
    for row in dishes_data:
        dish_id = row[0]
        cursor.execute("""
                SELECT t.tag_name 
                FROM tags t
                JOIN dish_tags dt ON t.id = dt.tag_id
                WHERE dt.dish_id = ?
            """, (dish_id,))
        tags = [r[0] for r in cursor.fetchall()]

        dishes.append({
            "id": row[0],
            "key": row[1],
            "name": row[2],
            "description": row[3],
            "image": f"/food_images/{row[1]}.jpg",
            "tags": tags
        })
    conn.close()
    return dishes
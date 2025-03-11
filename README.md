# WebApp - Health Check API

This is a **Flask-based WebApp** that includes a `/healthz` endpoint to monitor the health of the application by interacting with a database.

## 📌 Features
- Flask API with health check functionality (`/healthz`).
- Uses **SQLAlchemy** for database interaction.
- Implements **Flask Blueprints** for modular structure.
- Supports **CORS** for cross-origin requests.

---

## 🚀 Getting Started

### **1️⃣ Prerequisites**
Ensure you have the following installed:
- Python 3.8+ 
- `pip` (Python package manager)
- Virtual environment (optional but recommended)

---



### **2️⃣ Clone the Repository**
```bash
git clone <your-repository-url>
cd webapp
```

### **3️⃣ Create a Virtual Environment**
```bash
python -m venv venv
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
```

### **4️⃣ Install Dependencies**
```bash
pip install -r requirements.txt
```

### **5️⃣ Run the Flask App**
```bash
python run.py
```

By default, the app runs on http://127.0.0.1:8080.

🌍 API Endpoints
Method	Endpoint	Description
GET	/health_api/healthz	Checks the application's health by inserting a database record.
Health Check Response
✅ 200 OK → Application is healthy.
❌ 400 Bad Request → GET request contains a payload.
⚠️ 503 Service Unavailable → Database operation failed.

### **🧪 Running Tests
This project includes automated tests using pytest.

```bash
pytest -v app/tests/test_api.py
```

### ** Running Shell Script

```bash
ssh -i ~/.ssh/do root@[ip_address]
scp -i ~/.ssh/do Tharun_Maheswararao_002310838_02.zip root@[ip_address]:/tmp
scp -i setup.sh root@[ip_address]:/tmp
cd /tmp
sudo bash setup.sh [db_user] [db_password]
```

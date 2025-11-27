import sqlite3, hashlib

db = sqlite3.connect("panel/panel.db")
c = db.cursor()

username = "admin"
password = "admin123"

hashed = hashlib.sha256(password.encode()).hexdigest()

c.execute("DELETE FROM admins WHERE username=?", (username,))
c.execute("INSERT INTO admins (username, password_hash) VALUES (?, ?)", (username, hashed))

db.commit()
db.close()

print("Admin criado com SHA256!")

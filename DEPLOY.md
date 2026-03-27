# app-ads.txt Doğrulama Adımları

AdMob, app-ads.txt dosyasının **domain kökünde** olmasını ister.
Bunun için GitHub repo adı: **KULLANICIADI.github.io** (kendi kullanıcı adın)

---

## 1. GitHub'da Repo Oluştur

1. https://github.com/new
2. **Repository name:** `KULLANICIADI.github.io` (ör: kerimyorulmaz.github.io)
3. Public
4. "Add a README file" **işaretleme** – boş repo
5. Create repository

---

## 2. Terminal Komutları

`KULLANICIADI` yerine GitHub kullanıcı adını yaz:

```bash
cd /Users/macbook/Documents/garageloop7/appstore_site

git init
git add .
git commit -m "GarageLoop site + app-ads.txt"
git branch -M main
git remote add origin https://github.com/KULLANICIADI/KULLANICIADI.github.io.git
git push -u origin main
```

Örnek (kullanıcı kerimyorulmaz ise):
```bash
git remote add origin https://github.com/kerimyorulmaz/kerimyorulmaz.github.io.git
```

---

## 3. GitHub Pages

1. Repo → **Settings** → **Pages**
2. **Source:** Deploy from a branch
3. **Branch:** main, **/ (root)**
4. Save
5. 2-3 dakika bekle

**Test:** `https://KULLANICIADI.github.io/app-ads.txt` aç  
Görmen gereken: `google.com, pub-6306264558109126, DIRECT, f08c47fec0942fa0`

---

## 4. App Store Connect

1. https://appstoreconnect.apple.com → GarageLoop
2. **App Information**
3. **Support URL:** `https://KULLANICIADI.github.io/support.html`
4. **Marketing URL:** `https://KULLANICIADI.github.io/`
5. Kaydet

---

## 5. AdMob Doğrulama

1. https://admob.google.com
2. **Uygulamalar** → GarageLoop
3. **Uygulamayı doğrula** / **Verify app**
4. **Check for updates**
5. Birkaç saat içinde tamamlanır

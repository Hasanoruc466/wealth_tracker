# # Wealth Tracker: Altın, Kripto ve Döviz Portföy Yönetim Uygulaması

**Wealth Tracker**: Kullanıcıların sahip oldukları varlıkları (altın, döviz, kripto para vb.) takip etmelerine olanak tanıyan bir mobil uygulamadır. Uygulama, kullanıcıların varlıklarının toplam değerini kolayca hesaplamasına yardımcı olur.

---

## Özellikler ✨
- 🪙 **Varlık Ekleyin**: Altın, döviz veya kripto para gibi varlıklarınızı ekleyin.
- 📊 **Güncel Fiyatlar**: Anlık veri kullanarak varlıklarınızın güncel değerini hesaplar.
- 🗂️ **Listeleme**: Varlıklarınızı detaylı bir şekilde görüntüleyin.
- ✏️ **Güncelleme**: Mevcut varlık miktarınızı kolayca düzenleyin.
- ❌ **Silme**: Artık kullanmadığınız varlıkları listeden çıkarın.
- 🔄 **Otomatik Güncelleme**: Fiyatlar ve veriler güncel tutulur.

---

## Kullanılan Teknolojiler 🛠️
- **Flutter**: Mobil uygulama geliştirme.
- **Dart**: Kodlama dili.
- **REST API**: Anlık fiyat verilerini almak için.
- **Shared Preferences**: Verilerin yerel depolanması.

---

## Kurulum ve Kullanım 🚀

1. **Projeyi Klonlayın:**
   git clone https://github.com/kullaniciadi/wealth_tracker.git
   cd wealth_tracker
   
2. **Gerekli Paketleri Kurun:**
   flutter pub get
   
3. **Simülatörde veya Gerçek Cihazda Çalıştırın:**
   flutter run

## Kullanılan Public API'ler

- **[Kripto API](https://api4.bitlo.com/market/ticker/all)**: Kripto para fiyatlarını sağlamak için kullanıldı.
- **[Altın API](https://finans.truncgil.com/today.json)**: Güncel altın fiyatlarını almak için kullanıldı.
- **[Döviz API](https://hasanadiguzel.com.tr/api/kurgetir)**: Döviz kurlarını almak için kullanıldı.

      


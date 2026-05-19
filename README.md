# DGS Yolum – Dijital Sınav Hazırlık Rehberi

<p align="center">
  <img src="https://github.com/user-attachments/assets/b62a14fd-3a2f-413d-9db8-52563753e919" alt="DGS Yolum Uygulama Ekranları" width="100%">
</p>

**DGS Yolum**, Dikey Geçiş Sınavı (DGS) adaylarının hazırlık sürecini uçtan uca yönetmelerini sağlayan, veri odaklı ve kullanıcı deneyimi (UX) merkezli bir mobil platformdur. Önlisanstan lisansa geçiş sürecindeki adayların net takibi, hedef analizi ve resmi kaynaklara erişim ihtiyaçlarını tek bir modern arayüzde toplar.

---

## 🚀 Öne Çıkan Özellikler

* **Kişiselleştirilmiş Gelişim Takibi:** Kullanıcıların deneme sonuçlarını görselleştiren, zaman serisi grafikler (`fl_chart`) aracılığıyla performans trendlerini analiz eden dinamik modül.
* **Akıllı Üniversite ve Bölüm Rehberi:** Binlerce satırlık güncel ÖSYM taban puanı ve kontenjan verisi içerisinde; burs oranları, şehir ve üniversite türüne göre anlık sonuç veren optimize edilmiş filtreleme motoru.
* **İnteraktif Sınav Odaklanma Sistemi:** Özelleştirilebilir çalışma periyotları, sesli geri bildirimler ve gerçek sınav simülasyonu sunan gelişmiş sayaç (`Timer`) yapısı.
* **Resmi Veri Entegrasyonu:** ÖSYM kılavuzları, tercih tabloları ve çıkmış sorular gibi kritik dökümanlara uygulama içinden doğrudan erişim sağlayan merkezi arşiv.
* **Premium Karanlık Tema:** Uzun süreli çalışma seanslarında göz sağlığını koruyan ve modern bir estetik sunan akışkan "Dark Mode" arayüzü.

---

## 🛠 Teknik Stack & Mühendislik Yaklaşımları

Bu proje, bir mühendislik bakış açısıyla aşağıdaki teknolojiler ve yöntemler kullanılarak inşa edilmiştir:

* **Framework:** Flutter & Dart (Cross-platform)
* **UI/UX Mimarisi:** Standart bileşenlerin (`BottomNavigationBar` vb.) kısıtlamalarını aşmak için geliştirilen, dikey hizalama ve hayalet boşluk sorunlarını matematiksel olarak çözen **Custom Navigation Bar** yapısı.
* **Veri Yönetimi:** Karmaşık ve büyük ölçekli JSON veri yapılarının asenkron olarak işlenmesi; performans kaybı yaşatmayan arama ve filtreleme algoritmaları.
* **Kütüphaneler:**
    * `fl_chart`: Analitik veri görselleştirme.
    * `url_launcher`: Harici resmi kaynakların güvenli yönetimi.
    * `audioplayers`: Kullanıcı etkileşimli sesli bildirimler.

---

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel makinenizde test etmek için:

1.  **Repoyu klonlayın:**
    ```bash
    git clone [https://github.com/kullaniciadi/dgs-yolum.git](https://github.com/kullaniciadi/dgs-yolum.git)
    ```
2.  **Bağımlılıkları senkronize edin:**
    ```bash
    flutter pub get
    ```
3.  **Uygulamayı başlatın:**
    ```bash
    flutter run
    ```

---

## ✒️ Geliştirici Notu
**DGS Yolum**, sadece fonksiyonel bir araç değil, aynı zamanda Flutter ekosisteminde **Özel Widget Mimarisi**, **Durum Yönetimi (State Management)** ve **Veri Görselleştirme** üzerine odaklanılmış bir projedir. Özellikle kullanıcı arayüzündeki piksel hassasiyetli düzenlemeler, platformun profesyonel standartlara uygunluğunu hedeflemektedir.

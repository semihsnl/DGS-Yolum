import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Hesap Ayarları"),
            _buildSettingsButton(
              title: "Profil ve ÖBP Ayarları",
              subtitle: "Eğitim bilgilerini güncelle",
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF6C63FF),
              onTap: () {},
            ),
            
            const SizedBox(height: 25),

            _buildSectionTitle("Resmi Kaynaklar"),
            _buildSettingsButton(
              title: "Resmi Kaynaklar",
              subtitle: "ÖSYM kılavuzları ve soru kitapçıkları",
              icon: Icons.account_tree_outlined,
              color: const Color(0xFF00D26A),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OfficialSourcesPage()));
              },
            ),

            const SizedBox(height: 25),

            _buildSectionTitle("Destek ve Diğer"),
            _buildSettingsCard(
              children: [
                _buildListTile("Sıkça Sorulan Sorular", Icons.quiz_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQPage()));
                }),
                _buildDivider(),
                _buildListTile("Bize Ulaşın", Icons.mail_outline_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactPage()));
                }),
                _buildDivider(),
                _buildListTile("Kullanım Koşulları", Icons.gavel_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPage()));
                }),
                _buildDivider(),
                _buildListTile("Gizlilik Politikası", Icons.privacy_tip_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPage()));
                }),
              ],
            ),
            
            const SizedBox(height: 40),
            const Center(child: Text("DGS Hazırlık v1.0.4", style: TextStyle(color: Colors.white24, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingsButton({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white12),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 20),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.03), height: 1, indent: 55);
}

// --- RESMİ KAYNAKLAR ALT SAYFASI ---
class OfficialSourcesPage extends StatelessWidget {
  const OfficialSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Resmi Kaynaklar")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("DGS'nin resmi kaynakları", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Aşağıdaki linkler ÖSYM'nin resmi sitesine yönlendirir.", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 25),
          _buildSourceCard("DGS Çıkmış Sorular", "ÖSYM DGS arşivine göz atın", Icons.help_outline),
          _buildSourceCard("DGS Kılavuzu", "Güncel başvuru ve geçiş tablosu", Icons.menu_book),
          _buildSourceCard("2024 DGS Soru Kitapçığı", "Son yapılan sınavın PDF dosyası", Icons.description),
          _buildSourceCard("ÖSYM Ana Sayfa", "Resmi duyurular ve takvim", Icons.language),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Neden link?", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("DGS soruları ÖSYM telifi altındadır. Bu yüzden sizi doğrudan resmi sayfaya yönlendiriyoruz.", 
                     style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSourceCard(String title, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue, size: 20)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          const Icon(Icons.open_in_new, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

// --- SIKÇA SORULAN SORULAR (FAQ) ---
class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("S.S.S.")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFAQItem("Uygulama puanları nasıl hesaplıyor?", "Uygulamamız en güncel DGS katsayılarını kullanarak ÖSYM standartlarında hesaplama yapmaktadır."),
          _buildFAQItem("İnternet bağlantısı gerekli mi?", "Puan hesaplama ve süre takibi çevrimdışı çalışır; ancak taban puanlar ve resmi kaynaklar için internet gereklidir."),
          _buildFAQItem("Verilerim güvende mi?", "Hesapladığınız netler ve profil bilgileriniz sadece telefonunuzda saklanır, sunucularımıza gönderilmez."),
          _buildFAQItem("Uygulama ücretsiz mi?", "Uygulamamız tamamen ücretsizdir ve DGS hazırlık sürecinde öğrencilere destek olmayı hedefler."),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: const Color(0xFF1C1E26), borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          )
        ],
      ),
    );
  }
}

// --- BİZE ULAŞIN ---
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Bize Ulaşın")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Konu", "Mesajınızın konusu", 1),
            const SizedBox(height: 15),
            _buildTextField("Mesaj", "Lütfen geri bildiriminizi buraya yazın...", 5),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesajınız iletildi!")));
                  Navigator.pop(context);
                },
                child: const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, int lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          maxLines: lines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1C1E26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

// --- KULLANIM KOŞULLARI ---
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Kullanım Koşulları")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          "1. Kabul Edilme: Uygulamayı kullanarak bu koşulları kabul etmiş sayılırsınız.\n\n"
          "2. Hizmet Amacı: Bu uygulama DGS adaylarına yardımcı olmak amacıyla hazırlanmış bir rehber araçtır. Sonuçların resmi bir geçerliliği yoktur.\n\n"
          "3. Veri Doğruluğu: Taban puanlar ÖSYM verilerine dayanır ancak oluşabilecek hatalardan uygulama sorumlu tutulamaz.\n\n"
          "4. Kullanım Hakkı: Uygulama içeriği ticari amaçlarla kopyalanamaz veya dağıtılamaz.",
          style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6),
        ),
      ),
    );
  }
}

// --- GİZLİLİK POLİTİKASI ---
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Gizlilik Politikası")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          "1. Veri Toplama: Uygulamamız kişisel bilgilerinizi toplamaz. Girdiğiniz netler yerel depolamada tutulur.\n\n"
          "2. Üçüncü Taraflar: Verileriniz reklam veya analiz amacıyla üçüncü taraflarla paylaşılmaz.\n\n"
          "3. İzinler: Uygulama sadece gerekli olan internet erişimi iznini talep eder.\n\n"
          "4. Güncellemeler: Gizlilik politikamız zaman zaman güncellenebilir ve değişiklikler burada yayınlanır.",
          style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6),
        ),
      ),
    );
  }
}
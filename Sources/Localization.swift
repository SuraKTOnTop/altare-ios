import Foundation

/// Supported UI languages. `.system` follows the device language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, vi, es, fr, de, pt, ru, zh, ja, ko, id, th
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return ""
        case .en: return "English"
        case .vi: return "Tiếng Việt"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .pt: return "Português"
        case .ru: return "Русский"
        case .zh: return "中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .id: return "Bahasa Indonesia"
        case .th: return "ไทย"
        }
    }

    /// Resolves `.system` to a concrete supported language code.
    var resolved: String {
        if self != .system { return rawValue }
        let pref = (Locale.preferredLanguages.first ?? "en").lowercased()
        if pref.hasPrefix("zh") { return "zh" }
        let code = String(pref.prefix(2))
        return AppLanguage.allCases.map { $0.rawValue }.contains(code) ? code : "en"
    }
}

/// Tiny in-app localizer. Missing translations fall back to English so the UI
/// never shows a blank string.
enum Loc {
    static func t(_ key: String, _ lang: String) -> String {
        guard let entry = strings[key] else { return key }
        return entry[lang] ?? entry["en"] ?? key
    }

    static let strings: [String: [String: String]] = [
        "signIn": ["en":"Sign in","vi":"Đăng nhập","es":"Iniciar sesión","fr":"Se connecter","de":"Anmelden","pt":"Entrar","ru":"Войти","zh":"登录","ja":"サインイン","ko":"로그인","id":"Masuk","th":"เข้าสู่ระบบ"],
        "signingIn": ["en":"Signing in…","vi":"Đang đăng nhập…","es":"Iniciando sesión…","fr":"Connexion…","de":"Anmeldung…","pt":"Entrando…","ru":"Вход…","zh":"正在登录…","ja":"サインイン中…","ko":"로그인 중…","id":"Sedang masuk…","th":"กำลังเข้าสู่ระบบ…"],
        "signInSubtitle": ["en":"Sign in to continue","vi":"Đăng nhập để tiếp tục","es":"Inicia sesión para continuar","fr":"Connectez-vous pour continuer","de":"Zum Fortfahren anmelden","pt":"Entre para continuar","ru":"Войдите, чтобы продолжить","zh":"登录以继续","ja":"続行するにはサインイン","ko":"계속하려면 로그인","id":"Masuk untuk melanjutkan","th":"เข้าสู่ระบบเพื่อดำเนินการต่อ"],
        "emailOrUsername": ["en":"Email or username","vi":"Email hoặc tên đăng nhập","es":"Correo o usuario","fr":"E-mail ou nom d'utilisateur","de":"E-Mail oder Benutzername","pt":"E-mail ou usuário","ru":"E-mail или имя","zh":"邮箱或用户名","ja":"メールまたはユーザー名","ko":"이메일 또는 사용자 이름","id":"Email atau nama pengguna","th":"อีเมลหรือชื่อผู้ใช้"],
        "password": ["en":"Password","vi":"Mật khẩu","es":"Contraseña","fr":"Mot de passe","de":"Passwort","pt":"Senha","ru":"Пароль","zh":"密码","ja":"パスワード","ko":"비밀번호","id":"Kata sandi","th":"รหัสผ่าน"],
        "tabServers": ["en":"Servers","vi":"Máy chủ","es":"Servidores","fr":"Serveurs","de":"Server","pt":"Servidores","ru":"Серверы","zh":"服务器","ja":"サーバー","ko":"서버","id":"Server","th":"เซิร์ฟเวอร์"],
        "tabWallet": ["en":"Wallet","vi":"Ví","es":"Cartera","fr":"Portefeuille","de":"Wallet","pt":"Carteira","ru":"Кошелёк","zh":"钱包","ja":"ウォレット","ko":"지갑","id":"Dompet","th":"กระเป๋าเงิน"],
        "tabRewards": ["en":"Rewards","vi":"Phần thưởng","es":"Recompensas","fr":"Récompenses","de":"Belohnungen","pt":"Recompensas","ru":"Награды","zh":"奖励","ja":"報酬","ko":"보상","id":"Hadiah","th":"รางวัล"],
        "tabAccount": ["en":"Account","vi":"Tài khoản","es":"Cuenta","fr":"Compte","de":"Konto","pt":"Conta","ru":"Аккаунт","zh":"账户","ja":"アカウント","ko":"계정","id":"Akun","th":"บัญชี"],
        "noServers": ["en":"No servers yet","vi":"Chưa có máy chủ","es":"Aún no hay servidores","fr":"Aucun serveur pour l'instant","de":"Noch keine Server","pt":"Ainda não há servidores","ru":"Пока нет серверов","zh":"暂无服务器","ja":"サーバーがありません","ko":"아직 서버가 없습니다","id":"Belum ada server","th":"ยังไม่มีเซิร์ฟเวอร์"],
        "loading": ["en":"Loading…","vi":"Đang tải…","es":"Cargando…","fr":"Chargement…","de":"Laden…","pt":"Carregando…","ru":"Загрузка…","zh":"加载中…","ja":"読み込み中…","ko":"불러오는 중…","id":"Memuat…","th":"กำลังโหลด…"],
        "balance": ["en":"Balance","vi":"Số dư","es":"Saldo","fr":"Solde","de":"Guthaben","pt":"Saldo","ru":"Баланс","zh":"余额","ja":"残高","ko":"잔액","id":"Saldo","th":"ยอดคงเหลือ"],
        "credits": ["en":"credits","vi":"tín dụng","es":"créditos","fr":"crédits","de":"Credits","pt":"créditos","ru":"кредитов","zh":"积分","ja":"クレジット","ko":"크레딧","id":"kredit","th":"เครดิต"],
        "addCredits": ["en":"Add credits","vi":"Nạp tín dụng","es":"Añadir créditos","fr":"Ajouter des crédits","de":"Credits hinzufügen","pt":"Adicionar créditos","ru":"Пополнить","zh":"充值积分","ja":"クレジット追加","ko":"크레딧 충전","id":"Tambah kredit","th":"เติมเครดิต"],
        "transfer": ["en":"Transfer","vi":"Chuyển","es":"Transferir","fr":"Transférer","de":"Übertragen","pt":"Transferir","ru":"Перевод","zh":"转账","ja":"送金","ko":"전송","id":"Transfer","th":"โอน"],
        "buyResources": ["en":"Buy resources","vi":"Mua tài nguyên","es":"Comprar recursos","fr":"Acheter des ressources","de":"Ressourcen kaufen","pt":"Comprar recursos","ru":"Купить ресурсы","zh":"购买资源","ja":"リソースを購入","ko":"리소스 구매","id":"Beli sumber daya","th":"ซื้อทรัพยากร"],
        "memory": ["en":"Memory","vi":"Bộ nhớ","es":"Memoria","fr":"Mémoire","de":"Arbeitsspeicher","pt":"Memória","ru":"Память","zh":"内存","ja":"メモリ","ko":"메모리","id":"Memori","th":"หน่วยความจำ"],
        "disk": ["en":"Disk","vi":"Ổ đĩa","es":"Disco","fr":"Disque","de":"Speicher","pt":"Disco","ru":"Диск","zh":"磁盘","ja":"ディスク","ko":"디스크","id":"Disk","th":"ดิสก์"],
        "cpu": ["en":"CPU"],
        "serverSlots": ["en":"Server slots","vi":"Suất máy chủ","es":"Ranuras de servidor","fr":"Emplacements serveur","de":"Server-Slots","pt":"Vagas de servidor","ru":"Слоты серверов","zh":"服务器名额","ja":"サーバー枠","ko":"서버 슬롯","id":"Slot server","th":"ช่องเซิร์ฟเวอร์"],
        "estimatedCost": ["en":"Estimated cost","vi":"Chi phí ước tính","es":"Costo estimado","fr":"Coût estimé","de":"Geschätzte Kosten","pt":"Custo estimado","ru":"Оценочная стоимость","zh":"预估费用","ja":"概算費用","ko":"예상 비용","id":"Perkiraan biaya","th":"ค่าใช้จ่ายโดยประมาณ"],
        "purchase": ["en":"Purchase","vi":"Mua","es":"Comprar","fr":"Acheter","de":"Kaufen","pt":"Comprar","ru":"Купить","zh":"购买","ja":"購入","ko":"구매","id":"Beli","th":"ซื้อ"],
        "dailyReward": ["en":"Daily reward","vi":"Thưởng hằng ngày","es":"Recompensa diaria","fr":"Récompense quotidienne","de":"Tägliche Belohnung","pt":"Recompensa diária","ru":"Ежедневная награда","zh":"每日奖励","ja":"デイリー報酬","ko":"일일 보상","id":"Hadiah harian","th":"รางวัลรายวัน"],
        "reward": ["en":"Reward","vi":"Phần thưởng","es":"Recompensa","fr":"Récompense","de":"Belohnung","pt":"Recompensa","ru":"Награда","zh":"奖励","ja":"報酬","ko":"보상","id":"Hadiah","th":"รางวัล"],
        "streak": ["en":"Streak","vi":"Chuỗi","es":"Racha","fr":"Série","de":"Serie","pt":"Sequência","ru":"Серия","zh":"连续","ja":"連続","ko":"연속","id":"Beruntun","th":"สตรีค"],
        "nextStreak": ["en":"Next streak","vi":"Chuỗi kế","es":"Próxima racha","fr":"Série suivante","de":"Nächste Serie","pt":"Próxima sequência","ru":"След. серия","zh":"下一连续","ja":"次の連続","ko":"다음 연속","id":"Beruntun berikut","th":"สตรีคถัดไป"],
        "claim": ["en":"Claim","vi":"Nhận","es":"Reclamar","fr":"Réclamer","de":"Einlösen","pt":"Resgatar","ru":"Получить","zh":"领取","ja":"受け取る","ko":"받기","id":"Klaim","th":"รับ"],
        "afkRewards": ["en":"AFK rewards","vi":"Thưởng AFK","es":"Recompensas AFK","fr":"Récompenses AFK","de":"AFK-Belohnungen","pt":"Recompensas AFK","ru":"AFK-награды","zh":"挂机奖励","ja":"AFK報酬","ko":"AFK 보상","id":"Hadiah AFK","th":"รางวัล AFK"],
        "earning": ["en":"Earning","vi":"Đang kiếm","es":"Ganando","fr":"En cours","de":"Aktiv","pt":"Ganhando","ru":"Начисляется","zh":"赚取中","ja":"獲得中","ko":"적립 중","id":"Menghasilkan","th":"กำลังรับ"],
        "notEarning": ["en":"Not earning","vi":"Chưa kiếm","es":"Sin ganar","fr":"Inactif","de":"Inaktiv","pt":"Não ganhando","ru":"Не начисляется","zh":"未赚取","ja":"獲得なし","ko":"적립 안 함","id":"Tidak menghasilkan","th":"ยังไม่รับ"],
        "afkNow": ["en":"AFK now","vi":"AFK hiện tại","es":"AFK ahora","fr":"AFK maintenant","de":"AFK jetzt","pt":"AFK agora","ru":"AFK сейчас","zh":"当前挂机","ja":"現在のAFK","ko":"현재 AFK","id":"AFK sekarang","th":"AFK ตอนนี้"],
        "perMinute": ["en":"Per minute","vi":"Mỗi phút","es":"Por minuto","fr":"Par minute","de":"Pro Minute","pt":"Por minuto","ru":"В минуту","zh":"每分钟","ja":"毎分","ko":"분당","id":"Per menit","th":"ต่อนาที"],
        "partyX": ["en":"Party x","vi":"Nhóm x","es":"Grupo x","fr":"Groupe x","de":"Party x","pt":"Grupo x","ru":"Группа x","zh":"组队 x","ja":"パーティ x","ko":"파티 x","id":"Party x","th":"ปาร์ตี้ x"],
        "startEarning": ["en":"Start earning","vi":"Bắt đầu kiếm","es":"Empezar a ganar","fr":"Commencer","de":"Starten","pt":"Começar a ganhar","ru":"Начать","zh":"开始赚取","ja":"獲得開始","ko":"적립 시작","id":"Mulai menghasilkan","th":"เริ่มรับ"],
        "stopEarning": ["en":"Stop earning","vi":"Dừng kiếm","es":"Dejar de ganar","fr":"Arrêter","de":"Stoppen","pt":"Parar de ganhar","ru":"Остановить","zh":"停止赚取","ja":"獲得停止","ko":"적립 중지","id":"Berhenti menghasilkan","th":"หยุดรับ"],
        "referrals": ["en":"Referrals","vi":"Giới thiệu","es":"Referidos","fr":"Parrainage","de":"Empfehlungen","pt":"Indicações","ru":"Рефералы","zh":"推荐","ja":"紹介","ko":"추천","id":"Referal","th":"การแนะนำ"],
        "yourCode": ["en":"Your code","vi":"Mã của bạn","es":"Tu código","fr":"Votre code","de":"Dein Code","pt":"Seu código","ru":"Ваш код","zh":"你的邀请码","ja":"あなたのコード","ko":"내 코드","id":"Kode kamu","th":"รหัสของคุณ"],
        "resources": ["en":"Resources","vi":"Tài nguyên","es":"Recursos","fr":"Ressources","de":"Ressourcen","pt":"Recursos","ru":"Ресурсы","zh":"资源","ja":"リソース","ko":"리소스","id":"Sumber daya","th":"ทรัพยากร"],
        "accountDetails": ["en":"Account details","vi":"Thông tin tài khoản","es":"Detalles de la cuenta","fr":"Détails du compte","de":"Kontodetails","pt":"Detalhes da conta","ru":"Данные аккаунта","zh":"账户信息","ja":"アカウント情報","ko":"계정 정보","id":"Detail akun","th":"รายละเอียดบัญชี"],
        "email": ["en":"Email","vi":"Email","es":"Correo","fr":"E-mail","de":"E-Mail","pt":"E-mail","ru":"E-mail","zh":"邮箱","ja":"メール","ko":"이메일","id":"Email","th":"อีเมล"],
        "username": ["en":"Username","vi":"Tên đăng nhập","es":"Usuario","fr":"Nom d'utilisateur","de":"Benutzername","pt":"Usuário","ru":"Имя пользователя","zh":"用户名","ja":"ユーザー名","ko":"사용자 이름","id":"Nama pengguna","th":"ชื่อผู้ใช้"],
        "save": ["en":"Save","vi":"Lưu","es":"Guardar","fr":"Enregistrer","de":"Speichern","pt":"Salvar","ru":"Сохранить","zh":"保存","ja":"保存","ko":"저장","id":"Simpan","th":"บันทึก"],
        "logOut": ["en":"Log out","vi":"Đăng xuất","es":"Cerrar sesión","fr":"Se déconnecter","de":"Abmelden","pt":"Sair","ru":"Выйти","zh":"退出登录","ja":"ログアウト","ko":"로그아웃","id":"Keluar","th":"ออกจากระบบ"],
        "appearance": ["en":"Appearance","vi":"Giao diện","es":"Apariencia","fr":"Apparence","de":"Darstellung","pt":"Aparência","ru":"Оформление","zh":"外观","ja":"外観","ko":"화면 모드","id":"Tampilan","th":"ธีม"],
        "language": ["en":"Language","vi":"Ngôn ngữ","es":"Idioma","fr":"Langue","de":"Sprache","pt":"Idioma","ru":"Язык","zh":"语言","ja":"言語","ko":"언어","id":"Bahasa","th":"ภาษา"],
        "themeSystem": ["en":"Automatic","vi":"Tự động","es":"Automático","fr":"Automatique","de":"Automatisch","pt":"Automático","ru":"Авто","zh":"自动","ja":"自動","ko":"자동","id":"Otomatis","th":"อัตโนมัติ"],
        "themeLight": ["en":"Light","vi":"Sáng","es":"Claro","fr":"Clair","de":"Hell","pt":"Claro","ru":"Светлая","zh":"浅色","ja":"ライト","ko":"라이트","id":"Terang","th":"สว่าง"],
        "themeDark": ["en":"Dark","vi":"Tối","es":"Oscuro","fr":"Sombre","de":"Dunkel","pt":"Escuro","ru":"Тёмная","zh":"深色","ja":"ダーク","ko":"다크","id":"Gelap","th":"มืด"],
        "languageSystem": ["en":"System default","vi":"Theo hệ thống","es":"Predeterminado del sistema","fr":"Système","de":"Systemstandard","pt":"Padrão do sistema","ru":"Системный","zh":"跟随系统","ja":"システムに従う","ko":"시스템 기본값","id":"Bawaan sistem","th":"ตามระบบ"],
        "console": ["en":"Console","vi":"Bảng điều khiển","es":"Consola","fr":"Console","de":"Konsole","pt":"Console","ru":"Консоль","zh":"控制台","ja":"コンソール","ko":"콘솔","id":"Konsol","th":"คอนโซล"],
        "files": ["en":"Files","vi":"Tập tin","es":"Archivos","fr":"Fichiers","de":"Dateien","pt":"Arquivos","ru":"Файлы","zh":"文件","ja":"ファイル","ko":"파일","id":"Berkas","th":"ไฟล์"],
        "backups": ["en":"Backups","vi":"Sao lưu","es":"Copias","fr":"Sauvegardes","de":"Backups","pt":"Backups","ru":"Резервные копии","zh":"备份","ja":"バックアップ","ko":"백업","id":"Cadangan","th":"สำรองข้อมูล"],
        "startup": ["en":"Startup","vi":"Khởi động","es":"Inicio","fr":"Démarrage","de":"Start","pt":"Inicialização","ru":"Запуск","zh":"启动","ja":"起動","ko":"시작","id":"Startup","th":"การเริ่มต้น"],
        "start": ["en":"Start","vi":"Bật","es":"Iniciar","fr":"Démarrer","de":"Start","pt":"Iniciar","ru":"Запуск","zh":"启动","ja":"起動","ko":"시작","id":"Mulai","th":"เริ่ม"],
        "restart": ["en":"Restart","vi":"Khởi động lại","es":"Reiniciar","fr":"Redémarrer","de":"Neustart","pt":"Reiniciar","ru":"Перезапуск","zh":"重启","ja":"再起動","ko":"재시작","id":"Mulai ulang","th":"รีสตาร์ท"],
        "stop": ["en":"Stop","vi":"Dừng","es":"Detener","fr":"Arrêter","de":"Stopp","pt":"Parar","ru":"Стоп","zh":"停止","ja":"停止","ko":"정지","id":"Hentikan","th":"หยุด"],
        "kill": ["en":"Kill","vi":"Tắt ngay","es":"Forzar","fr":"Forcer","de":"Beenden","pt":"Forçar","ru":"Убить","zh":"强制结束","ja":"強制終了","ko":"강제 종료","id":"Paksa mati","th":"บังคับปิด"],
        "live": ["en":"Live","vi":"Trực tiếp","es":"En vivo","fr":"En direct","de":"Live","pt":"Ao vivo","ru":"В эфире","zh":"实时","ja":"ライブ","ko":"실시간","id":"Langsung","th":"สด"],
        "clear": ["en":"Clear","vi":"Xóa","es":"Limpiar","fr":"Effacer","de":"Leeren","pt":"Limpar","ru":"Очистить","zh":"清除","ja":"クリア","ko":"지우기","id":"Bersihkan","th":"ล้าง"],
        "enterCommand": ["en":"Enter a command","vi":"Nhập lệnh","es":"Escribe un comando","fr":"Entrez une commande","de":"Befehl eingeben","pt":"Digite um comando","ru":"Введите команду","zh":"输入命令","ja":"コマンドを入力","ko":"명령어 입력","id":"Masukkan perintah","th":"พิมพ์คำสั่ง"],
        "uptime": ["en":"Uptime","vi":"Thời gian chạy","es":"Tiempo activo","fr":"Disponibilité","de":"Laufzeit","pt":"Tempo ativo","ru":"Аптайм","zh":"运行时间","ja":"稼働時間","ko":"가동 시간","id":"Waktu aktif","th":"เวลาทำงาน"],
        "server": ["en":"Server","vi":"Máy chủ","es":"Servidor","fr":"Serveur","de":"Server","pt":"Servidor","ru":"Сервер","zh":"服务器","ja":"サーバー","ko":"서버","id":"Server","th":"เซิร์ฟเวอร์"],
        "webManagedFmt": ["en":"%@ are managed on the web dashboard.","vi":"%@ được quản lý trên bảng điều khiển web.","es":"%@ se gestionan en el panel web.","fr":"%@ sont gérés sur le tableau de bord web.","de":"%@ werden im Web-Dashboard verwaltet.","pt":"%@ são gerenciados no painel web.","ru":"%@ управляются в веб-панели.","zh":"%@ 在网页面板中管理。","ja":"%@ はウェブダッシュボードで管理します。","ko":"%@은(는) 웹 대시보드에서 관리됩니다.","id":"%@ dikelola di dasbor web.","th":"%@ จัดการผ่านแดชบอร์ดเว็บ"],
        "settings": ["en":"Settings","vi":"Cài đặt","es":"Ajustes","fr":"Réglages","de":"Einstellungen","pt":"Configurações","ru":"Настройки","zh":"设置","ja":"設定","ko":"설정","id":"Pengaturan","th":"การตั้งค่า"],
    ]
}

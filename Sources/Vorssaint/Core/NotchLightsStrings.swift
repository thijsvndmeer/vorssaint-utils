// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct NotchLightsStrings {
    let title: String
    let enable: String
    let description: String
    let style: String
    let armWidth: String
    let thickness: String
    let entry: String
    let motion: String
    let transition: String
    let edgeWave: String
    let edgeWaveHint: String
    let lightSurface: String
    let lightSurfaceHint: String
    let agentActivity: String
    let musicActivity: String
    let copySweep: String
    let notices: String
    let preview: String
    let previewHalo: String
    let previewWave: String

    let styleClassic: String
    let stylePixelated: String
    let styleVolumetric: String
    let styleRays: String
    let styleBio: String
    let stylePrism: String
    let styleNimbus: String

    let widthNarrow: String
    let widthMedium: String
    let widthWide: String
    let widthExtraWide: String

    let entrySweep: String
    let entryTrace: String
    let entryBlast: String

    let motionNone: String
    let motionOndulation: String
    let motionFlux: String
    let motionRipple: String
    let motionShimmer: String

    let transHybrid: String
    let transWhiteFlash: String
    let transHueSlide: String
    let transShockwave: String
    let transPulse: String
    let transSupernova: String
    let transRings: String
    let transPrism: String
    let transStrobe: String
    let transBigBang: String
    let transOff: String

    let surfaceNeon: String
    let surfaceVelours: String

    func styleName(_ value: NotchHaloStyle) -> String {
        switch value {
        case .classic: return styleClassic
        case .pixelated: return stylePixelated
        case .volumetric: return styleVolumetric
        case .rays: return styleRays
        case .bioluminescent: return styleBio
        case .prism: return stylePrism
        case .nimbus: return styleNimbus
        }
    }

    func armWidthName(_ value: NotchHaloArmWidth) -> String {
        switch value {
        case .narrow: return widthNarrow
        case .medium: return widthMedium
        case .wide: return widthWide
        case .extraWide: return widthExtraWide
        }
    }

    func entryName(_ value: NotchHaloEntryMode) -> String {
        switch value {
        case .sweep: return entrySweep
        case .trace: return entryTrace
        case .blast: return entryBlast
        }
    }

    func motionName(_ value: NotchHaloMotion) -> String {
        switch value {
        case .none: return motionNone
        case .ondulation: return motionOndulation
        case .flux: return motionFlux
        case .ripple: return motionRipple
        case .shimmer: return motionShimmer
        }
    }

    func transitionName(_ value: NotchHaloTransitionEffect) -> String {
        switch value {
        case .hybrid: return transHybrid
        case .whiteFlash: return transWhiteFlash
        case .hueSlide: return transHueSlide
        case .shockwave: return transShockwave
        case .pulse: return transPulse
        case .supernova: return transSupernova
        case .rings: return transRings
        case .prism: return transPrism
        case .strobe: return transStrobe
        case .bigBang: return transBigBang
        case .off: return transOff
        }
    }

    func surfaceName(_ value: NotchLightSurfaceStyle) -> String {
        switch value {
        case .neon: return surfaceNeon
        case .velours: return surfaceVelours
        }
    }

    static func localized(_ language: AppLanguage) -> NotchLightsStrings {
        switch language {
        case .enUS:
            return NotchLightsStrings(
                title: "Island lights",
                enable: "Glow and laser halos",
                description: "Illuminate the notch edges during AI tasks, music playback, copies, and alerts.",
                style: "Laser style",
                armWidth: "Reach",
                thickness: "Intensity",
                entry: "Entrance",
                motion: "Ongoing motion",
                transition: "State transition",
                edgeWave: "Screen edge wave",
                edgeWaveHint: "Sweep a crisp shockwave along display edges when an AI turn ends or alerts fire.",
                lightSurface: "Light menu bar finish",
                lightSurfaceHint: "Tune glow saturation and shadows when the menu bar has a light background.",
                agentActivity: "AI agent turns and alerts",
                musicActivity: "Music playback aura",
                copySweep: "Clipboard copy laser sweep",
                notices: "Island HUD notices",
                preview: "Test effects",
                previewHalo: "Halo",
                previewWave: "Edge wave",
                styleClassic: "Classic",
                stylePixelated: "Pixelated Bayer",
                styleVolumetric: "Volumetric",
                styleRays: "Rays",
                styleBio: "Bioluminescent",
                stylePrism: "Prism",
                styleNimbus: "Nimbus",
                widthNarrow: "Narrow",
                widthMedium: "Medium",
                widthWide: "Wide",
                widthExtraWide: "Extra wide",
                entrySweep: "Sweep",
                entryTrace: "Trace",
                entryBlast: "Blast",
                motionNone: "Steady",
                motionOndulation: "Ondulation",
                motionFlux: "Flux",
                motionRipple: "Ripple",
                motionShimmer: "Shimmer",
                transHybrid: "Hybrid",
                transWhiteFlash: "White flash",
                transHueSlide: "Hue slide",
                transShockwave: "Shockwave",
                transPulse: "Pulse",
                transSupernova: "Supernova",
                transRings: "Rings",
                transPrism: "Prism",
                transStrobe: "Strobe",
                transBigBang: "Big Bang",
                transOff: "Off",
                surfaceNeon: "Neon",
                surfaceVelours: "Velours"
            )
        case .ptBR:
            return NotchLightsStrings(
                title: "Luzes da ilha",
                enable: "Halos e lasers de brilho",
                description: "Ilumina as bordas do notch em tarefas de IA, musica, copias e alertas.",
                style: "Estilo do laser",
                armWidth: "Alcance",
                thickness: "Intensidade",
                entry: "Entrada",
                motion: "Movimento continuo",
                transition: "Transicao de estado",
                edgeWave: "Onda nas bordas da tela",
                edgeWaveHint: "Percorre as bordas da tela quando uma tarefa de IA termina ou surge um alerta.",
                lightSurface: "Acabamento em barra clara",
                lightSurfaceHint: "Ajusta saturacao e sombras quando a barra de menus esta clara.",
                agentActivity: "Tarefas e alertas de IA",
                musicActivity: "Aura da reproducao de musica",
                copySweep: "Varredura laser ao copiar",
                notices: "Avisos da ilha",
                preview: "Testar efeitos",
                previewHalo: "Halo",
                previewWave: "Onda",
                styleClassic: "Classico",
                stylePixelated: "Pixelado Bayer",
                styleVolumetric: "Volumetrico",
                styleRays: "Raios",
                styleBio: "Bioluminescente",
                stylePrism: "Prisma",
                styleNimbus: "Nimbus",
                widthNarrow: "Estreito",
                widthMedium: "Medio",
                widthWide: "Largo",
                widthExtraWide: "Extra largo",
                entrySweep: "Varredura",
                entryTrace: "Traco",
                entryBlast: "Explosao",
                motionNone: "Fixo",
                motionOndulation: "Ondulacao",
                motionFlux: "Fluxo",
                motionRipple: "Marola",
                motionShimmer: "Cintilacao",
                transHybrid: "Hibrida",
                transWhiteFlash: "Clarão branco",
                transHueSlide: "Deslize de matiz",
                transShockwave: "Onda de choque",
                transPulse: "Pulso",
                transSupernova: "Supernova",
                transRings: "Aneis",
                transPrism: "Prisma",
                transStrobe: "Estrobo",
                transBigBang: "Big Bang",
                transOff: "Desativada",
                surfaceNeon: "Neon",
                surfaceVelours: "Veludo"
            )
        case .tr:
            return NotchLightsStrings(
                title: "Ada isiklari",
                enable: "Lazer ve hale isiltisi",
                description: "Yapay zeka gorevleri, muzik, kopyalama ve uyarilarda centik kenarlarini aydinlatir.",
                style: "Lazer stili",
                armWidth: "Genislik",
                thickness: "Yogunluk",
                entry: "Giris animasyonu",
                motion: "Surekli hareket",
                transition: "Durum gecisi",
                edgeWave: "Ekran kenar dalgasi",
                edgeWaveHint: "Bir yapay zeka turu bittiginde veya uyari geldiginde ekran kenarlarinda dalga gecer.",
                lightSurface: "Acik menu cubugu gorunumu",
                lightSurfaceHint: "Menu cubugu acik renk oldugunda doygunluk ve golgeyi ayarlar.",
                agentActivity: "Yapay zeka turlari ve uyarilari",
                musicActivity: "Muzik calarken hale",
                copySweep: "Pano kopyalama lazer gecisi",
                notices: "Ada bildirimleri",
                preview: "Efektleri dene",
                previewHalo: "Hale",
                previewWave: "Kenar dalgasi",
                styleClassic: "Klasik",
                stylePixelated: "Pikselli Bayer",
                styleVolumetric: "Hacimsel",
                styleRays: "Isinlar",
                styleBio: "Biyoluminesan",
                stylePrism: "Prizma",
                styleNimbus: "Bulut",
                widthNarrow: "Dar",
                widthMedium: "Orta",
                widthWide: "Genis",
                widthExtraWide: "Cok genis",
                entrySweep: "Supurme",
                entryTrace: "Iz",
                entryBlast: "Patlama",
                motionNone: "Sabit",
                motionOndulation: "Dalgalanma",
                motionFlux: "Akis",
                motionRipple: "Dalga",
                motionShimmer: "Parilti",
                transHybrid: "Hibrit",
                transWhiteFlash: "Beyaz flas",
                transHueSlide: "Ton kaymasi",
                transShockwave: "Sok dalgasi",
                transPulse: "Nabiz",
                transSupernova: "Supernova",
                transRings: "Halkalar",
                transPrism: "Prizma",
                transStrobe: "Flasor",
                transBigBang: "Buyuk Patlama",
                transOff: "Kapali",
                surfaceNeon: "Neon",
                surfaceVelours: "Kadife"
            )
        case .ru:
            return NotchLightsStrings(
                title: "Подсветка острова",
                enable: "Лазерное свечение и ореол",
                description: "Подсвечивает края выреза во время задач ИИ, воспроизведения музыки, копирования и уведомлений.",
                style: "Стиль лазера",
                armWidth: "Охват",
                thickness: "Интенсивность",
                entry: "Появление",
                motion: "Движение",
                transition: "Переход состояния",
                edgeWave: "Волна по краям экрана",
                edgeWaveHint: "Запускает световую волну по периметру экрана при завершении задачи ИИ или тревоге.",
                lightSurface: "Светлая строка меню",
                lightSurfaceHint: "Адаптирует насыщенность и тени для светлого фона строки меню.",
                agentActivity: "Активность и сигналы ИИ",
                musicActivity: "Свечение при музыке",
                copySweep: "Лазерный импульс при копировании",
                notices: "Индикаторы острова",
                preview: "Проверка эффектов",
                previewHalo: "Ореол",
                previewWave: "Волна",
                styleClassic: "Классика",
                stylePixelated: "Пиксельный Байер",
                styleVolumetric: "Объёмное свечение",
                styleRays: "Лучи",
                styleBio: "Биолюминесценция",
                stylePrism: "Призма",
                styleNimbus: "Нимб",
                widthNarrow: "Узкий",
                widthMedium: "Средний",
                widthWide: "Широкий",
                widthExtraWide: "Сверхширокий",
                entrySweep: "Взмах",
                entryTrace: "Контур",
                entryBlast: "Вспышка",
                motionNone: "Статично",
                motionOndulation: "Покачивание",
                motionFlux: "Поток",
                motionRipple: "Рябь",
                motionShimmer: "Мерцание",
                transHybrid: "Гибрид",
                transWhiteFlash: "Белая вспышка",
                transHueSlide: "Сдвиг оттенка",
                transShockwave: "Ударная волна",
                transPulse: "Пульс",
                transSupernova: "Сверхновая",
                transRings: "Кольца",
                transPrism: "Призма",
                transStrobe: "Стробоскоп",
                transBigBang: "Большой взрыв",
                transOff: "Выкл",
                surfaceNeon: "Неон",
                surfaceVelours: "Велюр"
            )
        case .es:
            return NotchLightsStrings(
                title: "Luces de la isla",
                enable: "Halos y laseres",
                description: "Ilumina los bordes del notch durante tareas de IA, musica, copias y avisos.",
                style: "Estilo del laser",
                armWidth: "Alcance",
                thickness: "Intensidad",
                entry: "Entrada",
                motion: "Movimiento continuo",
                transition: "Transicion de estado",
                edgeWave: "Onda en bordes de pantalla",
                edgeWaveHint: "Recorre los bordes de la pantalla cuando termina un turno de IA o salta una alerta.",
                lightSurface: "Acabado en barra clara",
                lightSurfaceHint: "Ajusta saturacion y sombras sobre una barra de menus clara.",
                agentActivity: "Turnos y alertas de IA",
                musicActivity: "Aura al reproducir musica",
                copySweep: "Barrido laser al copiar",
                notices: "Avisos de la isla",
                preview: "Probar efectos",
                previewHalo: "Halo",
                previewWave: "Onda",
                styleClassic: "Clasico",
                stylePixelated: "Pixelado Bayer",
                styleVolumetric: "Volumetrico",
                styleRays: "Rayos",
                styleBio: "Bioluminiscente",
                stylePrism: "Prisma",
                styleNimbus: "Nimbo",
                widthNarrow: "Estrecho",
                widthMedium: "Medio",
                widthWide: "Ancho",
                widthExtraWide: "Extra ancho",
                entrySweep: "Barrido",
                entryTrace: "Trazo",
                entryBlast: "Estallido",
                motionNone: "Fijo",
                motionOndulation: "Ondulacion",
                motionFlux: "Flujo",
                motionRipple: "Onda suave",
                motionShimmer: "Destello",
                transHybrid: "Hibrida",
                transWhiteFlash: "Destello blanco",
                transHueSlide: "Cambio de tono",
                transShockwave: "Onda expansiva",
                transPulse: "Pulso",
                transSupernova: "Supernova",
                transRings: "Anillos",
                transPrism: "Prisma",
                transStrobe: "Estrobo",
                transBigBang: "Big Bang",
                transOff: "Desactivada",
                surfaceNeon: "Neon",
                surfaceVelours: "Terciopelo"
            )
        case .sk:
            return NotchLightsStrings(
                title: "Svetla ostrova",
                enable: "Laserove a svetelne halo",
                description: "Rozziari okraje vyrezu pri ulohach AI, hudbe, kopirovani a upozorneniach.",
                style: "Styl lasera",
                armWidth: "Dosah",
                thickness: "Intenzita",
                entry: "Vstup",
                motion: "Priebezny pohyb",
                transition: "Prechod stavu",
                edgeWave: "Vlna po okrajoch obrazovky",
                edgeWaveHint: "Prejde po okrajoch displeja po skonceni tahu AI alebo pri upozorneni.",
                lightSurface: "Svetly panel ponuky",
                lightSurfaceHint: "Prispôsobi sytost a tiene na svetlom pozadi panela ponuky.",
                agentActivity: "Aktivita a upozornenia AI",
                musicActivity: "Aura prehravania hudby",
                copySweep: "Laserovy prelet pri kopirovani",
                notices: "Oznamenia ostrova",
                preview: "Vyskusat efekty",
                previewHalo: "Halo",
                previewWave: "Vlna",
                styleClassic: "Klasicky",
                stylePixelated: "Pixelovy Bayer",
                styleVolumetric: "Objemovy",
                styleRays: "Luce",
                styleBio: "Bioluminiscentny",
                stylePrism: "Prizma",
                styleNimbus: "Nimbus",
                widthNarrow: "Uzky",
                widthMedium: "Stredny",
                widthWide: "Siroky",
                widthExtraWide: "Extra siroky",
                entrySweep: "Prelet",
                entryTrace: "Kresba",
                entryBlast: "Vyboj",
                motionNone: "Staly",
                motionOndulation: "Vlnenie",
                motionFlux: "Prud",
                motionRipple: "Zvlnenie",
                motionShimmer: "Trblietanie",
                transHybrid: "Hybridny",
                transWhiteFlash: "Biely zablesk",
                transHueSlide: "Posun odtiena",
                transShockwave: "Tlakova vlna",
                transPulse: "Pulz",
                transSupernova: "Supernova",
                transRings: "Prstence",
                transPrism: "Prizma",
                transStrobe: "Stroboskop",
                transBigBang: "Velky tresk",
                transOff: "Vypnute",
                surfaceNeon: "Neon",
                surfaceVelours: "Zamat"
            )
        case .de:
            return NotchLightsStrings(
                title: "Insel-Lichter",
                enable: "Laser und Leuchtschein",
                description: "Beleuchtet die Notch-Raender bei KI-Aufgaben, Musik, Kopien und Hinweisen.",
                style: "Laser-Stil",
                armWidth: "Breite",
                thickness: "Intensitaet",
                entry: "Einblendung",
                motion: "Laufende Bewegung",
                transition: "Zustandswechsel",
                edgeWave: "Bildschirm-Randwelle",
                edgeWaveHint: "Laesst nach KI-Zuegen oder Warnungen eine Welle ueber den Bildschirmrand laufen.",
                lightSurface: "Helle Menueleiste",
                lightSurfaceHint: "Passt Farbsaettigung und Schatten auf heller Menueleiste an.",
                agentActivity: "KI-Agenten und Warnungen",
                musicActivity: "Musikwiedergabe-Aura",
                copySweep: "Laserwisch beim Kopieren",
                notices: "Insel-Meldungen",
                preview: "Effekte testen",
                previewHalo: "Halo",
                previewWave: "Randwelle",
                styleClassic: "Klassisch",
                stylePixelated: "Bayer-Pixel",
                styleVolumetric: "Volumetrisch",
                styleRays: "Strahlen",
                styleBio: "Biolumineszent",
                stylePrism: "Prisma",
                styleNimbus: "Nimbus",
                widthNarrow: "Schmal",
                widthMedium: "Mittel",
                widthWide: "Breit",
                widthExtraWide: "Extra breit",
                entrySweep: "Wisch",
                entryTrace: "Spur",
                entryBlast: "Impuls",
                motionNone: "Ruhig",
                motionOndulation: "Woge",
                motionFlux: "Fluss",
                motionRipple: "Kraeuseln",
                motionShimmer: "Schimmern",
                transHybrid: "Hybrid",
                transWhiteFlash: "Weisser Blitz",
                transHueSlide: "Farbverlauf",
                transShockwave: "Schockwelle",
                transPulse: "Puls",
                transSupernova: "Supernova",
                transRings: "Ringe",
                transPrism: "Prisma",
                transStrobe: "Stroboskop",
                transBigBang: "Urknall",
                transOff: "Aus",
                surfaceNeon: "Neon",
                surfaceVelours: "Samt"
            )
        case .fr:
            return NotchLightsStrings(
                title: "Lumieres de l’ilot",
                enable: "Halos et lasers lumineux",
                description: "Illumine les bords de l’encoche pendant l’IA, la musique, la copie et les alertes.",
                style: "Style du laser",
                armWidth: "Envergure",
                thickness: "Intensite",
                entry: "Entree",
                motion: "Mouvement continu",
                transition: "Transition d’etat",
                edgeWave: "Onde sur les bords d’ecran",
                edgeWaveHint: "Envoie une onde le long des bords de l’ecran a la fin d’un tour IA ou d’une alerte.",
                lightSurface: "Finition barre claire",
                lightSurfaceHint: "Adapte la saturation et l’ombre sur une barre des menus claire.",
                agentActivity: "Tours et alertes IA",
                musicActivity: "Aura de lecture musicale",
                copySweep: "Balayage laser a la copie",
                notices: "Avis de l’ilot",
                preview: "Tester les effets",
                previewHalo: "Halo",
                previewWave: "Onde",
                styleClassic: "Classique",
                stylePixelated: "Pixellise Bayer",
                styleVolumetric: "Volumetrique",
                styleRays: "Rayons",
                styleBio: "Bioluminescent",
                stylePrism: "Prisme",
                styleNimbus: "Nimbus",
                widthNarrow: "Etroit",
                widthMedium: "Moyen",
                widthWide: "Large",
                widthExtraWide: "Tres large",
                entrySweep: "Balayage",
                entryTrace: "Trace",
                entryBlast: "Eclat",
                motionNone: "Fixe",
                motionOndulation: "Ondulation",
                motionFlux: "Flux",
                motionRipple: "Rides",
                motionShimmer: "Scintillement",
                transHybrid: "Hybride",
                transWhiteFlash: "Flash blanc",
                transHueSlide: "Glissement teinte",
                transShockwave: "Onde de choc",
                transPulse: "Impulsion",
                transSupernova: "Supernova",
                transRings: "Anneaux",
                transPrism: "Prisme",
                transStrobe: "Stroboscope",
                transBigBang: "Big Bang",
                transOff: "Desactivee",
                surfaceNeon: "Neon",
                surfaceVelours: "Velours"
            )
        case .it:
            return NotchLightsStrings(
                title: "Luci dell’isola",
                enable: "Aloni e laser luminosi",
                description: "Illumina i bordi del notch durante attivita IA, musica, copie e avvisi.",
                style: "Stile del laser",
                armWidth: "Ampiezza",
                thickness: "Intensita",
                entry: "Ingresso",
                motion: "Movimento continuo",
                transition: "Transizione di stato",
                edgeWave: "Onda sui bordi schermo",
                edgeWaveHint: "Propagazione luminosa lungo i bordi dello schermo a fine turno IA o avviso.",
                lightSurface: "Barra menu chiara",
                lightSurfaceHint: "Adatta saturazione e ombre quando la barra dei menu e chiara.",
                agentActivity: "Turni e avvisi IA",
                musicActivity: "Aura riproduzione musica",
                copySweep: "Scia laser alla copia",
                notices: "Avvisi dell’isola",
                preview: "Prova effetti",
                previewHalo: "Alone",
                previewWave: "Onda",
                styleClassic: "Classico",
                stylePixelated: "Pixel Bayer",
                styleVolumetric: "Volumetrico",
                styleRays: "Raggi",
                styleBio: "Bioluminescente",
                stylePrism: "Prisma",
                styleNimbus: "Nimbo",
                widthNarrow: "Stretto",
                widthMedium: "Medio",
                widthWide: "Ampio",
                widthExtraWide: "Extra ampio",
                entrySweep: "Spazzata",
                entryTrace: "Traccia",
                entryBlast: "Esplosione",
                motionNone: "Fermo",
                motionOndulation: "Ondulazione",
                motionFlux: "Flusso",
                motionRipple: "Increspatura",
                motionShimmer: "Luccichio",
                transHybrid: "Ibrida",
                transWhiteFlash: "Flash bianco",
                transHueSlide: "Scorrimento tinta",
                transShockwave: "Onda d’urto",
                transPulse: "Impulso",
                transSupernova: "Supernova",
                transRings: "Anelli",
                transPrism: "Prisma",
                transStrobe: "Strobo",
                transBigBang: "Big Bang",
                transOff: "Disattivata",
                surfaceNeon: "Neon",
                surfaceVelours: "Velluto"
            )
        case .ja:
            return NotchLightsStrings(
                title: "アイランドライト",
                enable: "レーザーとハロー発光",
                description: "AI処理、音楽再生、コピー、通知のタイミングでノッチ周辺を発光させます。",
                style: "レーザースタイル",
                armWidth: "広がり",
                thickness: "強さ",
                entry: "開始モーション",
                motion: "継続モーション",
                transition: "状態遷移エフェクト",
                edgeWave: "画面エッジウェーブ",
                edgeWaveHint: "AIターン完了や警告時に画面の縁へショックウェーブを走らせます。",
                lightSurface: "ライトメニューバー仕上げ",
                lightSurfaceHint: "メニューバーが明るい背景のときの彩度と影を調整します。",
                agentActivity: "AIエージェント稼働と通知",
                musicActivity: "音楽再生オーラ",
                copySweep: "コピー時のレーザースイープ",
                notices: "アイランド通知",
                preview: "エフェクトを試す",
                previewHalo: "ハロー",
                previewWave: "エッジ波",
                styleClassic: "クラシック",
                stylePixelated: "ピクセル Bayer",
                styleVolumetric: "ボリュメトリック",
                styleRays: "レイ",
                styleBio: "バイオルミネッセンス",
                stylePrism: "プリズム",
                styleNimbus: "ニンバス",
                widthNarrow: "狭い",
                widthMedium: "標準",
                widthWide: "広い",
                widthExtraWide: "超広範囲",
                entrySweep: "スイープ",
                entryTrace: "トレース",
                entryBlast: "ブラスト",
                motionNone: "静止",
                motionOndulation: "うねり",
                motionFlux: "フラックス",
                motionRipple: "リップル",
                motionShimmer: "シマー",
                transHybrid: "ハイブリッド",
                transWhiteFlash: "ホワイトフラッシュ",
                transHueSlide: "色相スライド",
                transShockwave: "ショックウェーブ",
                transPulse: "パルス",
                transSupernova: "スーパーノヴァ",
                transRings: "リング",
                transPrism: "プリズム",
                transStrobe: "ストロボ",
                transBigBang: "ビッグバン",
                transOff: "オフ",
                surfaceNeon: "ネオン",
                surfaceVelours: "ベロア"
            )
        case .ko:
            return NotchLightsStrings(
                title: "아일랜드 라이트",
                enable: "레이저 및 헤일로 발광",
                description: "AI 작업, 음악 재생, 복사 및 알림 시 노치 가장자리를 밝힙니다.",
                style: "레이저 스타일",
                armWidth: "너비",
                thickness: "강도",
                entry: "시작 효과",
                motion: "유지 모션",
                transition: "상태 전환",
                edgeWave: "화면 테두리 웨이브",
                edgeWaveHint: "AI 작업이 끝나거나 경고가 발생할 때 화면 가장자리를 따라 파동을 보냅니다.",
                lightSurface: "밝은 메뉴 막대 마감",
                lightSurfaceHint: "메뉴 막대 배경이 밝을 때 채도와 그림자를 보정합니다.",
                agentActivity: "AI 에이전트 작업 및 알림",
                musicActivity: "음악 재생 오라",
                copySweep: "복사 시 레이저 스윕",
                notices: "아일랜드 알림",
                preview: "효과 미리보기",
                previewHalo: "헤일로",
                previewWave: "테두리 웨이브",
                styleClassic: "클래식",
                stylePixelated: "픽셀 Bayer",
                styleVolumetric: "볼류메트릭",
                styleRays: "광선",
                styleBio: "생체 발광",
                stylePrism: "프리즘",
                styleNimbus: "님버스",
                widthNarrow: "좁게",
                widthMedium: "보통",
                widthWide: "넓게",
                widthExtraWide: "매우 넓게",
                entrySweep: "스윕",
                entryTrace: "트레이스",
                entryBlast: "블래스트",
                motionNone: "고정",
                motionOndulation: "물결",
                motionFlux: "플럭스",
                motionRipple: "잔물결",
                motionShimmer: "반짝임",
                transHybrid: "하이브리드",
                transWhiteFlash: "화이트 플래시",
                transHueSlide: "색조 슬라이드",
                transShockwave: "충격파",
                transPulse: "펄스",
                transSupernova: "초신성",
                transRings: "링",
                transPrism: "프리즘",
                transStrobe: "스트로브",
                transBigBang: "빅뱅",
                transOff: "끔",
                surfaceNeon: "네온",
                surfaceVelours: "벨루어"
            )
        case .uk:
            return NotchLightsStrings(
                title: "Підсвічування острова",
                enable: "Лазерне сяйво та ореол",
                description: "Підсвічує краї вирізу під час роботи ШІ, музики, копіювання та сповіщень.",
                style: "Стиль лазера",
                armWidth: "Охоплення",
                thickness: "Інтенсивність",
                entry: "Поява",
                motion: "Рух",
                transition: "Зміна стану",
                edgeWave: "Хвиля краями екрана",
                edgeWaveHint: "Запускає хвилю уздовж країв дисплея після завершення завдання ШІ або сповіщення.",
                lightSurface: "Світла смуга меню",
                lightSurfaceHint: "Налаштовує насиченість і тіні на світлому фоні смуги меню.",
                agentActivity: "Активність та сповіщення ШІ",
                musicActivity: "Сяйво під час музики",
                copySweep: "Лазерний спалах при копіюванні",
                notices: "Сповіщення острова",
                preview: "Перевірка ефектів",
                previewHalo: "Ореол",
                previewWave: "Хвиля",
                styleClassic: "Класичний",
                stylePixelated: "Піксельний Байєр",
                styleVolumetric: "Об’ємний",
                styleRays: "Промені",
                styleBio: "Біолюмінесцентний",
                stylePrism: "Призма",
                styleNimbus: "Німб",
                widthNarrow: "Вузький",
                widthMedium: "Середній",
                widthWide: "Широкий",
                widthExtraWide: "Надширокий",
                entrySweep: "Змах",
                entryTrace: "Контур",
                entryBlast: "Спалах",
                motionNone: "Спокійний",
                motionOndulation: "Коливання",
                motionFlux: "Потік",
                motionRipple: "Брижі",
                motionShimmer: "Мерехтіння",
                transHybrid: "Гібрид",
                transWhiteFlash: "Білий спалах",
                transHueSlide: "Зсув відтінку",
                transShockwave: "Ударна хвиля",
                transPulse: "Пульс",
                transSupernova: "Наднова",
                transRings: "Кільця",
                transPrism: "Призма",
                transStrobe: "Стробоскоп",
                transBigBang: "Великий вибух",
                transOff: "Вимк",
                surfaceNeon: "Неон",
                surfaceVelours: "Велюр"
            )
        case .zhHans:
            return NotchLightsStrings(
                title: "灵动岛光效",
                enable: "激光与光晕",
                description: "在 AI 任务、音乐播放、复制和通知时点亮刘海边缘。",
                style: "激光样式",
                armWidth: "覆盖宽度",
                thickness: "强度",
                entry: "入场动效",
                motion: "持续动态",
                transition: "状态切换",
                edgeWave: "屏幕边缘光波",
                edgeWaveHint: "AI 回合结束或触发警报时沿屏幕四周扫过光波。",
                lightSurface: "浅色菜单栏质感",
                lightSurfaceHint: "在浅色菜单栏背景下调整光效饱和度与阴影。",
                agentActivity: "AI 代理活动与提醒",
                musicActivity: "音乐播放光环",
                copySweep: "复制时激光扫掠",
                notices: "灵动岛通知提示",
                preview: "测试光效",
                previewHalo: "光晕",
                previewWave: "边缘光波",
                styleClassic: "经典",
                stylePixelated: "拜耳像素",
                styleVolumetric: "体积光",
                styleRays: "射线",
                styleBio: "生物荧光",
                stylePrism: "棱镜",
                styleNimbus: "光云",
                widthNarrow: "窄",
                widthMedium: "适中",
                widthWide: "宽",
                widthExtraWide: "超宽",
                entrySweep: "扫掠",
                entryTrace: "描边",
                entryBlast: "爆发",
                motionNone: "静止",
                motionOndulation: "起伏",
                motionFlux: "流光",
                motionRipple: "涟漪",
                motionShimmer: "微闪",
                transHybrid: "混合",
                transWhiteFlash: "白闪",
                transHueSlide: "色相滑动",
                transShockwave: "冲击波",
                transPulse: "脉冲",
                transSupernova: "超新星",
                transRings: "光环",
                transPrism: "棱镜",
                transStrobe: "频闪",
                transBigBang: "大爆炸",
                transOff: "关闭",
                surfaceNeon: "霓虹",
                surfaceVelours: "丝绒"
            )
        case .zhTW:
            return NotchLightsStrings(
                title: "動態島光效",
                enable: "雷射與光暈",
                description: "在 AI 任務、音樂播放、複製與通知時點亮瀏海邊緣。",
                style: "雷射樣式",
                armWidth: "延伸寬度",
                thickness: "強度",
                entry: "入場效果",
                motion: "持續動態",
                transition: "狀態轉場",
                edgeWave: "螢幕邊緣光波",
                edgeWaveHint: "在 AI 回合結束或觸發警示時沿螢幕邊緣掃過光波。",
                lightSurface: "淺色選單列質感",
                lightSurfaceHint: "於淺色選單列背景自動微調飽和度與陰影。",
                agentActivity: "AI 代理動態與警示",
                musicActivity: "音樂播放光環",
                copySweep: "複製時雷射掃掠",
                notices: "動態島通知",
                preview: "測試光效",
                previewHalo: "光暈",
                previewWave: "邊緣光波",
                styleClassic: "經典",
                stylePixelated: "拜耳像素",
                styleVolumetric: "體積光",
                styleRays: "射線",
                styleBio: "生物螢光",
                stylePrism: "稜鏡",
                styleNimbus: "光雲",
                widthNarrow: "窄",
                widthMedium: "標準",
                widthWide: "寬",
                widthExtraWide: "超寬",
                entrySweep: "掃掠",
                entryTrace: "描邊",
                entryBlast: "爆發",
                motionNone: "靜止",
                motionOndulation: "波動",
                motionFlux: "流光",
                motionRipple: "漣漪",
                motionShimmer: "微閃",
                transHybrid: "混合",
                transWhiteFlash: "白閃",
                transHueSlide: "色相滑動",
                transShockwave: "衝擊波",
                transPulse: "脈衝",
                transSupernova: "超新星",
                transRings: "光環",
                transPrism: "稜鏡",
                transStrobe: "頻閃",
                transBigBang: "大爆炸",
                transOff: "關閉",
                surfaceNeon: "霓虹",
                surfaceVelours: "絲絨"
            )
        case .zhHK:
            return NotchLightsStrings(
                title: "動態島光效",
                enable: "激光與光暈",
                description: "喺 AI 任務、音樂播放、複製同通知時照亮瀏海邊緣。",
                style: "激光樣式",
                armWidth: "延伸闊度",
                thickness: "強度",
                entry: "入場效果",
                motion: "持續動態",
                transition: "狀態轉場",
                edgeWave: "螢幕邊緣光波",
                edgeWaveHint: "AI 回合完成或發出警示時沿螢幕邊緣掃過光波。",
                lightSurface: "淺色選單列質感",
                lightSurfaceHint: "喺淺色選單列背景下調整飽和度與陰影。",
                agentActivity: "AI 代理動態與警示",
                musicActivity: "音樂播放光環",
                copySweep: "複製時激光掃掠",
                notices: "動態島通知",
                preview: "測試光效",
                previewHalo: "光暈",
                previewWave: "邊緣光波",
                styleClassic: "經典",
                stylePixelated: "拜耳像素",
                styleVolumetric: "體積光",
                styleRays: "射線",
                styleBio: "生物螢光",
                stylePrism: "稜鏡",
                styleNimbus: "光雲",
                widthNarrow: "窄",
                widthMedium: "適中",
                widthWide: "闊",
                widthExtraWide: "超闊",
                entrySweep: "掃掠",
                entryTrace: "描邊",
                entryBlast: "爆發",
                motionNone: "靜止",
                motionOndulation: "波動",
                motionFlux: "流光",
                motionRipple: "漣漪",
                motionShimmer: "微閃",
                transHybrid: "混合",
                transWhiteFlash: "白閃",
                transHueSlide: "色相滑動",
                transShockwave: "衝擊波",
                transPulse: "脈衝",
                transSupernova: "超新星",
                transRings: "光環",
                transPrism: "稜鏡",
                transStrobe: "頻閃",
                transBigBang: "大爆炸",
                transOff: "關閉",
                surfaceNeon: "霓虹",
                surfaceVelours: "絲絨"
            )
        }
    }
}

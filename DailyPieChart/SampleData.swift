import Foundation

let samplePersons: [Person] = [
    Person(
        name: "チャールズ・ダーウィン",
        era: "1809–1882",
        bio: "進化論を提唱したイギリスの自然科学者。規則正しい生活リズムを維持しながら研究を続けた。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 8, colorIndex: 0),
            TimeBlock(name: "朝の散歩", hours: 1, colorIndex: 2),
            TimeBlock(name: "研究・執筆", hours: 3, colorIndex: 1),
            TimeBlock(name: "昼食・休憩", hours: 1.5, colorIndex: 4),
            TimeBlock(name: "読書・手紙", hours: 2, colorIndex: 5),
            TimeBlock(name: "午後の散歩", hours: 1.5, colorIndex: 2),
            TimeBlock(name: "研究（午後）", hours: 3, colorIndex: 1),
            TimeBlock(name: "夕食・家族", hours: 2, colorIndex: 3),
            TimeBlock(name: "読書・就寝準備", hours: 2, colorIndex: 6),
        ]
    ),
    Person(
        name: "ルートヴィヒ・ヴァン・ベートーヴェン",
        era: "1770–1827",
        bio: "ドイツの作曲家。朝から作曲に没頭し、コーヒーへのこだわりでも知られる。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 6, colorIndex: 0),
            TimeBlock(name: "朝食・コーヒー", hours: 1, colorIndex: 6),
            TimeBlock(name: "作曲（午前）", hours: 5, colorIndex: 1),
            TimeBlock(name: "昼食・散歩", hours: 2, colorIndex: 2),
            TimeBlock(name: "作曲（午後）", hours: 3, colorIndex: 1),
            TimeBlock(name: "夕食", hours: 1, colorIndex: 3),
            TimeBlock(name: "読書・交流", hours: 3, colorIndex: 5),
            TimeBlock(name: "夜の散歩", hours: 1, colorIndex: 2),
            TimeBlock(name: "就寝準備", hours: 2, colorIndex: 4),
        ]
    ),
    Person(
        name: "フランツ・カフカ",
        era: "1883–1924",
        bio: "チェコの小説家。保険会社に勤めながら、深夜に執筆するという生活を送った。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 6, colorIndex: 0),
            TimeBlock(name: "朝食・出勤準備", hours: 1, colorIndex: 6),
            TimeBlock(name: "仕事（保険会社）", hours: 6, colorIndex: 3),
            TimeBlock(name: "昼食・家族の時間", hours: 2, colorIndex: 5),
            TimeBlock(name: "仮眠", hours: 1.5, colorIndex: 4),
            TimeBlock(name: "運動", hours: 1, colorIndex: 2),
            TimeBlock(name: "夕食", hours: 1, colorIndex: 1),
            TimeBlock(name: "執筆（深夜）", hours: 3.5, colorIndex: 7),
            TimeBlock(name: "読書", hours: 2, colorIndex: 8),
        ]
    ),
    Person(
        name: "ベンジャミン・フランクリン",
        era: "1706–1790",
        bio: "アメリカ建国の父の一人。発明家・政治家・著述家でもあり、自己管理を徹底した。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 7, colorIndex: 0),
            TimeBlock(name: "朝の準備・計画", hours: 1, colorIndex: 6),
            TimeBlock(name: "朝食・読書", hours: 1, colorIndex: 5),
            TimeBlock(name: "仕事（午前）", hours: 4, colorIndex: 1),
            TimeBlock(name: "昼食・読書", hours: 2, colorIndex: 2),
            TimeBlock(name: "仕事（午後）", hours: 4, colorIndex: 1),
            TimeBlock(name: "夕食・交流", hours: 2, colorIndex: 3),
            TimeBlock(name: "音楽・会話", hours: 2, colorIndex: 4),
            TimeBlock(name: "一日の振り返り", hours: 1, colorIndex: 7),
        ]
    ),
    Person(
        name: "マヤ・アンジェロウ",
        era: "1928–2014",
        bio: "アメリカの詩人・活動家。ホテルに部屋を借りて執筆に集中するという独特のスタイルを持つ。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 7, colorIndex: 0),
            TimeBlock(name: "朝食・準備", hours: 1, colorIndex: 6),
            TimeBlock(name: "執筆（ホテル）", hours: 6, colorIndex: 1),
            TimeBlock(name: "昼食", hours: 1, colorIndex: 5),
            TimeBlock(name: "読書・インプット", hours: 2, colorIndex: 8),
            TimeBlock(name: "運動", hours: 1, colorIndex: 2),
            TimeBlock(name: "夕食", hours: 1.5, colorIndex: 3),
            TimeBlock(name: "家族・友人との時間", hours: 2, colorIndex: 4),
            TimeBlock(name: "読書・就寝準備", hours: 2.5, colorIndex: 7),
        ]
    ),
    Person(
        name: "イマヌエル・カント",
        era: "1724–1804",
        bio: "ドイツの哲学者。毎日まったく同じ時刻に起床・散歩・就寝し、街の人々が時計代わりにしたほど規則正しい生活を送った。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 7, colorIndex: 0),
            TimeBlock(name: "起床・お茶・思索準備", hours: 1, colorIndex: 6),
            TimeBlock(name: "執筆・思索", hours: 3, colorIndex: 1),
            TimeBlock(name: "講義", hours: 4, colorIndex: 3),
            TimeBlock(name: "昼食（長い）", hours: 2, colorIndex: 5),
            TimeBlock(name: "散歩", hours: 1, colorIndex: 2),
            TimeBlock(name: "読書", hours: 4, colorIndex: 8),
            TimeBlock(name: "就寝準備・軽食", hours: 2, colorIndex: 4),
        ]
    ),
    Person(
        name: "ウィンストン・チャーチル",
        era: "1874–1965",
        bio: "イギリスの首相。午前中はベッドの中で執筆・書類処理をこなし、午後には必ず昼寝をとることで長時間の集中力を維持した。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 8, colorIndex: 0),
            TimeBlock(name: "ベッドで執筆・書類処理", hours: 3, colorIndex: 1),
            TimeBlock(name: "朝食・新聞", hours: 1, colorIndex: 6),
            TimeBlock(name: "仕事（午前）", hours: 2, colorIndex: 3),
            TimeBlock(name: "昼食・交流", hours: 1.5, colorIndex: 5),
            TimeBlock(name: "昼寝", hours: 1.5, colorIndex: 4),
            TimeBlock(name: "仕事（午後）", hours: 3, colorIndex: 1),
            TimeBlock(name: "夕食・社交", hours: 2, colorIndex: 9),
            TimeBlock(name: "深夜の仕事", hours: 2, colorIndex: 7),
        ]
    ),
    Person(
        name: "マリー・キュリー",
        era: "1867–1934",
        bio: "ポーランド生まれの物理学者・化学者。ノーベル賞を2度受賞した史上初の人物。研究室に長時間こもり、放射線研究に人生を捧げた。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 7, colorIndex: 0),
            TimeBlock(name: "朝食・準備", hours: 1, colorIndex: 6),
            TimeBlock(name: "研究（午前）", hours: 5, colorIndex: 1),
            TimeBlock(name: "昼食（簡素）", hours: 0.5, colorIndex: 3),
            TimeBlock(name: "研究（午後）", hours: 5.5, colorIndex: 1),
            TimeBlock(name: "夕食・家族", hours: 2, colorIndex: 5),
            TimeBlock(name: "論文執筆・読書", hours: 2, colorIndex: 8),
            TimeBlock(name: "就寝準備", hours: 1, colorIndex: 4),
        ]
    ),
    Person(
        name: "ピョートル・チャイコフスキー",
        era: "1840–1893",
        bio: "ロシアの作曲家。毎日2時間の散歩を欠かさず、「散歩をやめたら死ぬ」と語ったほど歩くことを創作の源にした。",
        timeBlocks: [
            TimeBlock(name: "睡眠", hours: 8, colorIndex: 0),
            TimeBlock(name: "起床・お茶・読書", hours: 2, colorIndex: 6),
            TimeBlock(name: "作曲（午前）", hours: 3, colorIndex: 1),
            TimeBlock(name: "昼食", hours: 1, colorIndex: 3),
            TimeBlock(name: "散歩（必須）", hours: 2, colorIndex: 2),
            TimeBlock(name: "作曲（午後）", hours: 3, colorIndex: 1),
            TimeBlock(name: "夕食", hours: 1.5, colorIndex: 5),
            TimeBlock(name: "読書・交流", hours: 2, colorIndex: 9),
            TimeBlock(name: "就寝準備", hours: 1.5, colorIndex: 4),
        ]
    ),
    Person(
        name: "レオナルド・ダ・ヴィンチ",
        era: "1452–1519",
        bio: "イタリアの芸術家・科学者。多相睡眠（短い仮眠を繰り返す）を実践し、絵画・解剖学・工学など多分野で革新的な業績を残した。",
        timeBlocks: [
            TimeBlock(name: "睡眠（多相）", hours: 5.5, colorIndex: 0),
            TimeBlock(name: "制作・絵画（午前）", hours: 4, colorIndex: 7),
            TimeBlock(name: "散歩・自然観察", hours: 1.5, colorIndex: 2),
            TimeBlock(name: "昼食", hours: 1, colorIndex: 3),
            TimeBlock(name: "解剖・科学研究", hours: 3, colorIndex: 1),
            TimeBlock(name: "制作（午後）", hours: 4, colorIndex: 7),
            TimeBlock(name: "弟子・交流", hours: 2, colorIndex: 9),
            TimeBlock(name: "スケッチ・読書", hours: 3, colorIndex: 8),
        ]
    ),
]

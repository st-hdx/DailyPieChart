import SwiftUI

struct ClockChartView: View {
    let timeBlocks: [TimeBlock]
    var showHourLabels: Bool = true
    var showActivityLabels: Bool = true
    @State private var progress: Double = 0

    var sliceData: [(start: Angle, end: Angle, block: TimeBlock)] {
        let gap = 0.4
        var result: [(Angle, Angle, TimeBlock)] = []
        var currentHours = 0.0
        for block in timeBlocks {
            let startDeg = currentHours / 24.0 * 360.0 - 90.0
            let endDeg = (currentHours + block.hours) / 24.0 * 360.0 - 90.0
            result.append((.degrees(startDeg + gap), .degrees(endDeg - gap), block))
            currentHours += block.hours
        }
        return result
    }

    // スライスの中間角度（ラジアン）と活動名
    var activityMidpoints: [(angle: CGFloat, name: String, hours: Double)] {
        let pi = CGFloat.pi
        var result: [(CGFloat, String, Double)] = []
        var currentHours = 0.0
        for block in timeBlocks {
            let startDeg = currentHours / 24.0 * 360.0 - 90.0
            let endDeg = (currentHours + block.hours) / 24.0 * 360.0 - 90.0
            let midRad = CGFloat((startDeg + endDeg) / 2.0) * pi / 180.0
            result.append((midRad, block.name, block.hours))
            currentHours += block.hours
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            clockContent(geo: geo)
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(progress)
        .opacity(progress)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                progress = 1.0
            }
        }
    }

    @ViewBuilder
    private func clockContent(geo: GeometryProxy) -> some View {
        let margin: CGFloat = showActivityLabels ? 52 : 0
        let s = min(geo.size.width, geo.size.height) - margin * 2
        let cx = geo.size.width / 2
        let cy = geo.size.height / 2
        let outerR: CGFloat = showActivityLabels ? s * 0.38 : (showHourLabels ? s * 0.365 : s * 0.45)
        let innerR = outerR * 0.52
        let hourLabelR = outerR * 1.18

        ZStack {
            backgroundRing(cx: cx, cy: cy, outerR: outerR, innerR: innerR)
            slicesLayer(cx: cx, cy: cy, outerR: outerR, innerR: innerR)
            tickMarksLayer(cx: cx, cy: cy, outerR: outerR, innerR: innerR)
            if showHourLabels {
                hourLabelsLayer(cx: cx, cy: cy, labelR: hourLabelR, s: s)
                VStack(spacing: 1) {
                    Text("24")
                        .font(.system(size: s * 0.10, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textWarm.opacity(0.72))
                    Text("HOUR")
                        .font(.system(size: s * 0.038, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textWarm.opacity(0.42))
                }
                .position(x: cx, y: cy)
            }
            if showActivityLabels {
                activityLabelsLayer(cx: cx, cy: cy, outerR: outerR, s: s)
            }
        }
    }

    private func backgroundRing(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> some View {
        Path { path in
            path.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                        startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
            path.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                        startAngle: .degrees(270), endAngle: .degrees(-90), clockwise: true)
            path.closeSubpath()
        }
        .fill(Theme.ringBg)
    }

    private func slicesLayer(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> some View {
        ZStack {
            ForEach(Array(sliceData.enumerated()), id: \.offset) { _, slice in
                Path { path in
                    path.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                                startAngle: slice.start, endAngle: slice.end, clockwise: false)
                    path.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                                startAngle: slice.end, endAngle: slice.start, clockwise: true)
                    path.closeSubpath()
                }
                .fill(blockColors[slice.block.colorIndex % blockColors.count])
            }
        }
    }

    private func tickMarksLayer(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> some View {
        let pi = CGFloat.pi
        return ZStack {
            ForEach(0..<24) { hour in
                let angle = CGFloat(hour) / 24.0 * 2.0 * pi - pi / 2.0
                let isMajor = hour % 6 == 0
                let tickInnerR = isMajor ? innerR : innerR * 1.2
                Path { path in
                    path.move(to: CGPoint(x: cx + tickInnerR * cos(angle),
                                         y: cy + tickInnerR * sin(angle)))
                    path.addLine(to: CGPoint(x: cx + outerR * cos(angle),
                                            y: cy + outerR * sin(angle)))
                }
                .stroke(Color(red: 0.50, green: 0.40, blue: 0.28).opacity(isMajor ? 0.45 : 0.20),
                        lineWidth: isMajor ? 1.5 : 0.7)
            }
        }
    }

    private func hourLabelsLayer(cx: CGFloat, cy: CGFloat, labelR: CGFloat, s: CGFloat) -> some View {
        let pi = CGFloat.pi
        return ZStack {
            ForEach(0..<24) { hour in
                let angle = CGFloat(hour) / 24.0 * 2.0 * pi - pi / 2.0
                let isMajor = hour % 6 == 0
                Text("\(hour)")
                    .font(.system(
                        size: isMajor ? s * 0.06 : s * 0.035,
                        weight: isMajor ? .semibold : .regular,
                        design: .rounded
                    ))
                    .foregroundColor(isMajor ? Theme.textWarm.opacity(0.70) : Theme.textWarm.opacity(0.38))
                    .position(x: cx + labelR * cos(angle),
                              y: cy + labelR * sin(angle))
            }
        }
    }

    private func activityLabelsLayer(cx: CGFloat, cy: CGFloat, outerR: CGFloat, s: CGFloat) -> some View {
        ZStack {
            ForEach(Array(activityMidpoints.enumerated()), id: \.offset) { _, item in
                if item.hours >= 1.0 {
                    activityLabelItem(angle: item.angle, name: item.name,
                                      cx: cx, cy: cy, outerR: outerR, s: s)
                }
            }
        }
    }

    @ViewBuilder
    private func activityLabelItem(angle: CGFloat, name: String,
                                   cx: CGFloat, cy: CGFloat,
                                   outerR: CGFloat, s: CGFloat) -> some View {
        // 引き出し線
        Path { path in
            path.move(to: CGPoint(x: cx + outerR * 1.04 * cos(angle),
                                  y: cy + outerR * 1.04 * sin(angle)))
            path.addLine(to: CGPoint(x: cx + outerR * 1.35 * cos(angle),
                                     y: cy + outerR * 1.35 * sin(angle)))
        }
        .stroke(Theme.textWarm.opacity(0.25), lineWidth: 0.8)

        // ラベル
        Text(name)
            .font(.system(size: max(s * 0.038, 9), weight: .medium))
            .foregroundColor(Theme.textWarm.opacity(0.80))
            .lineLimit(1)
            .frame(maxWidth: outerR * 0.9)
            .position(x: cx + outerR * 1.48 * cos(angle),
                      y: cy + outerR * 1.48 * sin(angle))
    }
}

struct PieChartView: View {
    let timeBlocks: [TimeBlock]

    var timeRanges: [(block: TimeBlock, startHour: Double)] {
        var result: [(TimeBlock, Double)] = []
        var current = 0.0
        for block in timeBlocks {
            result.append((block, current))
            current += block.hours
        }
        return result
    }

    var body: some View {
        VStack(spacing: 16) {
            ClockChartView(timeBlocks: timeBlocks)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(timeRanges, id: \.block.id) { item in
                    legendItem(block: item.block, startHour: item.startHour)
                }
            }
            .padding(.horizontal)
        }
    }

    private func legendItem(block: TimeBlock, startHour: Double) -> some View {
        let color = blockColors[block.colorIndex % blockColors.count]
        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.7), radius: 3, x: 0, y: 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(formatTimeRange(start: startHour, duration: block.hours))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.30), lineWidth: 1)
        )
        .cornerRadius(10)
        .shadow(color: Theme.cardShadow.opacity(0.08), radius: 4, x: 0, y: 1)
    }

    func formatTimeRange(start: Double, duration: Double) -> String {
        func fmt(_ h: Double) -> String {
            let hour = Int(h) % 24
            let min = Int((h - Double(Int(h))) * 60)
            return String(format: "%d:%02d", hour, min)
        }
        return "\(fmt(start))〜\(fmt(start + duration))"
    }
}

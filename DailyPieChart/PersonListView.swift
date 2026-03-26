import SwiftUI

struct PersonListView: View {
    @EnvironmentObject var store: StoreManager
    @State private var showPaywall = false
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("偉人たちの習慣から")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accentGradient)
                        Text("自分の一日を設計しよう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(samplePersons.enumerated()), id: \.element.id) { index, person in
                            let isLocked = !store.isPro && index >= StoreManager.freePersonLimit
                            if isLocked {
                                Button { showPaywall = true } label: {
                                    LockedPersonCard(person: person)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                NavigationLink(destination: PersonDetailView(person: person)) {
                                    PersonCard(person: person)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    if !store.isPro {
                        proTeaser
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("偉人たちの一日")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
    }

    private var proTeaser: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accentGradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text("残り\(samplePersons.count - StoreManager.freePersonLimit)人をアンロック")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textWarm)
                    Text("Pro にアップグレード")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.accent1.opacity(0.4), lineWidth: 1))
            .cornerRadius(14)
            .shadow(color: Theme.accent1.opacity(0.12), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PersonCard

struct PersonCard: View {
    let person: Person

    var accentColor: Color {
        blockColors[(person.timeBlocks.first?.colorIndex ?? 0) % blockColors.count]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                )

            VStack(spacing: 0) {
                HStack {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.25)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: 36, height: 3)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                ClockChartView(
                    timeBlocks: person.timeBlocks,
                    showHourLabels: false,
                    showActivityLabels: false
                )
                .frame(height: 130)
                .padding(.horizontal, 8)
                .padding(.top, 6)

                VStack(alignment: .leading, spacing: 3) {
                    Text(person.name)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textWarm)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(person.era)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .shadow(color: Theme.cardShadow.opacity(0.18), radius: 14, x: 0, y: 4)
    }
}

// MARK: - LockedPersonCard

struct LockedPersonCard: View {
    let person: Person

    var body: some View {
        ZStack {
            PersonCard(person: person)

            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.background.opacity(0.72))

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.accentGradient)
                Text("Pro")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.accentGradient)
                    .cornerRadius(8)
            }
        }
    }
}

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle().fill(Theme.mintTint).frame(width: 200, height: 200)
                    Circle().fill(Theme.mint.opacity(0.28)).frame(width: 142, height: 142)
                    Circle().fill(Theme.mint.opacity(0.55)).frame(width: 91, height: 91)
                    Circle().fill(Theme.night).frame(width: 55, height: 55)
                    Image(systemName: "location.fill").font(.sys(size: 22, weight: .bold)).foregroundStyle(Theme.mint)
                    ZStack {
                        Circle().fill(Theme.mint)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.night).frame(width: 15, height: 17)
                        Rectangle().fill(Theme.sun).frame(width: 15, height: 2).offset(y: -4)
                    }
                    .frame(width: 36, height: 36)
                    .offset(x: -66, y: 66)
                }
                .frame(maxWidth: .infinity).padding(.top, 8)

                Text(L("Find the Qibla, wherever you are"))
                    .font(.sys(size: 34, weight: .heavy, design: Theme.design)).foregroundStyle(Theme.ink)
                    .padding(.top, 20)
                Text(L("Your location is used to work out the Qibla, your prayer times, nearby mosques and the weather."))
                    .font(.sys(size: 16)).foregroundStyle(Theme.muted).padding(.top, 8)

                VStack(spacing: 0) {
                    point("iphone", "Calculated on your phone", "Qibla and prayer times need no server")
                    Divider().overlay(Theme.line)
                    point("person.crop.circle.badge.xmark", "No account needed", "No sign-up, no tracking, no ads")
                    Divider().overlay(Theme.line)
                    point("wifi.slash", "Works offline", "Qibla and prayer times, anywhere")
                }
                .padding(.horizontal, 16).card().padding(.top, 18)

                Spacer(minLength: 16)

                Button {
                    model.usingGPS = true
                    model.location.requestAccess()
                    model.welcomed = true
                } label: {
                    HStack(spacing: 10) {
                        Text(L("Allow location while using the app"))
                        Image(systemName: "arrow.right").foregroundStyle(Theme.mint)
                    }
                    .font(.sys(size: 16, weight: .bold, design: Theme.design))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundStyle(Theme.isClassic ? Theme.onAccent : .white)
                    .background(Theme.isClassic ? Theme.mint : Theme.night, in: Capsule())
                }
                Button {
                    model.usingGPS = false
                    model.tab = 2
                    model.welcomed = true
                } label: {
                    Text(L("Choose a city instead"))
                        .font(.sys(size: 15, weight: .bold, design: Theme.design))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
    }

    private func point(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.sys(size: 16, weight: .semibold)).foregroundStyle(Theme.mintDeep)
                .frame(width: 36, height: 36).background(Theme.mintTint, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(L(title)).font(.sys(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                Text(L(sub)).font(.sys(size: 13)).foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .frame(minHeight: 58)
    }
}

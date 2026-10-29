import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var showCities = false
    @State private var showOffsets = false
    @State private var showFonts = false
    @State private var notifDenied = false
    @AppStorage("tempUnit") private var tempUnit = "c"
    @AppStorage("compassStyle") private var compassStyle = "classic"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    PageTitle(en: "Settings", ar: "الإعدادات")

                    header(L("theme"))
                    group {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                icon("paintpalette")
                                Text(L("Theme")).font(.sys(size: 17, weight: .semibold)).foregroundStyle(Theme.ink)
                            }
                            HStack(spacing: 0) {
                                ForEach(PaletteDef.all) { p in swatch(id: p.id, title: p.title, color: Color(hex: p.swatch)) }
                            }
                            .padding(.vertical, 2)
                            Picker(L("Appearance"), selection: $model.appearance) {
                                Text(L("Auto")).tag("auto"); Text(L("Light")).tag("light"); Text(L("Dark")).tag("dark")
                            }
                            .pickerStyle(.segmented)
                            HStack(spacing: 14) {
                                icon("safari")
                                Text(L("Compass style")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                Spacer()
                            }
                            Picker(L("Compass style"), selection: $compassStyle) {
                                Text(L("Classic")).tag("classic"); Text(L("Rings")).tag("rings")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 14)
                    }

                    header(L("accessibility"))
                    group {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 14) {
                                icon("textformat.size")
                                Text(L("Text size")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                Spacer()
                                Menu {
                                    Picker(L("Text size"), selection: $model.textSize) {
                                        Text(L("Auto (iPhone setting)")).tag("auto")
                                        Text(L("Standard")).tag("1")
                                        Text(L("Large")).tag("1.2")
                                        Text(L("Larger")).tag("1.4")
                                        Text(L("Largest")).tag("1.6")
                                    }
                                } label: { menuValue(textSizeName) }
                            }.frame(minHeight: 56)
                            divider
                            HStack(spacing: 14) {
                                icon("book")
                                Text(L("Azkhar text size")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                Spacer()
                                Menu {
                                    Picker(L("Azkhar text size"), selection: $model.azkarSize) {
                                        Text(L("Standard")).tag("1")
                                        Text(L("Large")).tag("1.25")
                                        Text(L("Larger")).tag("1.5")
                                        Text(L("Largest")).tag("2")
                                    }
                                } label: { menuValue(azkarSizeName) }
                            }.frame(minHeight: 56)
                            divider
                            HStack(spacing: 14) {
                                icon("bold")
                                Toggle(L("Bold text"), isOn: $model.boldText).tint(Theme.mintDeep)
                            }.frame(minHeight: 56)
                        }
                    }

                    header(L("language"))
                    group {
                        HStack(spacing: 14) {
                            icon("globe")
                            Text(L("Application language")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                            Spacer()
                            Menu {
                                Picker(L("Language"), selection: $model.langID) {
                                    ForEach(AppLang.all) { Text($0.title).tag($0.id) }
                                }
                            } label: { menuValue(Loc.ar ? "العربية" : (AppLang.current.title.components(separatedBy: " · ").last ?? "")) }
                        }.frame(minHeight: 56)
                        Divider().overlay(Theme.line.opacity(0.5))
                        Button { showFonts = true } label: {
                            HStack(spacing: 14) {
                                icon("textformat")
                                Text(L("App font")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(AppFont.current?.title ?? L("System default")).font(.sys(size: 17)).foregroundStyle(Theme.muted).lineLimit(1)
                                Image(systemName: "chevron.forward").font(.sys(size: 14, weight: .semibold)).foregroundStyle(Theme.muted)
                            }
                            .frame(minHeight: 56).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }

                    header(L("prayers"))
                    group {
                        Button { model.useMyLocation() } label: {
                            HStack(spacing: 14) {
                                icon("location.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("Current location")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                    Text(model.usingGPS ? model.place.name : (model.lastGPSName ?? L("Use my location")))
                                        .font(.sys(size: 13)).foregroundStyle(Theme.muted).lineLimit(1)
                                }
                                Spacer()
                                if model.usingGPS { Image(systemName: "checkmark").font(.sys(size: 16, weight: .bold)).foregroundStyle(Theme.mintDeep) }
                            }
                            .frame(minHeight: 56).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        divider
                        Button { showCities = true } label: {
                            HStack(spacing: 14) {
                                icon("mappin.and.ellipse")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("Choose a city")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                    if !model.usingGPS { Text(model.place.name).font(.sys(size: 13)).foregroundStyle(Theme.muted).lineLimit(1) }
                                }
                                Spacer()
                                if !model.usingGPS { Image(systemName: "checkmark").font(.sys(size: 16, weight: .bold)).foregroundStyle(Theme.mintDeep) }
                                Image(systemName: "chevron.right").font(.sys(size: 14, weight: .semibold)).foregroundStyle(Theme.muted)
                            }
                            .frame(minHeight: 56).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        divider
                        TimelineView(.everyMinute) { ctx in
                            HStack(spacing: 14) {
                                icon("clock")
                                Text(L("Local time")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(localClock(ctx.date, model.place.timeZone)).font(.sys(size: 17)).foregroundStyle(Theme.muted).monospacedDigit()
                            }.frame(minHeight: 56)
                        }
                        Text(Loc.ar ? "الصلاة والقبلة والمساجد والطقس كلها تعتمد على هذا الموقع. المنطقة الزمنية: \(model.place.tz)" : Loc.f("Prayer times, Qibla, mosques and weather all use this location. Time zone: {0}", model.place.tz))
                            .font(.footnote).foregroundStyle(Theme.muted).sideAligned().padding(.bottom, 10)
                        if model.location.denied {
                            Text(L("Location is off for this app. Turn it on in iPhone Settings, or choose a city."))
                                .font(.footnote).foregroundStyle(Theme.muted).sideAligned().padding(.bottom, 10)
                        } else if model.usingGPS && model.location.coordinate == nil {
                            Text(L("Finding your location…")).font(.footnote).foregroundStyle(Theme.muted).sideAligned().padding(.bottom, 10)
                        }
                        divider
                        HStack(spacing: 14) {
                            icon("function")
                            Text(L("Method")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                            Spacer()
                            Menu {
                                Picker(L("Method"), selection: $model.methodID) {
                                    ForEach(CalcMethod.all) { Text(L($0.name)).tag($0.id) }
                                }
                            } label: { menuValue(shortMethod(model.method.name)) }
                        }.frame(minHeight: 56)
                        divider
                        Button { showOffsets = true } label: {
                            row("plusminus.circle", "Adjust times", "minutes", chevron: true)
                        }
                        divider
                        HStack(spacing: 14) {
                            icon("sun.max")
                            Toggle(L("Hanafi Asr"), isOn: $model.hanafi).tint(Theme.mintDeep)
                                .font(.sys(size: 17)).foregroundStyle(Theme.ink)
                        }.frame(minHeight: 56)
                    }

                    header(L("notifications"))
                    group {
                        HStack(spacing: 14) {
                            icon("bell")
                            Toggle(L("Adhan alerts"), isOn: Binding(
                                get: { model.notifOn },
                                set: { on in
                                    model.notifOn = on
                                    if on { Notifier.requestAuth { _ in refreshNotifStatus(); model.rescheduleNotifications() } }
                                })).tint(Theme.mintDeep)
                                .font(.sys(size: 17)).foregroundStyle(Theme.ink)
                        }.frame(minHeight: 56)
                        if model.notifOn && notifDenied {
                            Text(L("Notifications are off for this app in iPhone Settings."))
                                .font(.footnote).foregroundStyle(Theme.muted)
                            Button { Notifier.openIPhoneSettings() } label: {
                                Text(L("Open iPhone Settings")).font(.sys(size: 15, weight: .semibold)).foregroundStyle(.blue)
                            }.padding(.bottom, 10)
                        }
                        divider
                        HStack(spacing: 14) {
                            icon("speaker.wave.2")
                            Text(Loc.ar ? "صوت الأذان" : L("Adhan sound")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                            Spacer()
                            Button { Notifier.previewAzan() } label: {
                                Image(systemName: "play.circle.fill").font(.sys(size: 26)).foregroundStyle(Theme.mintDeep)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Loc.ar ? "استماع" : "Play")
                        }.frame(minHeight: 56)
                        divider
                        HStack(spacing: 14) {
                            icon("clock.badge")
                            Text(L("Remind me before")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                            Spacer()
                            Menu {
                                Picker(L("Remind"), selection: $model.notifBefore) {
                                    Text(L("Off")).tag(0)
                                    ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) " + L("min")).tag($0) }
                                }
                            } label: { menuValue(model.notifBefore == 0 ? L("Off") : "\(model.notifBefore) " + L("min")) }
                        }.frame(minHeight: 56)
                        divider
                        HStack(spacing: 14) {
                            icon("sunrise")
                            Toggle(L("Sunrise alert"), isOn: $model.notifSunrise).tint(Theme.mintDeep)
                                .font(.sys(size: 17)).foregroundStyle(Theme.ink)
                        }.frame(minHeight: 56)
                    }
                    Text(Loc.ar ? "بجانب كل صلاة: زر المنبّه يشغّل الأذان، وزر الجرس يرسل تنبيهًا بدون أذان."
                                : L("Next to each prayer: the alarm button plays the adhan, the bell sends a notification without it."))
                        .font(.sys(size: 12)).foregroundStyle(Theme.muted).sideAligned().padding(.horizontal, 6)

                    header(L("compass"))
                    group {
                        HStack(spacing: 14) {
                            icon("hand.draw")
                            Toggle(L("Preview mode (turn dial by hand)"), isOn: $model.previewMode).tint(Theme.mintDeep)
                                .font(.sys(size: 17)).foregroundStyle(Theme.ink)
                        }.frame(minHeight: 56)
                    }

                    header(L("units"))
                    group {
                        HStack(spacing: 14) {
                            icon("thermometer.medium")
                            Text(L("Temperature")).font(.sys(size: 17)).foregroundStyle(Theme.ink)
                            Spacer()
                            Menu {
                                Picker(L("Temperature"), selection: $tempUnit) {
                                    Text(L("Celsius (°C)")).tag("c")
                                    Text(L("Fahrenheit (°F)")).tag("f")
                                }
                            } label: { menuValue(tempUnit == "f" ? "°F" : "°C") }
                        }.frame(minHeight: 56)
                    }

                    group {
                        row("info.circle", "About", "Rihal 1.0", chevron: false)
                    }
                    .padding(.top, 14)

                    Text(L("Qibla and prayer times are calculated on this device. Your approximate location is sent only when you look up mosques, weather or cities."))
                        .font(.sys(size: 12)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationDestination(isPresented: $showCities) { CityListView() }
            .navigationDestination(isPresented: $showOffsets) { OffsetsView() }
            .navigationDestination(isPresented: $showFonts) { FontPickerView() }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { refreshNotifStatus() }
        }
        .environment(\.layoutDirection, AppLang.current.isRTL ? .rightToLeft : .leftToRight)   // Arabic reads from the right
    }

    // MARK: pieces
    private func refreshNotifStatus() { Notifier.status { notifDenied = ($0 == .denied) } }
    private var textSizeName: String {
        switch model.textSize { case "auto": return L("Auto"); case "1.2": return L("Large"); case "1.4": return L("Larger"); case "1.6": return L("Largest"); default: return L("Standard") }
    }
    private var azkarSizeName: String {
        switch model.azkarSize { case "1.25": return L("Large"); case "1.5": return L("Larger"); case "2": return L("Largest"); default: return L("Standard") }
    }
    private func menuValue(_ t: String) -> some View {
        HStack(spacing: 6) {
            Text(L(t)).font(.sys(size: 17)).foregroundStyle(Theme.muted).lineLimit(1).fixedSize()
            Image(systemName: "chevron.up.chevron.down").font(.sys(size: 13, weight: .semibold)).foregroundStyle(Theme.muted)
        }
    }
    private func shortMethod(_ n: String) -> String {
        ["Muslim World League": "MWL", "Egyptian General Authority": "Egypt", "Karachi (UIS)": "Karachi",
         "ISNA (North America)": "ISNA", "Umm al-Qura (Makkah)": "Umm al-Qura"][n] ?? n
    }
    private func header(_ t: String) -> some View {
        Text(L(t)).font(.sys(size: 20, weight: .bold, design: Theme.design))
            .foregroundStyle(Theme.muted).padding(.leading, 6).padding(.top, 14)
    }
    private func group<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0, content: c)
            .padding(.horizontal, 18).frame(maxWidth: .infinity, alignment: .leading).card(28)
    }
    private func localClock(_ d: Date, _ tz: TimeZone) -> String {
        let f = DateFormatter(); f.timeZone = tz; f.locale = Locale(identifier: "en_GB"); f.dateFormat = "HH:mm"
        let m = tz.secondsFromGMT(for: d) / 60
        return "\(f.string(from: d)) · GMT" + (m >= 0 ? "+" : "-") + String(format: "%d:%02d", abs(m) / 60, abs(m) % 60)
    }
    private var divider: some View { Divider().overlay(Theme.line).padding(.leading, 42) }
    private func icon(_ n: String) -> some View {
        Image(systemName: n).font(.sys(size: 20)).foregroundStyle(Theme.muted).frame(width: 28)
    }
    private func row(_ ic: String, _ title: String, _ value: String, chevron: Bool) -> some View {
        HStack(spacing: 14) {
            icon(ic)
            Text(L(title)).font(.sys(size: 17)).foregroundStyle(Theme.ink)
            Spacer()
            Text(L(value)).font(.sys(size: 17)).foregroundStyle(Theme.muted).lineLimit(1)
            if chevron { Image(systemName: "chevron.right").font(.sys(size: 14, weight: .semibold)).foregroundStyle(Theme.muted) }
        }
        .frame(minHeight: 56).contentShape(Rectangle())
    }

    private func swatch(id: String, title: String, color: Color?) -> some View {
        let on = model.paletteID == id
        return Button { model.paletteID = id } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color ?? Theme.tile).frame(width: 40, height: 40)
                    if color == nil { Image(systemName: "paintpalette").font(.sys(size: 16)).foregroundStyle(Theme.muted) }
                    if on { Image(systemName: "checkmark").font(.sys(size: 14, weight: .heavy)).foregroundStyle(.white) }
                }
                .overlay(Circle().stroke(on ? Theme.ink : Theme.line, lineWidth: on ? 2.5 : 1).frame(width: 48, height: 48))
                .frame(width: 50, height: 50)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(L(title))
        }
        .buttonStyle(.plain)
    }

}

struct CityListView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CityPickerList(selectedName: model.usingGPS ? nil : model.place.name, onPick: { c in
            if Cities.all.contains(where: { $0.name == c.name && $0.isoCode == c.isoCode }) { model.chooseCity(c) } else { model.pin(c) }
            dismiss()
        }, header: { EmptyView() })
        .navigationTitle(L("City"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OffsetsView: View {
    @AppStorage("off_fajr") private var fajr = 0
    @AppStorage("off_sunrise") private var sunrise = 0
    @AppStorage("off_dhuhr") private var dhuhr = 0
    @AppStorage("off_asr") private var asr = 0
    @AppStorage("off_maghrib") private var maghrib = 0
    @AppStorage("off_isha") private var isha = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("Add or subtract minutes to match your local mosque or official timetable."))
                    .font(.sys(size: 14)).foregroundStyle(Theme.muted)
                VStack(spacing: 0) {
                    line("Fajr", $fajr); Divider().overlay(Theme.line)
                    line("Sunrise", $sunrise); Divider().overlay(Theme.line)
                    line("Dhuhr", $dhuhr); Divider().overlay(Theme.line)
                    line("Asr", $asr); Divider().overlay(Theme.line)
                    line("Maghrib", $maghrib); Divider().overlay(Theme.line)
                    line("Isha", $isha)
                }
                .padding(.horizontal, 18).card(28)
                Button {
                    fajr = 0; sunrise = 0; dhuhr = 0; asr = 0; maghrib = 0; isha = 0
                } label: {
                    Text(L("Reset all to 0")).font(.sys(size: 16, weight: .bold, design: Theme.design))
                        .frame(maxWidth: .infinity, minHeight: 50).foregroundStyle(Theme.ink).card(25)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(L("Adjust times"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func line(_ name: String, _ v: Binding<Int>) -> some View {
        HStack {
            Text(L(name)).font(.sys(size: 17, weight: .semibold)).foregroundStyle(Theme.ink)
            Spacer()
            Text(v.wrappedValue == 0 ? "0 \(L("min"))" : String(format: "%+d ", v.wrappedValue) + L("min"))
                .font(.sys(size: 16)).monospacedDigit()
                .foregroundStyle(v.wrappedValue == 0 ? Theme.muted : Theme.mintDeep)
            Stepper("", value: v, in: -30...30).labelsHidden()
        }
        .frame(minHeight: 56)
    }
}

extension View {
    /// Notes run from the right in Arabic and from the left otherwise.
    func sideAligned() -> some View {
        multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)   // leading is the right edge in right-to-left pages
    }
}

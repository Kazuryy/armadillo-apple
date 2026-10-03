import SwiftUI

/// Version, licence and the "not affiliated" notice.
struct TVAboutView: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (short, build) {
        case let (short?, build?): return "\(short) (\(build))"
        case let (short?, nil): return short
        default: return "Unknown"
        }
    }

    var body: some View {
        TVScreen(
            title: "About",
            subtitle: "An independent client for Pangolin."
        ) {
            VStack(spacing: 16) {
                TVInfoCard {
                    TVRowLabel(systemImage: "tag.fill", title: version, subtitle: "Version")
                }
                TVInfoCard {
                    TVRowLabel(
                        systemImage: "doc.text.fill", title: "AGPL-3.0",
                        subtitle: "License. The source code is public.")
                }
                TVInfoCard {
                    TVRowLabel(
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        title: "github.com/Kazuryy/armadillo-apple", subtitle: "Source code")
                }
                TVInfoCard {
                    TVRowLabel(
                        systemImage: "hand.raised.fill",
                        title: "github.com/Kazuryy/armadillo-apple/blob/main/PRIVACY.md",
                        subtitle: "Privacy policy")
                }

                TVFootnote(
                    "Armadillo is an independent, community-built project. It is not affiliated with, endorsed by, or sponsored by Fossorial, Inc., the makers of Pangolin.")
            }
        }
    }
}

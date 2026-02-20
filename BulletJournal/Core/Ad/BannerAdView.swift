//
//  BannerAdView.swift
//  BulletJournal
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    @State private var adHeight: CGFloat = 0

    var body: some View {
        BannerAdRepresentable(adHeight: $adHeight)
            .frame(height: adHeight)
    }
}

private struct BannerAdRepresentable: UIViewRepresentable {
    @Binding var adHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(adHeight: $adHeight)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let bannerView = BannerView()
        bannerView.adUnitID = AdConfiguration.bannerAdUnitID
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        context.coordinator.bannerView = bannerView

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let bannerView = context.coordinator.bannerView else { return }

        if bannerView.rootViewController == nil {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootVC

                let screenWidth = windowScene.screen.bounds.width
                let viewWidth = uiView.frame.width > 0 ? uiView.frame.width : screenWidth
                bannerView.adSize = largeAnchoredAdaptiveBanner(width: viewWidth)
                bannerView.load(Request())
            }
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding var adHeight: CGFloat
        var bannerView: BannerView?

        init(adHeight: Binding<CGFloat>) {
            _adHeight = adHeight
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            withAnimation(.easeInOut(duration: 0.25)) {
                adHeight = bannerView.adSize.size.height
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            withAnimation(.easeInOut(duration: 0.25)) {
                adHeight = 0
            }
        }
    }
}

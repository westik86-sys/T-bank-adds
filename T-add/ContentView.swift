//
//  ContentView.swift
//  T-add
//
//  Created by Pavel Korostelev on 12.02.2026.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @State private var nextScreenInstanceID = UUID()
    @State private var splashWorkItem: DispatchWorkItem?
    @State private var wasInBackground = false
    private let splashDuration: TimeInterval = 2.0

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                NextScreenView()
                    .id(nextScreenInstanceID)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSplash)
        .statusBar(hidden: !showSplash)
        .onAppear {
            startFlow()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                wasInBackground = true
            } else if newPhase == .active && wasInBackground {
                wasInBackground = false
                startFlow()
            }
        }
    }

    private func startFlow() {
        splashWorkItem?.cancel()
        showSplash = true
        nextScreenInstanceID = UUID()

        let workItem = DispatchWorkItem {
            showSplash = false
        }
        splashWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration, execute: workItem)
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 1.0, green: 221.0 / 255.0, blue: 45.0 / 255.0)

            TShieldSVGView()
                .frame(width: 128, height: 128)
                .frame(width: 192, height: 192)

            VStack(spacing: 0) {
                SplashStatusBar()
                    .padding(.top, 8)
                    .padding(.horizontal, 22)

                Spacer()

                Capsule()
                    .fill(Color.black)
                    .frame(width: 133, height: 5)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

private struct SplashStatusBar: View {
    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: "wifi")
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: "battery.100")
                    .font(.system(size: 17, weight: .regular))
            }
            .foregroundStyle(.black)
        }
        .frame(height: 44)
    }
}

private struct TShieldSVGView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        webView.loadHTMLString(svgHTML, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    private var svgHTML: String {
        """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
          <style>
            html, body {
              margin: 0;
              width: 100%;
              height: 100%;
              background: transparent;
              overflow: hidden;
            }
            svg {
              width: 100%;
              height: 100%;
              display: block;
            }
          </style>
        </head>
        <body>
          <svg preserveAspectRatio="none" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <g id="container">
              <path d="M0 0H24V12.0727C24 15.1658 22.3487 18.0278 19.6706 19.5722L12 24L4.32941 19.5722C1.65134 18.0235 0 15.1658 0 12.0727V0Z" fill="white"/>
              <path fill-rule="evenodd" clip-rule="evenodd" d="M6.58824 6.35294V10.1091C7.10161 9.52727 8.03423 9.13796 9.10375 9.13796H10.2631V13.5016C10.2631 14.661 9.94653 15.6791 9.48022 16.2396H14.5241C14.0578 15.6791 13.7412 14.6652 13.7412 13.5059V9.13796H14.9005C15.9658 9.13796 16.9027 9.53155 17.416 10.1091V6.35294H6.58824Z" fill="#333333"/>
            </g>
          </svg>
        </body>
        </html>
        """
    }
}

private struct NextScreenView: View {
    @State private var showBottomSheet = false
    @State private var showConsultantPopup = false
    @State private var showPromoFullScreen = false
    @State private var shouldShowErrorOnTap = false
    @State private var showErrorAlert = false
    @State private var sheetWorkItem: DispatchWorkItem?
    @State private var popupWorkItem: DispatchWorkItem?
    @State private var promoWorkItem: DispatchWorkItem?
    private let bottomSheetDelay: TimeInterval = 1.6
    private let popupDelayAfterSheetClose: TimeInterval = 1.6
    private let promoDelayAfterPopupClose: TimeInterval = 1.6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Image("NextScreen3531764")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black)

                if showConsultantPopup {
                    ConsultantPopupView {
                        showConsultantPopup = false
                        schedulePromoFullScreenPresentation()
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 96)
                }
            }
            .onAppear {
                resetTransientState()
                scheduleSheetPresentation()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if shouldShowErrorOnTap {
                    showErrorAlert = true
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showBottomSheet, onDismiss: {
            schedulePopupPresentation()
        }) {
            NativeBottomSheetContent()
                .presentationDetents([.height(572)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .fullScreenCover(isPresented: $showPromoFullScreen) {
            PromoFullScreenView {
                showPromoFullScreen = false
                shouldShowErrorOnTap = true
            }
        }
        .alert("Что-то пошло не так", isPresented: $showErrorAlert) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Попробуйте позже")
        }
    }

    private func resetTransientState() {
        sheetWorkItem?.cancel()
        popupWorkItem?.cancel()
        promoWorkItem?.cancel()
        showBottomSheet = false
        showConsultantPopup = false
        showPromoFullScreen = false
        shouldShowErrorOnTap = false
        showErrorAlert = false
    }

    private func scheduleSheetPresentation() {
        let workItem = DispatchWorkItem {
            showBottomSheet = true
        }
        sheetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + bottomSheetDelay, execute: workItem)
    }

    private func schedulePopupPresentation() {
        popupWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            showConsultantPopup = true
        }
        popupWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + popupDelayAfterSheetClose, execute: workItem)
    }

    private func schedulePromoFullScreenPresentation() {
        promoWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            showPromoFullScreen = true
        }
        promoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + promoDelayAfterPopupClose, execute: workItem)
    }
}

private struct NativeBottomSheetContent: View {
    @Environment(\.dismiss) private var dismiss
    private let topImageURL = URL(string: "http://localhost:3845/assets/694ccb92aed6d00d76878b9624fd96efb1b53ed8.png")

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Color(red: 0.839, green: 0.224, blue: 0.224)

                AsyncImage(url: topImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(red: 0.839, green: 0.224, blue: 0.224)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(.white.opacity(0.95), .black.opacity(0.45))
                        .frame(width: 40, height: 40)
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
                .buttonStyle(.plain)
            }
            .frame(height: 290)

            VStack(alignment: .leading, spacing: 0) {
                Text("Много кэшбэка в Шаурме\nу Асланбека")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                Text("Оплачивайте шаву картой Black и лутайте кэшбэк, который можно потратить в аптеке. Предложение ограничено")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)

                Spacer()

                Button(action: {}) {
                    Text("За шавой!")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 1.0, green: 221.0 / 255.0, blue: 45.0 / 255.0))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .dynamicTypeSize(.medium)
    }
}

private struct ConsultantPopupView: View {
    let onClose: () -> Void
    private let avatarURL = URL(string: "http://localhost:3845/assets/6436a6502468afbdba0894b13499cc17f4d4d1ca.png")

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.25))
                    }
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())

                    Text("Ваш консультант")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 61)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.188, green: 0.196, blue: 0.294), Color(red: 0.259, green: 0.282, blue: 0.404)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Добрый день! Напишите\nкакой вопрос вас\nинтересует и я постараюсь\nВам помочь")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.black)
                                .padding(.top, 7)
                                .padding(.leading, 8)

                            HStack {
                                Spacer()
                                Text("16:23")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color(red: 0.573, green: 0.6, blue: 0.635))
                                    .padding(.trailing, 8)
                                    .padding(.bottom, 5)
                            }
                        }
                        .frame(width: 202, height: 99, alignment: .topLeading)
                        .background(Color(red: 0.945, green: 0.941, blue: 0.941))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.top, 19)
                        .padding(.trailing, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer()

                    Rectangle()
                        .fill(Color(red: 0.851, green: 0.851, blue: 0.851).opacity(0.5))
                        .frame(height: 1)

                    HStack {
                        Text("Введите сообщение")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(red: 0.573, green: 0.6, blue: 0.635))
                            .padding(.leading, 12)

                        Spacer()

                        Circle()
                            .fill(Color(red: 0.851, green: 0.851, blue: 0.851))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white)
                            }
                            .padding(.trailing, 12)
                    }
                    .frame(height: 61)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
            .frame(width: 284, height: 346)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 34, x: 0, y: 6)
        }
        .dynamicTypeSize(.medium)
    }
}

private struct PromoFullScreenView: View {
    let onClose: () -> Void
    private let bgImageURL = URL(string: "http://localhost:3845/assets/d3b4c21583bec9d7125c0545ed05fedbe26738bb.png")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: bgImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(red: 0.95, green: 0.95, blue: 0.95)
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.white, Color.white.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.0, green: 0.384, blue: 0.431))
                    .frame(height: 76)
                    .overlay {
                        Text("Акция! До 14 февраля")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 96)
                    .padding(.horizontal, 16)

                (
                    Text("Получите дизайн-\nпроект бани под ваши\nразмеры ")
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.22))
                    +
                    Text("бесплатно")
                        .foregroundStyle(Color(red: 0.0, green: 0.384, blue: 0.431))
                )
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 24)
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("— Отрисуем планировку бани")
                    Text("— Рассчитаем стоимость")
                    Text("— Поможем выбрать стиль")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.top, 20)
                .padding(.horizontal, 16)

                Spacer()

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.965, green: 0.969, blue: 0.973))
                    .frame(height: 56)
                    .overlay(alignment: .leading) {
                        Text("Введите номер телефона")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color(red: 0.573, green: 0.6, blue: 0.635))
                            .padding(.leading, 12)
                    }
                    .padding(.horizontal, 16)

                Button(action: {}) {
                    Text("Получить дизайн-проект")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.612, green: 0.863, blue: 0.184), Color(red: 0.451, green: 0.624, blue: 0.133)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 54)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 40)
            .padding(.trailing, 16)
            .buttonStyle(.plain)
        }
        .dynamicTypeSize(.medium)
    }
}

#Preview {
    ContentView()
}

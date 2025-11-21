//
//  WebView.swift
//  LifeCompanion
//
//  Created by gayeugur on 21.11.2025.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

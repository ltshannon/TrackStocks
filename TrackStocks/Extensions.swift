//
//  Extensions.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/27/24.
//

import Foundation
import SwiftUI

public extension String {
    //Common
    static var empty: String { "" }
    static var space: String { " " }
    static var comma: String { "," }
    static var newline: String { "\n" }
    
    //Debug
    static var success: String { "🎉" }
    static var test: String { "🧪" }
    static var notice: String { "⚠️" }
    static var warning: String { "🚧" }
    static var fatal: String { "☢️" }
    static var reentry: String { "⛔️" }
    static var stop: String { "🛑" }
    static var boom: String { "💥" }
    static var sync: String { "🚦" }
    static var key: String { "🗝" }
    static var bell: String { "🔔" }
    
    var isNotEmpty: Bool {
        !isEmpty
    }
}

extension UIColor {
    static var accentColor: UIColor {
        UIColor(named: "AccentColor") ?? .blue
    }
}

extension Font {
    static let buttonText: Font = Font.system(size: 19, weight: .regular).leading(.loose)
}

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.dropFirst().reduce(String(prefix(1))) {
            return CharacterSet.uppercaseLetters.contains($1)
                ? $0 + " " + String($1)
                : $0 + String($1)
        }
    }
}

struct NavigationStyleLayer: UIViewControllerRepresentable {
    @MainActor
    final class ViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            if let navigationController = parent?.navigationController as? UINavigationController {
            navigationController.navigationBar.standardAppearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 30.0)]
            }
        }
    }

    func makeUIViewController(context: Context) -> ViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {

    }
}

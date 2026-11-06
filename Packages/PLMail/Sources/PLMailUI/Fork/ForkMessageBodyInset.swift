#if os(iOS)

// FORK (FORK.md 2): the message body edge to edge on a phone.

import SwiftUI

/// On a phone the body runs to the screen's edges, as in Apple Mail: every
/// point of a 390-pt screen is worth more to a 600-px newsletter than a margin
/// is. On iPad (regular width) the original's inset, rounded sheet stays,
/// because there the body sits inside a pane card whose corners it would
/// otherwise square off.
struct ForkMessageBodyInset: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .clipShape(.rect(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 12)
        } else {
            content
        }
    }
}

#endif

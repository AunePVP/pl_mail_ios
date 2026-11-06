#if os(iOS)

// FORK (FORK.md 2): shrink wide mail to the screen, as Apple Mail does.

extension MessageBodyView {
    /// Scales a message laid out wider than the screen down to fit it.
    ///
    /// Newsletters are built as fixed 600–700 px tables. The wrapper's
    /// `table { display: block; overflow-x: auto }` was meant to let such a
    /// table scroll on its own, but with the web view's scrolling disabled and
    /// tables nested inside tables, the right-hand side was simply cut off.
    ///
    /// So: lay the tables out naturally, measure, and if the page is wider than
    /// the viewport, zoom the body down by the ratio — the text stays text
    /// (pinch-free, selectable), it just gets smaller, which is what every
    /// other mail client on the platform does. A message that already fits
    /// keeps the wrapper's original rules untouched.
    ///
    /// Run at document end and again on `load`, because images without
    /// declared sizes only widen the layout once they arrive. `zoom` changes
    /// layout, so `scrollHeight` — and with it the height the view reports —
    /// shrinks along with it.
    static let fitWidthScript = """
        (function () {
          var natural = document.createElement('style');
          natural.textContent =
            'table { display: table !important; overflow: visible !important; }';
          function fit() {
            var body = document.body;
            if (!body) { return; }
            body.style.zoom = '';
            document.head.appendChild(natural);
            var viewport = document.documentElement.clientWidth || window.innerWidth;
            var content = Math.max(
              document.documentElement.scrollWidth, body.scrollWidth);
            if (viewport > 0 && content > viewport + 1) {
              body.style.zoom = String(viewport / content);
            } else if (natural.parentNode) {
              natural.parentNode.removeChild(natural);
            }
          }
          fit();
          window.addEventListener('load', fit);
        })();
        """
}

#endif

#if os(iOS)

// FORK (FORK.md 2): wide mail fills the screen and shrinks to it, as in Apple Mail.

extension MessageBodyView {
    /// Lays a designed message out edge to edge and scales it down to fit.
    ///
    /// Newsletters are built as fixed 600–700 px tables. The wrapper's
    /// `table { display: block; overflow-x: auto }` was meant to let such a
    /// table scroll on its own, but with the web view's scrolling disabled and
    /// tables nested inside tables, the right-hand side was simply cut off.
    ///
    /// So: lay the tables out naturally and measure. A message with a table at
    /// least as wide as the screen (minus the wrapper's margins) is a designed
    /// layout: it loses the wrapper's 16 px side padding, as its own design
    /// brings margins, and if it is still wider than the viewport the body is
    /// zoomed down by the ratio — text stays text, selectable, just smaller.
    /// A plain message keeps the padding and the wrapper's rules untouched.
    ///
    /// Run at document end and again on `load`, because images without
    /// declared sizes only widen the layout once they arrive. `zoom` changes
    /// layout, so `scrollHeight` — and with it the height the view reports —
    /// shrinks along with it.
    static let fitWidthScript = """
        (function () {
          var natural = document.createElement('style');
          natural.textContent =
            'table { display: table !important; overflow: visible !important;' +
            ' max-width: none !important; }';
          function widestTable() {
            var widest = 0;
            var tables = document.getElementsByTagName('table');
            for (var i = 0; i < tables.length; i++) {
              widest = Math.max(widest, tables[i].scrollWidth, tables[i].offsetWidth);
            }
            return widest;
          }
          function fit() {
            var body = document.body;
            if (!body) { return; }
            body.style.zoom = '';
            body.style.paddingLeft = '';
            body.style.paddingRight = '';
            document.head.appendChild(natural);
            var viewport = document.documentElement.clientWidth || window.innerWidth;
            if (viewport <= 0) { return; }
            var designed = widestTable() >= viewport - 32;
            if (!designed) {
              if (natural.parentNode) { natural.parentNode.removeChild(natural); }
              return;
            }
            body.style.paddingLeft = '0';
            body.style.paddingRight = '0';
            var content = Math.max(
              document.documentElement.scrollWidth, body.scrollWidth);
            if (content > viewport + 1) {
              body.style.zoom = String(viewport / content);
            }
          }
          fit();
          window.addEventListener('load', fit);
        })();
        """
}

#endif

// FFI for linked-brushing demo

const SVG_NS = "http://www.w3.org/2000/svg";

// createCircle :: Element -> Number -> Number -> Number -> String -> datum -> Effect Unit
export function createCircle_(svg) {
  return function (cx) {
    return function (cy) {
      return function (r) {
        return function (fill) {
          return function (datum) {
            return function () {
              const c = document.createElementNS(SVG_NS, "circle");
              c.setAttribute("cx", cx);
              c.setAttribute("cy", cy);
              c.setAttribute("r", r);
              c.setAttribute("fill", fill);
              c.setAttribute("class", "point");
              c.__data__ = datum;
              svg.appendChild(c);
              return c;
            };
          };
        };
      };
    };
  };
}

// attachBrush :: Element -> (BoundingBox -> Effect Unit) -> (Effect Unit) -> Effect Unit
export function attachBrush_(svg) {
  return function (onBrush) {
    return function (onClear) {
      return function () {
        var rect = document.createElementNS(SVG_NS, "rect");
        rect.setAttribute("class", "brush-rect");
        rect.setAttribute("display", "none");
        svg.appendChild(rect);

        var start = null;
        var dragging = false;

        function toSvg(e) {
          var pt = svg.createSVGPoint();
          pt.x = e.clientX;
          pt.y = e.clientY;
          var ctm = svg.getScreenCTM();
          return ctm ? pt.matrixTransform(ctm.inverse()) : pt;
        }

        function clamp(v, lo, hi) {
          return Math.max(lo, Math.min(hi, v));
        }

        var W = parseFloat(svg.getAttribute("width"));
        var H = parseFloat(svg.getAttribute("height"));

        svg.addEventListener("pointerdown", function (e) {
          if (e.button !== 0) return;
          dragging = true;
          svg.setPointerCapture(e.pointerId);
          e.preventDefault();
          start = toSvg(e);
          start.x = clamp(start.x, 0, W);
          start.y = clamp(start.y, 0, H);
          rect.setAttribute("x", start.x);
          rect.setAttribute("y", start.y);
          rect.setAttribute("width", 0);
          rect.setAttribute("height", 0);
          rect.setAttribute("display", "block");
        });

        svg.addEventListener("pointermove", function (e) {
          if (!dragging) return;
          var cur = toSvg(e);
          cur.x = clamp(cur.x, 0, W);
          cur.y = clamp(cur.y, 0, H);
          var x0 = Math.min(start.x, cur.x);
          var y0 = Math.min(start.y, cur.y);
          var x1 = Math.max(start.x, cur.x);
          var y1 = Math.max(start.y, cur.y);
          rect.setAttribute("x", x0);
          rect.setAttribute("y", y0);
          rect.setAttribute("width", x1 - x0);
          rect.setAttribute("height", y1 - y0);
          onBrush({ x0: x0, y0: y0, x1: x1, y1: y1 })();
        });

        svg.addEventListener("pointerup", function (e) {
          if (!dragging) return;
          dragging = false;
          svg.releasePointerCapture(e.pointerId);
          var w = parseFloat(rect.getAttribute("width"));
          var h = parseFloat(rect.getAttribute("height"));
          if (w < 5 && h < 5) {
            rect.setAttribute("display", "none");
            onClear();
          }
        });
      };
    };
  };
}

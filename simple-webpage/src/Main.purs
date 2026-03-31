-- | Simple Webpage — minimum viable HATS visualization
module Main where

import Prelude
import Effect (Effect)
import Hylograph.HATS (Tree, elem, forEach, staticStr)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Element.Types (ElementType(..))

type Bar = { label :: String, h :: Number, x :: Number, color :: String }

bars :: Array Bar
bars =
  [ { label: "A", h: 90.0, x:  20.0, color: "#4e79a7" }
  , { label: "B", h: 60.0, x:  75.0, color: "#f28e2b" }
  , { label: "C", h: 75.0, x: 130.0, color: "#e15759" }
  , { label: "D", h: 40.0, x: 185.0, color: "#76b7b2" }
  , { label: "E", h: 55.0, x: 240.0, color: "#59a14f" }
  ]

chart :: Tree
chart =
  elem SVG [ F.viewBox 0.0 0.0 300.0 130.0, F.style "max-width: 400px;" ]
    [ forEach "bars" Group bars _.label \d ->
        elem Group []
          [ elem Rect
              [ F.x d.x, F.y (100.0 - d.h), F.width 40.0, F.height d.h
              , F.fill d.color
              ] []
          , elem Text
              [ F.x (d.x + 20.0), F.y 120.0
              , F.textAnchor "middle", F.fontSize "12px", F.fill "#333"
              , staticStr "textContent" d.label
              ] []
          ]
    ]

main :: Effect Unit
main = do
  _ <- rerender "#app" chart
  pure unit

-- | Coordinated Highlighting — Minimal How-To
-- |
-- | Hover a circle in the left panel and the matching bar in
-- | the right panel highlights (and vice versa).
module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)

import Hylograph.HATS
  ( Tree, elem, forEach, withBehaviors, onCoordinatedHighlight, staticStr )
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Behavior.Types (HighlightClass(..))
import Hylograph.Internal.Element.Types (ElementType(..))

-- | Sample data: five items with a name, color, value, and y-position.
type Item = { name :: String, color :: String, value :: Number, y :: Number }

items :: Array Item
items =
  [ { name: "Alpha",   color: "#4e79a7", value: 80.0, y:  20.0 }
  , { name: "Beta",    color: "#f28e2b", value: 55.0, y:  68.0 }
  , { name: "Gamma",   color: "#e15759", value: 40.0, y: 116.0 }
  , { name: "Delta",   color: "#76b7b2", value: 70.0, y: 164.0 }
  , { name: "Epsilon", color: "#59a14f", value: 30.0, y: 212.0 }
  ]

-- | Classify helper shared by both views:
-- | Primary when this element's name matches the hovered id, Neutral otherwise.
classify :: String -> String -> HighlightClass
classify myName hoveredId =
  if myName == hoveredId then Primary else Neutral

-- | Left panel: five colored circles.
circlesView :: Tree
circlesView =
  elem SVG [ F.viewBox 0.0 0.0 100.0 240.0, F.width 120.0 ]
    [ forEach "dots" Circle items _.name \d ->
        withBehaviors
          [ onCoordinatedHighlight
              { identify: d.name
              , classify: classify d.name
              , group: Nothing
              }
          ] $
          elem Circle
            [ F.cx 50.0, F.cy d.y, F.r 18.0
            , F.fill d.color, F.stroke "#fff", F.strokeWidth 2.0
            ] []
    ]

-- | Right panel: five horizontal bars.
barsView :: Tree
barsView =
  elem SVG [ F.viewBox 0.0 0.0 220.0 240.0, F.width 260.0 ]
    [ forEach "bars" Rect items _.name \d ->
        withBehaviors
          [ onCoordinatedHighlight
              { identify: d.name
              , classify: classify d.name
              , group: Nothing
              }
          ] $
          elem Rect
            [ F.x 0.0, F.y (d.y - 16.0), F.width (d.value * 2.2), F.height 32.0
            , F.fill d.color, staticStr "rx" "4"
            ] []
    ]

main :: Effect Unit
main = do
  _ <- rerender "#circles" circlesView
  _ <- rerender "#bars"    barsView
  pure unit

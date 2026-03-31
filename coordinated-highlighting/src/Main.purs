-- | Coordinated Highlighting — hover a category in the key and all
-- | matching circles in the scatter plot highlight.
module Main where

import Prelude

import Data.Array (mapWithIndex)
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Effect (Effect)

import Hylograph.HATS (Tree, elem, forEach, staticStr, withBehaviors, onCoordinatedHighlight)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Behavior.Types (HighlightClass(..))
import Hylograph.Internal.Element.Types (ElementType(..))

-- Categories for the key
type Category = { name :: String, color :: String, idx :: Int }

categories :: Array Category
categories =
  [ { name: "Igneous",     color: "#e15759", idx: 0 }
  , { name: "Sedimentary", color: "#4e79a7", idx: 1 }
  , { name: "Metamorphic", color: "#59a14f", idx: 2 }
  , { name: "Volcanic",    color: "#f28e2b", idx: 3 }
  ]

-- Scattered circles, each belonging to a category
type Dot = { x :: Number, y :: Number, r :: Number, category :: String, color :: String, id :: String }

dots :: Array Dot
dots =
  [ { x: 45.0,  y: 35.0,  r: 10.0, category: "Igneous",     color: "#e15759", id: "d1" }
  , { x: 160.0, y: 55.0,  r: 14.0, category: "Sedimentary", color: "#4e79a7", id: "d2" }
  , { x: 90.0,  y: 120.0, r: 8.0,  category: "Metamorphic", color: "#59a14f", id: "d3" }
  , { x: 210.0, y: 40.0,  r: 11.0, category: "Igneous",     color: "#e15759", id: "d4" }
  , { x: 130.0, y: 160.0, r: 13.0, category: "Volcanic",    color: "#f28e2b", id: "d5" }
  , { x: 55.0,  y: 190.0, r: 9.0,  category: "Sedimentary", color: "#4e79a7", id: "d6" }
  , { x: 240.0, y: 130.0, r: 12.0, category: "Metamorphic", color: "#59a14f", id: "d7" }
  , { x: 180.0, y: 200.0, r: 10.0, category: "Igneous",     color: "#e15759", id: "d8" }
  , { x: 30.0,  y: 100.0, r: 15.0, category: "Volcanic",    color: "#f28e2b", id: "d9" }
  , { x: 270.0, y: 80.0,  r: 7.0,  category: "Sedimentary", color: "#4e79a7", id: "d10" }
  , { x: 200.0, y: 170.0, r: 11.0, category: "Volcanic",    color: "#f28e2b", id: "d11" }
  , { x: 100.0, y: 60.0,  r: 9.0,  category: "Metamorphic", color: "#59a14f", id: "d12" }
  , { x: 150.0, y: 100.0, r: 16.0, category: "Igneous",     color: "#e15759", id: "d13" }
  , { x: 260.0, y: 190.0, r: 8.0,  category: "Sedimentary", color: "#4e79a7", id: "d14" }
  , { x: 70.0,  y: 155.0, r: 12.0, category: "Volcanic",    color: "#f28e2b", id: "d15" }
  ]

-- | The key: labeled color swatches
keyView :: Tree
keyView =
  let swatchH = 28.0
      gap = 8.0
  in
    elem SVG [ F.viewBox 0.0 0.0 140.0 160.0, F.width 140.0, F.height 160.0 ]
      [ forEach "key" Group categories _.name \cat ->
          let y = 10.0 + Int.toNumber cat.idx * (swatchH + gap)
          in withBehaviors
              [ onCoordinatedHighlight
                  { identify: cat.name
                  , classify: \hovered -> if hovered == cat.name then Primary else Dimmed
                  , group: Nothing
                  }
              ] $
              elem Group [ F.transform ("translate(0," <> show y <> ")") ]
                [ elem Rect
                    [ F.x 0.0, F.y 0.0, F.width 20.0, F.height swatchH
                    , staticStr "rx" "3"
                    , F.fill cat.color
                    ] []
                , elem Text
                    [ F.x 28.0, F.y (swatchH / 2.0 + 5.0)
                    , F.fontSize "13"
                    , F.fontFamily "system-ui, sans-serif"
                    , F.fill "#333"
                    , staticStr "textContent" cat.name
                    ] []
                ]
      ]

-- | The scatter: circles colored by category
scatterView :: Tree
scatterView =
  elem SVG [ F.viewBox 0.0 0.0 300.0 230.0, F.width 300.0, F.height 230.0 ]
    [ forEach "scatter" Group dots _.id \d ->
        withBehaviors
          [ onCoordinatedHighlight
              { identify: d.category  -- identifies as category, not individual dot
              , classify: \hovered -> if hovered == d.category then Primary else Dimmed
              , group: Nothing
              }
          ] $
          elem Group []
            [ elem Circle
                [ F.cx d.x, F.cy d.y, F.r d.r
                , F.fill d.color
                , F.opacity "0.85"
                ] []
            ]
    ]

main :: Effect Unit
main = do
  _ <- rerender "#key" keyView
  _ <- rerender "#scatter" scatterView
  pure unit

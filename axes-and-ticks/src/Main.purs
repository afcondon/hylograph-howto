-- | Axes and Ticks — Scatter plot with X and Y axes using pure scales
module Main where

import Prelude
import Effect (Effect)
import Hylograph.Scale.Pure as Scale
import Hylograph.HATS (Tree, elem, forEach, staticStr)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Element.Types (ElementType(..))

type Point = { x :: Number, y :: Number, label :: String }

points :: Array Point
points =
  [ { x: 10.0, y: 28.0, label: "A" }, { x: 25.0, y: 62.0, label: "B" }
  , { x: 38.0, y: 45.0, label: "C" }, { x: 52.0, y: 80.0, label: "D" }
  , { x: 60.0, y: 35.0, label: "E" }, { x: 72.0, y: 90.0, label: "F" }
  , { x: 85.0, y: 55.0, label: "G" }, { x: 95.0, y: 72.0, label: "H" }
  , { x: 42.0, y: 18.0, label: "I" }, { x: 68.0, y: 68.0, label: "J" }
  ]

chart :: Tree
chart =
  let
    ml = 50.0
    mt = 10.0
    pw = 440.0
    ph = 300.0
    w = ml + pw + 10.0
    h = mt + ph + 40.0
    xS = Scale.linear # Scale.domain [0.0, 100.0] # Scale.range [ml, ml + pw]
    yS = Scale.linear # Scale.domain [0.0, 100.0] # Scale.range [mt + ph, mt]
    xT = Scale.ticks 5 xS
    yT = Scale.ticks 5 yS
    bY = mt + ph
  in
  elem SVG
    [ F.viewBox 0.0 0.0 w h, F.width w
    , F.style "max-width: 520px; font-family: system-ui, sans-serif;"
    ]
    [ forEach "pts" Circle points _.label \pt ->
        elem Circle
          [ F.cx (Scale.applyScale xS pt.x), F.cy (Scale.applyScale yS pt.y)
          , F.r 4.0, F.fill "#2563eb", F.fillOpacity "0.7"
          ] []

    , elem Line
        [ F.x1 ml, F.y1 bY, F.x2 (ml + pw), F.y2 bY
        , F.stroke "#333", F.strokeWidth 1.0
        ] []
    , forEach "xTicks" Group xT show \tv ->
        let px = Scale.applyScale xS tv in
        elem Group []
          [ elem Line
              [ F.x1 px, F.y1 bY, F.x2 px, F.y2 (bY + 6.0)
              , F.stroke "#333", F.strokeWidth 1.0
              ] []
          , elem Text
              [ F.x px, F.y (bY + 20.0), F.textAnchor "middle"
              , F.fontSize "11", F.fill "#555"
              , staticStr "textContent" (show tv)
              ] []
          ]

    , elem Line
        [ F.x1 ml, F.y1 mt, F.x2 ml, F.y2 (mt + ph)
        , F.stroke "#333", F.strokeWidth 1.0
        ] []
    , forEach "yTicks" Group yT show \tv ->
        let py = Scale.applyScale yS tv in
        elem Group []
          [ elem Line
              [ F.x1 (ml - 6.0), F.y1 py, F.x2 ml, F.y2 py
              , F.stroke "#333", F.strokeWidth 1.0
              ] []
          , elem Text
              [ F.x (ml - 10.0), F.y (py + 4.0), F.textAnchor "end"
              , F.fontSize "11", F.fill "#555"
              , staticStr "textContent" (show tv)
              ] []
          ]
    ]

main :: Effect Unit
main = do
  _ <- rerender "#app" chart
  pure unit

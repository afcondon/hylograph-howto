-- | CSS Hover — pure CSS :hover on HATS elements, no JavaScript needed
module Main where

import Prelude

import Effect (Effect)
import Hylograph.HATS (Tree, elem, forEach, staticStr)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Element.Types (ElementType(..))

type Dot = { color :: String, cx :: Number }

dots :: Array Dot
dots =
  [ { color: "#e15759", cx: 40.0 }
  , { color: "#f28e2b", cx: 104.0 }
  , { color: "#edc948", cx: 168.0 }
  , { color: "#59a14f", cx: 232.0 }
  , { color: "#4e79a7", cx: 296.0 }
  , { color: "#b07aa1", cx: 360.0 }
  ]

circles :: Tree
circles =
  elem SVG
    [ F.viewBox 0.0 0.0 400.0 100.0
    , F.style "max-width: 500px;"
    ]
    [ forEach "dots" Circle dots _.color \d ->
        elem Circle
          [ F.cx d.cx
          , F.cy 50.0
          , F.r 24.0
          , F.fill d.color
          , staticStr "class" "hoverable"
          ] []
    ]

main :: Effect Unit
main = do
  _ <- rerender "#app" circles
  pure unit

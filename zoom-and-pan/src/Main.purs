-- | Zoom and Pan — Minimal HATS demo
-- |
-- | Renders a 10x10 grid of circles, then attaches native zoom/pan behavior.
-- | The zoom applies to a <g class="zoom-group"> wrapping all content.
module Main where

import Prelude

import Data.Array ((..))
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Hylograph.HATS (Tree, elem, staticStr, staticNum, forEach)
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Interaction.Zoom (attachZoomNative)
import Hylograph.Internal.Element.Types (ElementType(..))
import Web.DOM.ParentNode (querySelector, QuerySelector(..))
import Web.HTML (window)
import Web.HTML.Window (document)
import Web.HTML.HTMLDocument (toParentNode)

-- | Grid datum: row and column index
type Dot = { row :: Int, col :: Int }

-- | Generate a 10x10 grid of dots
dots :: Array Dot
dots = do
  row <- 0 .. 9
  col <- 0 .. 9
  pure { row, col }

-- | Build the HATS tree: an SVG containing a zoom-group with circles
circleGrid :: Tree
circleGrid =
  elem SVG
    [ staticStr "viewBox" "0 0 500 500"
    , staticStr "width" "500"
    , staticStr "height" "500"
    , staticStr "style" "background: #fff;"
    ]
    -- Wrap all content in a <g class="zoom-group"> so zoom can target it
    [ elem Group [ staticStr "class" "zoom-group" ]
        [ forEach "dots" Circle dots
            (\d -> show d.row <> "," <> show d.col)
            \d ->
              elem Circle
                [ staticNum "cx" (toNumber d.col * 45.0 + 50.0)
                , staticNum "cy" (toNumber d.row * 45.0 + 50.0)
                , staticNum "r" 12.0
                , staticStr "fill" "#4e79a7"
                , staticStr "opacity" "0.7"
                ] []
        ]
    ]

main :: Effect Unit
main = do
  -- 1. Render the circle grid into #app
  _ <- rerender "#app" circleGrid

  -- 2. Find the SVG element we just created
  doc <- window >>= document
  mSvg <- querySelector (QuerySelector "#app svg") (toParentNode doc)

  -- 3. Attach zoom: scale 0.1x to 10x, targeting the .zoom-group <g>
  case mSvg of
    Just svg -> do
      _ <- attachZoomNative svg 0.1 10.0 ".zoom-group"
      pure unit
    Nothing ->
      pure unit

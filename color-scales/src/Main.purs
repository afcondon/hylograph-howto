-- | Color Scales — Linear scales, color interpolators, and tick marks
-- | Demonstrates Hylograph's pure scale system without D3.
module Main where

import Prelude
import Data.Array (range)
import Data.Int (toNumber)
import Effect (Effect)
import Hylograph.Scale.Pure as Scale
import Hylograph.Scale.Sequential (interpolateViridis, interpolateRdYlGn)
import Hylograph.HATS (Tree, elem, forEach, staticStr)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Element.Types (ElementType(..))

-- | Build an SVG with two color gradient bars and tick marks
colorScales :: Number -> Tree
colorScales w =
  let
    n      = 100 -- color samples per bar
    indices = range 0 (n - 1) <#> \i ->
                { idx: i, t: toNumber i / toNumber (n - 1) }
    xScale  = Scale.linear # Scale.domain [0.0, toNumber (n - 1)] # Scale.range [0.0, w]
    nScale  = Scale.linear # Scale.domain [0.0, 1.0] # Scale.range [0.0, w]
    ticks   = Scale.ticks 10 nScale
    barH = 32.0
    stripW = w / toNumber n + 1.0
    y1 = 10.0                  -- first bar top
    yT = y1 + barH + 8.0      -- tick area
    y2 = yT + 40.0             -- second bar top

    -- Helper: one horizontal gradient bar via thin rects
    gradientBar name yPos interp =
      forEach name Rect indices (show <<< _.idx) \s ->
        elem Rect
          [ F.x (Scale.applyScale xScale (toNumber s.idx)), F.y yPos
          , F.width stripW, F.height barH
          , F.fill (interp s.t)
          ] []
  in
  elem SVG
    [ F.viewBox 0.0 0.0 (w + 20.0) (y2 + barH + 10.0)
    , F.width (w + 20.0)
    , F.style "max-width: 640px; font-family: system-ui, sans-serif;"
    ]
    [ gradientBar "viridis" y1 interpolateViridis

    , forEach "ticks" Group ticks show \tv ->
        let px = Scale.applyScale nScale tv in
        elem Group []
          [ elem Line
              [ F.x1 px, F.y1 yT, F.x2 px, F.y2 (yT + 8.0)
              , F.stroke "#333", F.strokeWidth 1.0
              ] []
          , elem Text
              [ F.x px, F.y (yT + 20.0), F.textAnchor "middle"
              , F.fontSize "11", F.fill "#555"
              , staticStr "textContent" (show tv)
              ] []
          ]

    , gradientBar "rdylgn" y2 interpolateRdYlGn
    ]

main :: Effect Unit
main = do

  _ <- rerender "#app" (colorScales 500.0)
  pure unit

-- | Linked Brushing — drag to brush-select in one scatter plot,
-- | matching points highlight in a second scatter plot.
-- |
-- | Uses the low-level Coordinated API (registerCoordinated / emitTrigger).
module Main where

import Prelude

import Data.Array ((..))
import Data.Foldable (for_)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Hylograph.Interaction.Coordinated
  ( BoundingBox, InteractionState(..), InteractionTrigger(..)
  , mkBrushTrigger, mkClearTrigger, pointInBox
  , registerCoordinated, emitTrigger )
import Web.DOM.Element (Element)
import Web.DOM.ParentNode (querySelector, QuerySelector(..))
import Web.HTML (window)
import Web.HTML.HTMLDocument (toParentNode)
import Web.HTML.Window (document)

-- | Datum shared by both views. Brush hit-testing uses x/y.
type Datum = { id :: String, x :: Number, y :: Number, z :: Number, color :: String }

group :: Maybe String
group = Just "linked"

-- | Deterministic "random" based on index — avoids needing random Effect.
pseudoRandom :: Int -> Number
pseudoRandom i =
  let n = (i * 1103515245 + 12345) `mod` 2147483647
  in toNumber (n `mod` 1000) / 1000.0

-- | 60 data points with three color groups.
sampleData :: Array Datum
sampleData =
  let pick i = case i `mod` 3 of
        0 -> "#e15759"
        1 -> "#4e79a7"
        _ -> "#59a14f"
  in (0 .. 59) <#> \i ->
    { id: "p" <> show i
    , x: 30.0 + pseudoRandom (i * 3) * 300.0
    , y: 30.0 + pseudoRandom (i * 3 + 1) * 220.0
    , z: 30.0 + pseudoRandom (i * 3 + 2) * 220.0
    , color: pick i
    }

-- | How every element responds to interaction triggers.
respond :: InteractionTrigger -> Datum -> InteractionState
respond = case _ of
  BrushTrigger box -> \d ->
    if pointInBox { x: d.x, y: d.y } box then Selected else Dimmed
  HoverTrigger hid -> \d ->
    if d.id == hid then Primary else Dimmed
  _ -> const Neutral

-- FFI: create an SVG <circle> with __data__ attached, return the Element.
foreign import createCircle_
  :: Element -> Number -> Number -> Number -> String -> Datum -> Effect Element

-- FFI: attach pointer-events brush to an SVG.
foreign import attachBrush_
  :: Element -> (BoundingBox -> Effect Unit) -> Effect Unit -> Effect Unit

-- | Add a circle to an SVG and register it for coordinated interaction.
addPoint :: Element -> Number -> Number -> Datum -> Effect Unit
addPoint svg cx cy d = do
  el <- createCircle_ svg cx cy 5.0 d.color d
  _ <- registerCoordinated el
    { identify: _.id
    , respond: respond
    , group: group
    , position: Just (\datum -> { x: datum.x, y: datum.y })
    }
  pure unit

-- | Query for an SVG element or do nothing.
withSvg :: String -> (Element -> Effect Unit) -> Effect Unit
withSvg sel f = do
  doc <- window >>= document
  mEl <- querySelector (QuerySelector sel) (toParentNode doc)
  maybe (pure unit) f mEl

main :: Effect Unit
main = do
  -- Populate View 1 (x vs y) and View 2 (x vs z)
  withSvg "#view1" \svg1 -> do
    for_ sampleData \d -> addPoint svg1 d.x d.y d
    attachBrush_ svg1
      (\box -> emitTrigger group (mkBrushTrigger box))
      (emitTrigger group mkClearTrigger)

  withSvg "#view2" \svg2 ->
    for_ sampleData \d -> addPoint svg2 d.x d.z d

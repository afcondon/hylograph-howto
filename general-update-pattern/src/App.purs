-- | General Update Pattern — Mike Bostock's classic alphabet demo
-- |
-- | Letters fall in from the top (enter), slide to new positions (update),
-- | and drop out the bottom (exit). Ported from the Hylograph interactive tour.
module App where

import Prelude

import Data.Array (mapWithIndex)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Array as Array
import Data.String.CodeUnits as SCU
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hylograph.HATS (Tree, elem, forEachWithGUP, staticNum, staticStr)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.HATS.Transitions (tickTransitions, TransitionResult(..))
import Hylograph.Internal.Element.Types (ElementType(..))
import Hylograph.Internal.Transition.Types (transitionWith, Easing(BounceOut, CubicInOut, CubicIn))

foreign import raf_ :: Effect Unit -> Effect Unit

-- =============================================================================
-- Data — random subsets of the alphabet
-- =============================================================================

type Letter = { letter :: String, index :: Int }

toLetters :: String -> Array Letter
toLetters s = mapWithIndex (\i c -> { letter: SCU.singleton c, index: i }) (SCU.toCharArray s)

-- Pre-computed datasets — each shares some letters with the others
strings :: Array String
strings = [ "abcdef", "bdfhj", "acegik", "cfi", "abcdefghij", "dgjm", "behk" ]

-- =============================================================================
-- HATS tree — letters with enter/update/exit
-- =============================================================================

letterChart :: Array Letter -> Tree
letterChart letters =
  let spacing = 45.0
      startX = 40.0
      centerY = 150.0
  in
    elem SVG
      [ F.viewBox 0.0 0.0 500.0 300.0, F.width 500.0, F.height 300.0 ]
      [ forEachWithGUP "letters" Text letters _.letter
          (\d -> elem Text
            [ F.x (startX + toNumber d.index * spacing)
            , F.y centerY
            , F.fontSize "36"
            , F.textAnchor "middle"
            , staticStr "dominant-baseline" "middle"
            , F.fill "#2c3e50"
            , F.opacity "1"
            , staticStr "textContent" d.letter
            ] [])
          { enter: Just
              { attrs:
                  [ staticNum "y" 30.0              -- fall in from top
                  , staticNum "opacity" 0.0
                  , staticStr "fill" "#27ae60"       -- green
                  ]
              , transition: Just $ transitionWith
                  { duration: Milliseconds 1800.0, delay: Nothing
                  , staggerDelay: Just 50.0, easing: Just BounceOut }
              }
          , update: Just
              { attrs:
                  [ staticNum "y" centerY
                  , staticStr "fill" "#2c3e50"       -- dark
                  , staticNum "opacity" 1.0
                  ]
              , transition: Just $ transitionWith
                  { duration: Milliseconds 1200.0, delay: Nothing
                  , staggerDelay: Just 30.0, easing: Just CubicInOut }
              }
          , exit: Just
              { attrs:
                  [ staticNum "y" 270.0              -- drop out the bottom
                  , staticNum "opacity" 0.0
                  , staticStr "fill" "#e74c3c"       -- red
                  ]
              , transition: Just $ transitionWith
                  { duration: Milliseconds 1200.0, delay: Nothing
                  , staggerDelay: Just 30.0, easing: Just CubicIn }
              }
          }
      ]

-- =============================================================================
-- Animation loop
-- =============================================================================

renderWithTransitions :: Array Letter -> Effect Unit
renderWithTransitions letters = do
  result <- rerender "#viz" (letterChart letters)
  case result.transitions of
    Nothing -> pure unit
    Just ts -> animLoop ts

animLoop :: _ -> Effect Unit
animLoop ts = raf_ do
  result <- tickTransitions 16.0 ts
  case result of
    Running ts' -> animLoop ts'
    Complete -> pure unit

-- =============================================================================
-- Component
-- =============================================================================

type State = { idx :: Int }
data Action = Init | Shuffle

component :: forall q i o m. MonadAff m => H.Component q i o m
component = H.mkComponent
  { initialState: \_ -> { idx: 0 }
  , render: \_ -> HH.div_
      [ HH.h1_ [ HH.text "General Update Pattern" ]
      , HH.p_ [ HH.text "Click Shuffle. Letters enter from the top (green), slide to new positions, and exit through the bottom (red)." ]
      , HH.button [ HE.onClick \_ -> Shuffle ] [ HH.text "Refresh" ]
      , HH.div [ HP.id "viz" ] []
      ]
  , eval: H.mkEval H.defaultEval
      { handleAction = case _ of
          Init -> H.liftEffect $ renderWithTransitions (toLetters (fromMaybe "abcdef" (Array.index strings 0)))
          Shuffle -> do
            st <- H.get
            let next = (st.idx + 1) `mod` Array.length strings
            H.modify_ \s -> s { idx = next }
            H.liftEffect $ renderWithTransitions (toLetters (fromMaybe "" (Array.index strings next)))
      , initialize = Just Init
      }
  }

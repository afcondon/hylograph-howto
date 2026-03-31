module App where

import Prelude
import Data.Array (filter, mapWithIndex, take, drop, any)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hylograph.HATS (Tree, forEachWithGUP, elem, staticNum, thunkedNum, thunkedStr)
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.HATS.Transitions (tickTransitions, TransitionResult(..), HATSTransitions)
import Hylograph.Internal.Element.Types (ElementType(..))
import Hylograph.Internal.Transition.Types (transition)

foreign import rafOnce :: (Number -> Effect Unit) -> Effect Unit
foreign import performanceNow :: Effect Number
type Datum = { id :: String, color :: String, x :: Number }
mk :: String -> String -> Datum
mk id color = { id, color, x: 0.0 }

palette :: Array Datum
palette = [ mk "A" "#e63946", mk "B" "#457b9d", mk "C" "#2a9d8f", mk "D" "#e9c46a"
          , mk "E" "#f4a261", mk "F" "#264653", mk "G" "#a8dadc", mk "H" "#6d6875" ]

arrange :: Array Datum -> Array Datum
arrange = mapWithIndex \i d -> d { x = 60.0 + toNumber i * 60.0 }

shuffle :: Array Datum -> Array Datum
shuffle items =
  arrange (drop 2 items <> take 2 (filter (\d -> not (any (\x -> x.id == d.id) items)) palette))

type State = { items :: Array Datum }
data Action = Initialize | Shuffle

component :: forall q i o m. MonadAff m => H.Component q i o m
component = H.mkComponent
  { initialState: \_ -> { items: arrange (take 5 palette) }
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction, initialize = Just Initialize } }

render :: forall m. State -> H.ComponentHTML Action () m
render _ =
  HH.div [ HP.class_ (HH.ClassName "app") ]
    [ HH.h1_ [ HH.text "Enter / Update / Exit" ]
    , HH.p_ [ HH.text "Shuffle to see circles enter, move, and exit." ]
    , HH.button [ HE.onClick \_ -> Shuffle ] [ HH.text "Shuffle" ]
    , HH.div [ HP.id "viz" ] [] ]

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> H.get >>= \s -> H.liftEffect (renderViz s.items)
  Shuffle -> do
    H.modify_ \s -> s { items = shuffle s.items }
    H.get >>= \s -> H.liftEffect (renderViz s.items)

renderViz :: Array Datum -> Effect Unit
renderViz items = do
  result <- rerender "#viz" (circlesTree items)
  case result.transitions of
    Nothing -> pure unit
    Just ts -> animateTransitions ts

animateTransitions :: HATSTransitions -> Effect Unit
animateTransitions ts = do
  t0 <- performanceNow
  rafOnce \t1 -> do
    let delta = t1 - t0
    result <- tickTransitions delta ts
    case result of
      Complete -> pure unit
      Running ts' -> animateTransitions ts'

circlesTree :: Array Datum -> Tree
circlesTree items =
  elem SVG [ staticNum "width" 540.0, staticNum "height" 100.0 ]
    [ forEachWithGUP "circles" Circle items _.id
        (\d -> elem Circle
          [ thunkedNum "cx" d.x, thunkedNum "cy" 50.0
          , staticNum "r" 22.0, thunkedStr "fill" d.color ] [])
        { enter:  Just { attrs: [ staticNum "r" 0.0 ]
                       , transition: Just (transition (Milliseconds 400.0)) }
        , update: Just { attrs: [], transition: Just (transition (Milliseconds 600.0)) }
        , exit:   Just { attrs: [ staticNum "r" 0.0 ]
                       , transition: Just (transition (Milliseconds 400.0)) } } ]

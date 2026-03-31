module App where

import Prelude
import Data.Array (range, zipWith, length)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff (delay)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hylograph.HATS (Tree, forEachWithGUP, elem, staticNum, staticStr, thunkedNum, thunkedStr)
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.HATS.Transitions (HATSTransitions, TransitionResult(..), tickTransitions)
import Hylograph.Internal.Element.Types (ElementType(..))
import Hylograph.Internal.Transition.Types (Easing(..), staggeredTransition, transitionWith)

foreign import randomHeights :: Int -> Effect (Array Int)
type Bar = { idx :: Int, height :: Number }
type State = { bars :: Array Bar, ts :: Maybe HATSTransitions, fib :: Maybe H.ForkId }
data Action = Init | Shuffle | Tick Number
mkBars :: Array Number -> Array Bar
mkBars hs = zipWith (\i h -> { idx: i, height: h }) (range 0 (length hs - 1)) hs

component :: forall q i o m. MonadAff m => H.Component q i o m
component = H.mkComponent
  { initialState: \_ ->
      { bars: mkBars (map (\i -> 30.0 + toNumber i * 16.0) (range 0 11)), ts: Nothing, fib: Nothing }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction, initialize = Just Init } }

render :: forall m. State -> H.ComponentHTML Action () m
render _ = HH.div [ HP.class_ (HH.ClassName "app") ]
  [ HH.h1_ [ HH.text "Staggered Transitions" ]
  , HH.p_ [ HH.text "Bars animate in sequence, creating a wave effect." ]
  , HH.button [ HE.onClick \_ -> Shuffle ] [ HH.text "Shuffle heights" ]
  , HH.div [ HP.id "viz" ] [] ]

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Init -> H.get >>= \st -> doRerender st.bars
  Shuffle -> do
    hs <- H.liftEffect $ randomHeights 12
    let bars = mkBars (map toNumber hs)
    H.modify_ _ { bars = bars }
    doRerender bars
  Tick dt -> H.get >>= \st -> case st.ts of
    Nothing -> pure unit
    Just t -> H.liftEffect (tickTransitions dt t) >>= case _ of
      Complete -> do
        case st.fib of
          Just f -> H.kill f
          Nothing -> pure unit
        H.modify_ _ { ts = Nothing, fib = Nothing }
      Running t' -> H.modify_ _ { ts = Just t' }

doRerender :: forall o m. MonadAff m => Array Bar -> H.HalogenM State Action () o m Unit
doRerender bars = do
  st <- H.get
  case st.fib of
    Just f -> H.kill f
    Nothing -> pure unit
  r <- H.liftEffect $ rerender "#viz" (barChart bars)
  case r.transitions of
    Nothing -> H.modify_ _ { ts = Nothing, fib = Nothing }
    Just t -> do
      H.modify_ _ { ts = Just t }
      f <- H.fork tickLoop
      H.modify_ _ { fib = Just f }
  where
  tickLoop = do
    H.liftAff $ delay (Milliseconds 16.0)
    handleAction (Tick 16.0)
    H.get >>= \st -> case st.ts of
      Just _ -> tickLoop
      Nothing -> pure unit

barChart :: Array Bar -> Tree
barChart bars =
  let bw = 36.0
      gap = 6.0
      maxH = 220.0
      tw = toNumber (length bars) * (bw + gap)
  in elem SVG
    [ staticNum "width" tw, staticNum "height" (maxH + 10.0)
    , staticStr "viewBox" ("0 0 " <> show tw <> " " <> show (maxH + 10.0)) ]
    [ forEachWithGUP "bars" Rect bars (\b -> show b.idx) (\b ->
        elem Rect
          [ thunkedNum "x" (toNumber b.idx * (bw + gap)), thunkedNum "y" (maxH - b.height)
          , thunkedNum "width" bw, thunkedNum "height" b.height
          , thunkedStr "fill" "#2563eb", thunkedNum "rx" 3.0 ] [])
      { enter: Just { attrs: [], transition: Just $ transitionWith
          { duration: Milliseconds 600.0, delay: Nothing, staggerDelay: Just 80.0, easing: Just CubicOut } }
      , update: Just { attrs: [], transition: Just $ staggeredTransition (Milliseconds 500.0) 60.0 }
      , exit: Just { attrs: [], transition: Just $ staggeredTransition (Milliseconds 400.0) 40.0 } } ]

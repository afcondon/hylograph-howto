-- | Halogen + HATS integration demo
-- |
-- | State lives in Halogen, visualization lives in HATS.
-- | They communicate through rerender.
module App where

import Prelude

import Data.Array (range)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hylograph.HATS (Tree, forEach, elem, staticStr, staticNum, thunkedNum, thunkedStr)
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Element.Types (ElementType(..))

-- FFI
foreign import clearElement :: String -> Effect Unit

-- Types
type State = { count :: Int }

data Action = Initialize | Increment | Decrement

-- Component
component :: forall q i o m. MonadAff m => H.Component q i o m
component =
  H.mkComponent
    { initialState: \_ -> { count: 3 }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

-- Render
render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div [ HP.class_ (HH.ClassName "app") ]
    [ HH.h1_ [ HH.text "Halogen + HATS" ]
    , HH.p_ [ HH.text ("Bars: " <> show state.count) ]
    , HH.div [ HP.class_ (HH.ClassName "controls") ]
        [ HH.button [ HE.onClick \_ -> Decrement ] [ HH.text "\x2212" ]
        , HH.button [ HE.onClick \_ -> Increment ] [ HH.text "+" ]
        ]
    , HH.div [ HP.id "viz" ] []
    ]

-- Actions
handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    state <- H.get
    H.liftEffect (renderViz state.count)
  Increment -> do
    H.modify_ \s -> s { count = min 12 (s.count + 1) }
    state <- H.get
    H.liftEffect (renderViz state.count)
  Decrement -> do
    H.modify_ \s -> s { count = max 0 (s.count - 1) }
    state <- H.get
    H.liftEffect (renderViz state.count)

-- HATS rendering
renderViz :: Int -> Effect Unit
renderViz n = do
  clearElement "#viz"
  _ <- rerender "#viz" (barChart n)
  pure unit

-- A simple bar chart: n bars, each proportional to its index
barChart :: Int -> Tree
barChart n =
  let
    barWidth = 32.0
    gap = 4.0
    maxHeight = 200.0
    totalWidth = toNumber n * (barWidth + gap)
    items = range 1 n
  in
    elem SVG
      [ staticNum "width" totalWidth
      , staticNum "height" (maxHeight + 20.0)
      , staticStr "viewBox" ("0 0 " <> show totalWidth <> " " <> show (maxHeight + 20.0))
      ]
      [ forEach "bars" Rect items show \i ->
          let
            h = maxHeight * toNumber i / toNumber n
            x = toNumber (i - 1) * (barWidth + gap)
            y = maxHeight - h
          in
            elem Rect
              [ thunkedNum "x" x
              , thunkedNum "y" y
              , thunkedNum "width" barWidth
              , thunkedNum "height" h
              , thunkedStr "fill" "#2563eb"
              , thunkedNum "rx" 2.0
              ] []
      ]

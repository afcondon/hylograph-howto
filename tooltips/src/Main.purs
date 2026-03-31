-- | Tooltips — hover any circle to see a tooltip with its details.
module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)

import Hylograph.HATS (Tree, elem, forEach, staticStr, withBehaviors, onCoordinatedHighlightWithTooltip)
import Hylograph.HATS.Friendly as F
import Hylograph.HATS.InterpreterTick (rerender)
import Hylograph.Internal.Behavior.Types (HighlightClass(..), TooltipTrigger(..))
import Hylograph.Internal.Element.Types (ElementType(..))
import Hylograph.Tooltip (configureTooltip, lightTheme)

type Planet =
  { name :: String
  , radius :: Number
  , color :: String
  , x :: Number
  , y :: Number
  , detail :: String
  }

planets :: Array Planet
planets =
  [ { name: "Mercury", radius: 8.0,  color: "#b0b0b0", x: 50.0,  y: 120.0, detail: "Closest to the Sun" }
  , { name: "Venus",   radius: 12.0, color: "#e8c96a", x: 130.0, y: 90.0,  detail: "Hottest surface temperature" }
  , { name: "Earth",   radius: 13.0, color: "#4e9fd5", x: 220.0, y: 100.0, detail: "The only known living world" }
  , { name: "Mars",    radius: 10.0, color: "#d4644a", x: 310.0, y: 130.0, detail: "The Red Planet" }
  , { name: "Jupiter", radius: 28.0, color: "#d4a65a", x: 430.0, y: 100.0, detail: "Largest planet in the system" }
  , { name: "Saturn",  radius: 24.0, color: "#e8d88c", x: 550.0, y: 110.0, detail: "Famous for its rings" }
  ]

view :: Tree
view =
  elem SVG [ F.viewBox 0.0 0.0 640.0 240.0, F.width 640.0, F.height 240.0 ]
    [ forEach "planets" Group planets _.name \d ->
        withBehaviors
          [ onCoordinatedHighlightWithTooltip
              { identify: d.name
              , classify: \hovered ->
                  if hovered == d.name then Primary else Dimmed
              , group: Nothing
              , tooltip: Just
                  { content: "<b>" <> d.name <> "</b><br/>" <> d.detail
                  , showWhen: OnHover
                  , borderColor: Just d.color
                  }
              }
          ] $
          elem Group []
            [ elem Circle
                [ F.cx d.x, F.cy d.y, F.r d.radius
                , F.fill d.color
                , F.opacity "0.9"
                ] []
            , elem Text
                [ F.x d.x, F.y (d.y + d.radius + 16.0)
                , F.fontSize "11"
                , F.fontFamily "system-ui, sans-serif"
                , F.fill "#555"
                , F.textAnchor "middle"
                , staticStr "textContent" d.name
                ] []
            ]
    ]

main :: Effect Unit
main = do
  configureTooltip lightTheme
  _ <- rerender "#chart" view
  pure unit

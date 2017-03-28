module Volume.View exposing (control, bareControl)

import Html exposing (Html, div, input)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Volume
import Touch
import Utils.Touch exposing (onUnifiedClick, onSingleTouch)
import String


control : Float -> Bool -> Html Volume.Msg -> Html Volume.Msg
control volume muted label =
    let
        stateButton : List ( String, Bool ) -> Volume.Msg -> List (Html.Attribute Volume.Msg)
        stateButton classes msg =
            ((classList classes) :: (onUnifiedClick msg))
    in
        div
            [ classList [ ( "volume--control", True ), ( "volume--control__muted", muted ) ] ]
            [ div [ class "volume--label" ] [ label ]
            , div
                [ class "volume--range" ]
                [ div
                    (stateButton
                        [ ( "volume--state volume--state__mute", True )
                        , ( "volume--state__muted", muted )
                        ]
                        Volume.ToggleMute
                    )
                    []
                , div
                    [ class "volume--slider" ]
                    [ input
                        [ type_ "range"
                        , Html.Attributes.min "0"
                        , Html.Attributes.max (scale |> floor |> toString)
                        , value (toString (volume * scale))
                        , step "1"
                        , onInput (Volume.Change << decode)
                        ]
                        []
                    ]
                , div (stateButton [ ( "volume--state volume--state__full", True ) ] (Volume.Change (Just 1.0))) []
                ]
            ]


bareControl : Float -> Html Volume.Msg
bareControl volume =
    div
        [ class "volume--control" ]
        [ div
            [ class "volume--range" ]
            [ div
                [ class "volume--slider" ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "0"
                    , Html.Attributes.max (scale |> floor |> toString)
                    , value (toString (volume * scale))
                    , step "1"
                    , onInput (Volume.Change << decode)
                    ]
                    []
                ]
            ]
        ]


scale : Float
scale =
    1000.0


decode : String -> Maybe Float
decode input =
    case String.toFloat input of
        Ok value ->
            Just (value / scale)

        Err _ ->
            Nothing

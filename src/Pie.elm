module Pie exposing (view)

import Color exposing (Color)
import Color.Convert exposing (hexToColor)
import Dict
import GitHub
import Html exposing (Html, div, img)
import Html.Attributes exposing (class, src, style)
import Path
import Shape exposing (defaultPieConfig)
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes as Attr
import TypedSvg.Attributes.InPx exposing (height, width)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Paint(..), Transform(..), em)


type alias Data =
    { label : String
    , data : Float
    , color : Color
    }


fromRepo : GitHub.Repository -> Data
fromRepo repo =
    case repo.language of
        Nothing ->
            Data "none" (toFloat repo.star) Color.black

        Just lang ->
            case hexToColor lang.color of
                Ok c ->
                    Data lang.name (toFloat repo.star) c

                _ ->
                    Data "none" (toFloat repo.star) Color.black


view : GitHub.User -> Html msg
view user =
    let
        config =
            { outerRadius = 110
            , innerRadius = 200
            , padAngle = 0.02
            , cornerRadius = 0
            , labelPosition = 230
            }

        updateBy d value =
            case value of
                Nothing ->
                    Just d

                Just v ->
                    Just { v | data = v.data + d.data }

        model =
            List.map fromRepo user.repos
                |> List.foldl (\d -> Dict.update d.label (updateBy d)) Dict.empty
                |> Dict.filter (\_ v -> v.data /= 0)
    in
    div [ class "position-relative" ]
        [ img
            [ class "avatar position-absolute top-0 bottom-0 right-0 left-0"
            , style "margin" "auto"
            , style "width" "10em"
            , src user.avatar
            ]
            []
        , drawChart config (Dict.values model)
        ]


w : Float
w =
    990


h : Float
h =
    504


radius : Float
radius =
    min w h / 2


type alias ChartConfig =
    { outerRadius : Float
    , innerRadius : Float
    , padAngle : Float
    , cornerRadius : Float
    , labelPosition : Float
    }


drawChart : ChartConfig -> List Data -> Svg msg
drawChart config model =
    let
        pieData =
            List.map .data model
                |> Shape.pie
                    { defaultPieConfig
                        | innerRadius = config.innerRadius
                        , outerRadius = config.outerRadius
                        , padAngle = config.padAngle
                        , cornerRadius = config.cornerRadius
                        , sortingFn = \_ _ -> EQ
                    }

        makeSlice pieDatum datum =
            Path.element (Shape.arc pieDatum) [ Attr.fill (Paint datum.color) ]

        makeLabel pieDatum datum =
            let
                ( x, y ) =
                    Shape.centroid
                        { pieDatum
                            | innerRadius = config.labelPosition
                            , outerRadius = config.labelPosition
                        }
            in
            text_
                [ Attr.transform [ Translate x y ]
                , Attr.dy (em 0.35)
                , Attr.textAnchor AnchorMiddle
                ]
                [ text datum.label ]
    in
    svg [ width (radius * 2), height (radius * 2) ]
        [ g [ Attr.transform [ Translate radius radius ] ]
            [ g [] <| List.map2 makeSlice pieData model
            , g [] <| List.map2 makeLabel pieData model
            ]
        ]

module Library.State (..) where

import Effects exposing (Effects, Never)
import ID
import Library
import Library.Effects


initialState : Library.Model
initialState =
  let
    root =
      { id = "libraries", title = "Libraries", icon = "", children = [] }
  in
    { levels = [ root ] }


update : Library.Action -> Library.Model -> Maybe ID.Channel -> ( Library.Model, Effects Library.Action )
update action model maybeChannelId =
  case action of
    Library.NoOp ->
      ( model, Effects.none )

    Library.ExecuteAction a ->
      case maybeChannelId of
        Just channelId ->
          ( model, (Library.Effects.sendAction channelId a) )

        Nothing ->
          ( model, Effects.none )

    Library.Response folder ->
      ( (pushLevel model folder), Effects.none )

    Library.PopLevel index ->
      ( { model | levels = List.drop index model.levels }, Effects.none )


currentLevel : Library.Model -> Library.Folder
currentLevel model =
  case List.head model.levels of
    Just level ->
      level

    Nothing ->
      Debug.crash "Model has no root level!"


pushLevel : Library.Model -> Library.Folder -> Library.Model
pushLevel model folder =
  -- Debug.log ("pushLevel |" ++ (toString folder) ++ "| |" ++ (toString model.level) ++ "| ")
  { model | levels = (folder :: model.levels) }


add : Library.Model -> Library.Node -> Library.Model
add model library =
  let
    levels =
      (List.reverse model.levels)

    root =
      case (List.head levels) of
        Just level ->
          { level | children = (library :: level.children) }

        Nothing ->
          Debug.crash "Model has no root level!"

    others =
      case List.tail levels of
        Just l ->
          l

        Nothing ->
          []
  in
    { model | levels = (List.reverse (root :: others)) }

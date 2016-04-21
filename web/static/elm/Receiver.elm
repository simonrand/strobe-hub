module Receiver where

import ID

type alias Model =
  { id : ID.Receiver
  , name : String
  , online : Bool
  , volume : Float
  , zoneId : ID.Channel
  , editingName : Bool
  }


type Action
  = NoOp
  | Volume Float
  | Attach String


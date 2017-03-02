{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
module Fragment.Bool.Rules.Type (
    BoolTypeContext
  , boolTypeRules
  ) where

import Control.Lens (preview)

import Rules.Type
import Ast.Type

import Fragment.Bool.Ast.Type

type BoolTypeContext ki ty a = AsTyBool ki ty

normalizeBool :: BoolTypeContext ki ty a
              => Type ki ty a
              -> Maybe (Type ki ty a)
normalizeBool ty = do
  _ <- preview _TyBool ty
  return ty

boolTypeRules :: BoolTypeContext ki ty a
              => TypeInput ki ty a
boolTypeRules =
  TypeInput [ NormalizeTypeBase normalizeBool ]

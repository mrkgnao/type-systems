{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TypeFamilies #-}
module Fragment.IsoRec.Rules.Type.Infer.SyntaxDirected (
    IsoRecInferContext
  , isoRecInferRules
  ) where

import Bound (instantiate1)
import Control.Monad.Except (MonadError)
import Control.Lens (preview)

import Rules.Type.Infer.SyntaxDirected
import Ast.Type
import Ast.Term
import Data.Functor.Rec

import Fragment.IsoRec.Ast.Type
import Fragment.IsoRec.Ast.Term

inferTmFold :: IsoRecInferContext e w s r m ki ty pt tm a
            => (Term ki ty pt tm a -> m (Type ki ty a))
            -> Term ki ty pt tm a
            -> Maybe (m (Type ki ty a))
inferTmFold inferFn tm = do
  (tyF, tmF) <- preview _TmFold tm
  s <- preview _TyRec tyF
  return $ do
    mkCheckType inferFn tmF (instantiate1 tyF s)
    return tyF

inferTmUnfold :: IsoRecInferContext e w s r m ki ty pt tm a
              => (Term ki ty pt tm a -> m (Type ki ty a))
              -> Term ki ty pt tm a
              -> Maybe (m (Type ki ty a))
inferTmUnfold inferFn tm = do
  (tyU, tmU) <- preview _TmUnfold tm
  s <- preview _TyRec tyU
  return $ do
    mkCheckType inferFn tmU tyU
    return $ instantiate1 tyU s

type IsoRecInferContext e w s r m ki ty pt tm a = (Eq a, EqRec (ty ki), MonadError e m, InferContext e w s r m ki ty pt tm a, AsTyIsoRec ki ty, AsTmIsoRec ki ty pt tm)

isoRecInferRules :: IsoRecInferContext e w s r m ki ty pt tm a
                  => InferInput e w s r m ki ty pt tm a
isoRecInferRules =
  InferInput
    [ InferRecurse inferTmFold
    , InferRecurse inferTmUnfold
    ]
    []

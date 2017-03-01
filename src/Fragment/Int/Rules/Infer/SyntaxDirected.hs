{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
module Fragment.Int.Rules.Infer.SyntaxDirected (
    IntInferContext
  , intInferRules
  ) where

import Control.Monad.Except (MonadError)
import Control.Lens (review, preview)

import Rules.Infer
import Ast.Type
import Ast.Pattern
import Ast.Term
import Ast.Error.Common
import Data.Functor.Rec

import Fragment.Int.Ast.Type
import Fragment.Int.Ast.Pattern
import Fragment.Int.Ast.Term

equivInt :: AsTyInt ki ty => Type ki ty a -> Type ki ty a -> Maybe Bool
equivInt ty1 ty2 = do
  _ <- preview _TyInt ty1
  _ <- preview _TyInt ty2
  return True

inferInt :: (Monad m, AsTyInt ki ty, AsTmInt ki ty pt tm)
         => Term ki ty pt tm a
         -> Maybe (m (Type ki ty a))
inferInt tm = do
  _ <- preview _TmInt tm
  return . return . review _TyInt $ ()

inferAdd :: (Eq a, EqRec (ty ki), MonadError e m, AsUnexpected e ki ty a, AsTyInt ki ty, AsTmInt ki ty pt tm)
         => (Type ki ty a -> Type ki ty a -> Bool)
         -> (Term ki ty pt tm a -> m (Type ki ty a))
         -> Term ki ty pt tm a
         -> Maybe (m (Type ki ty a))
inferAdd tyEquiv inferFn tm = do
  (tm1, tm2) <- preview _TmAdd tm
  return $ do
    let ty = review _TyInt ()
    mkCheck tyEquiv inferFn tm1 ty
    mkCheck tyEquiv inferFn tm2 ty
    return ty

inferMul :: (Eq a, EqRec (ty ki), MonadError e m, AsUnexpected e ki ty a, AsTyInt ki ty, AsTmInt ki ty pt tm)
         => (Type ki ty a -> Type ki ty a -> Bool)
         -> (Term ki ty pt tm a -> m (Type ki ty a))
         -> Term ki ty pt tm a
         -> Maybe (m (Type ki ty a))
inferMul tyEquiv inferFn tm = do
  (tm1, tm2) <- preview _TmMul tm
  return $ do
    let ty = review _TyInt ()
    mkCheck tyEquiv inferFn tm1 ty
    mkCheck tyEquiv inferFn tm2 ty
    return ty

checkInt :: (Eq a, EqRec (ty ki), MonadError e m, AsUnexpected e ki ty a, AsPtInt pt, AsTyInt ki ty) => (Type ki ty a -> Type ki ty a -> Bool) -> Pattern pt a -> Type ki ty a -> Maybe (m [Type ki ty a])
checkInt tyEquiv p ty = do
  _ <- preview _PtInt p
  return $ do
    let tyI = review _TyInt ()
    expect tyEquiv (ExpectedType tyI) (ActualType ty)
    return []

type IntInferContext e w s r m ki ty pt tm a = (InferContext e w s r m ki ty pt tm a, AsTyInt ki ty, AsPtInt pt, AsTmInt ki ty pt tm)

intInferRules :: IntInferContext e w s r m ki ty pt tm a
              => InferInput e w s r m ki ty pt tm a
intInferRules =
  InferInput
    [ EquivBase equivInt ]
    [ InferBase inferInt
    , InferTyEquivRecurse inferAdd
    , InferTyEquivRecurse inferMul
    ]
    [ PCheckTyEquiv checkInt ]

{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
module Fragment.Ast (
    AstVar(..)
  , _ATyVar
  , _APtVar
  , _ATmVar
  , Ast(..)
  , _AVar
  , _AType
  , _APattern
  , _ATerm
  , Type(..)
  , Pattern(..)
  , Term(..)
  ) where

import Control.Monad (ap)
import GHC.Exts (Constraint)

import Control.Lens

import Bound
import Data.Functor.Classes
import Data.Deriving

data AstVar a =
    ATyVar a
  | APtVar a
  | ATmVar a
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

deriveEq1 ''AstVar
deriveOrd1 ''AstVar
deriveShow1 ''AstVar

makePrisms ''AstVar

data Ast ty pt tm a =
    AVar a
  | AType (ty (Ast ty pt tm) a)
  | APattern (pt (Ast ty pt tm) a)
  | ATerm (tm ty pt (Ast ty pt tm) a)

makePrisms ''Ast

type TripleConstraint (k :: * -> Constraint) ty pt tm a =
  ( k (ty (Ast ty pt tm) a)
  , k (pt (Ast ty pt tm) a)
  , k (tm ty pt (Ast ty pt tm) a)
  )

type TripleConstraint1 (k :: (* -> *) -> Constraint) ty pt tm =
  ( k (ty (Ast ty pt tm))
  , k (pt (Ast ty pt tm))
  , k (tm ty pt (Ast ty pt tm))
  )

deriving instance (Eq a, TripleConstraint Eq ty pt tm a) => Eq (Ast ty pt tm a)

deriving instance (Ord a, TripleConstraint Ord ty pt tm a) => Ord (Ast ty pt tm a)

deriving instance (Show a, TripleConstraint Show ty pt tm a) => Show (Ast ty pt tm a)

instance TripleConstraint1 Eq1 ty pt tm => Eq1 (Ast ty pt tm) where
  liftEq = $(makeLiftEq ''Ast)

instance TripleConstraint1 Ord1 ty pt tm => Ord1 (Ast ty pt tm) where
  liftCompare = $(makeLiftCompare ''Ast)

instance TripleConstraint1 Show1 ty pt tm => Show1 (Ast ty pt tm) where
  liftShowsPrec = $(makeLiftShowsPrec ''Ast)

deriving instance TripleConstraint1 Functor ty pt tm => Functor (Ast ty pt tm)
deriving instance TripleConstraint1 Foldable ty pt tm => Foldable (Ast ty pt tm)

deriving instance TripleConstraint1 Traversable ty pt tm => Traversable (Ast ty pt tm)

instance (TripleConstraint1 Functor ty pt tm, Bound ty, Bound pt, Bound (tm ty pt)) => Applicative (Ast ty pt tm) where
  pure = return
  (<*>) = ap

instance (TripleConstraint1 Functor ty pt tm, Bound ty, Bound pt, Bound (tm ty pt)) => Monad (Ast ty pt tm) where
  return = AVar

  AVar x >>= f = f x
  AType ty >>= f = AType (ty >>>= f)
  APattern pt >>= f = APattern (pt >>>= f)
  ATerm tm >>= f = ATerm (tm >>>= f)

data Type ty a = TyVar a | Type (ty (Type ty) a)

makePrisms ''Type

deriving instance (Eq a, Eq (ty (Type ty) a)) => Eq (Type ty a)
deriving instance (Ord a, Ord (ty (Type ty) a)) => Ord (Type ty a)
deriving instance (Show a, Show (ty (Type ty) a)) => Show (Type ty a)

instance Eq1 (ty (Type ty)) => Eq1 (Type ty) where
  liftEq = $(makeLiftEq ''Type)

instance Ord1 (ty (Type ty)) => Ord1 (Type ty) where
  liftCompare = $(makeLiftCompare ''Type)

instance Show1 (ty (Type ty)) => Show1 (Type ty) where
  liftShowsPrec = $(makeLiftShowsPrec ''Type)

deriving instance (Functor (ty (Type ty))) => Functor (Type ty)
deriving instance (Foldable (ty (Type ty))) => Foldable (Type ty)
deriving instance (Traversable (ty (Type ty))) => Traversable (Type ty)

instance (Functor (ty (Type ty)), Bound ty) => Applicative (Type ty) where
  pure = return
  (<*>) = ap

instance (Functor (ty (Type ty)), Bound ty) => Monad (Type ty) where
  return = TyVar

  TyVar x >>= f = f x
  Type x >>= f = Type (x >>>= f)

data Pattern pt a = PtVar a | Pattern (pt (Pattern pt) a)

makePrisms ''Pattern

deriving instance (Eq a, Eq (pt (Pattern pt) a)) => Eq (Pattern pt a)
deriving instance (Ord a, Ord (pt (Pattern pt) a)) => Ord (Pattern pt a)
deriving instance (Show a, Show (pt (Pattern pt) a)) => Show (Pattern pt a)

instance Eq1 (pt (Pattern pt)) => Eq1 (Pattern pt) where
  liftEq = $(makeLiftEq ''Pattern)

instance Ord1 (pt (Pattern pt)) => Ord1 (Pattern pt) where
  liftCompare = $(makeLiftCompare ''Pattern)

instance Show1 (pt (Pattern pt)) => Show1 (Pattern pt) where
  liftShowsPrec = $(makeLiftShowsPrec ''Pattern)

deriving instance (Functor (pt (Pattern pt))) => Functor (Pattern pt)
deriving instance (Foldable (pt (Pattern pt))) => Foldable (Pattern pt)
deriving instance (Traversable (pt (Pattern pt))) => Traversable (Pattern pt)

instance (Functor (pt (Pattern pt)), Bound pt) => Applicative (Pattern pt) where
  pure = return
  (<*>) = ap

instance (Functor (pt (Pattern pt)), Bound pt) => Monad (Pattern pt) where
  return = PtVar

  PtVar x >>= f = f x
  Pattern x >>= f = Pattern (x >>>= f)

newtype Term ty pt tm a = Term (Ast ty pt tm (AstVar a))

makeWrapped ''Term

deriving instance (Eq a, TripleConstraint Eq ty pt tm (AstVar a)) => Eq (Term ty pt tm a)
deriving instance (Ord a, TripleConstraint Ord ty pt tm (AstVar a)) => Ord (Term ty pt tm a)
deriving instance (Show a, TripleConstraint Show ty pt tm (AstVar a)) => Show (Term ty pt tm a)

instance (TripleConstraint1 Eq1 ty pt tm) => Eq1 (Term ty pt tm) where
  liftEq = $(makeLiftEq ''Term)

instance (TripleConstraint1 Ord1 ty pt tm) => Ord1 (Term ty pt tm) where
  liftCompare = $(makeLiftCompare ''Term)

instance (TripleConstraint1 Show1 ty pt tm) => Show1 (Term ty pt tm) where
  liftShowsPrec = $(makeLiftShowsPrec ''Term)

deriving instance (TripleConstraint1 Functor ty pt tm) => Functor (Term ty pt tm)
deriving instance (TripleConstraint1 Foldable ty pt tm) => Foldable (Term ty pt tm)
deriving instance (TripleConstraint1 Traversable ty pt tm) => Traversable (Term ty pt tm)

-- TODO a prism from Ast ty pt tm (AstVar a) <-> Pattern pt a
-- _Pattern :: Traversable (pt (Ast ty pt tm)) => Prism' (Ast ty pt tm (AstVar a)) (Pattern pt a)
-- _Pattern = _APattern . below _APtVar . _Unwrapped
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
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
module Language.TheLot (
    runEvalStrict
  , runEvalLazy
  , runInfer
  , runCheck
  ) where

-- TODO reexport the helpers
-- TODO probably should put them into their own module for that

import Control.Monad.Reader
import Control.Monad.Except
import Control.Monad.State

import qualified Data.List.NonEmpty as N
import qualified Data.Text as T

import Control.Lens

import Bound
import Data.Functor.Classes
import Data.Deriving

import Fragment
import Fragment.Ast
import Error
import Util

import Fragment.Var
import Fragment.Int
import Fragment.Bool
import Fragment.Pair
import Fragment.Tuple
import Fragment.Record
-- import Fragment.Variant
import Fragment.STLC

data TypeF f a =
    TyLInt (TyFInt f a)
  | TyLBool (TyFBool f a)
  | TyLPair (TyFPair f a)
  | TyLTuple (TyFTuple f a)
  | TyLRecord (TyFRecord f a)
--  | TyLVariant (TyFVariant Type a)
 | TyLSTLC (TyFSTLC f a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

deriveEq1 ''TypeF
deriveOrd1 ''TypeF
deriveShow1 ''TypeF

makePrisms ''TypeF

instance AsTyInt TypeF where
  _TyIntP = _TyLInt

instance AsTyBool TypeF where
  _TyBoolP = _TyLBool

instance AsTyPair TypeF where
  _TyPairP = _TyLPair

instance AsTyTuple TypeF where
  _TyTupleP = _TyLTuple

instance AsTyRecord TypeF where
  _TyRecordP = _TyLRecord

-- instance AsTyVariant Type where
--  _TyVariantP = _TyLVariant

instance AsTySTLC TypeF where
  _TySTLCP = _TyLSTLC

instance Bound TypeF where
  TyLInt i >>>= f = TyLInt (i >>>= f)
  TyLBool b >>>= f = TyLBool (b >>>= f)
  TyLPair p >>>= f = TyLPair (p >>>= f)
  TyLTuple t >>>= f = TyLTuple (t >>>= f)
  TyLRecord r >>>= f = TyLRecord (r >>>= f)
  TyLSTLC lc >>>= f = TyLSTLC (lc >>>= f)

instance Bitransversable TypeF where
  bitransverse fT fL (TyLInt i) = TyLInt <$> bitransverse fT fL i
  bitransverse fT fL (TyLBool b) = TyLBool <$> bitransverse fT fL b
  bitransverse fT fL (TyLPair p) = TyLPair <$> bitransverse fT fL p
  bitransverse fT fL (TyLTuple t) = TyLTuple <$> bitransverse fT fL t
  bitransverse fT fL (TyLRecord r) = TyLRecord <$> bitransverse fT fL r
  bitransverse fT fL (TyLSTLC lc) = TyLSTLC <$> bitransverse fT fL lc

data PatternF f a =
    PtLWild (PtFWild f a)
  | PtLInt (PtFInt f a)
  | PtLBool (PtFBool f a)
  | PtLPair (PtFPair f a)
  | PtLTuple (PtFTuple f a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

deriveEq1 ''PatternF
deriveOrd1 ''PatternF
deriveShow1 ''PatternF

makePrisms ''PatternF

instance AsPtWild PatternF where
  _PtWildP = _PtLWild

instance AsPtInt PatternF where
  _PtIntP = _PtLInt

instance AsPtBool PatternF where
  _PtBoolP = _PtLBool

instance AsPtPair PatternF where
  _PtPairP = _PtLPair

instance AsPtTuple PatternF where
  _PtTupleP = _PtLTuple

instance Bound PatternF where
  PtLWild w >>>= f = PtLWild (w >>>= f)
  PtLInt i >>>= f = PtLInt (i >>>= f)
  PtLBool b >>>= f = PtLBool (b >>>= f)
  PtLPair p >>>= f = PtLPair (p >>>= f)
  PtLTuple t >>>= f = PtLTuple (t >>>= f)

instance Bitransversable PatternF where
  bitransverse fT fL (PtLWild w) = PtLWild <$> bitransverse fT fL w
  bitransverse fT fL (PtLInt i) = PtLInt <$> bitransverse fT fL i
  bitransverse fT fL (PtLBool b) = PtLBool <$> bitransverse fT fL b
  bitransverse fT fL (PtLPair p) = PtLPair <$> bitransverse fT fL p
  bitransverse fT fL (PtLTuple t) = PtLTuple <$> bitransverse fT fL t

data TermF ty pt f a =
    TmLInt (TmFInt ty pt f a)
  | TmLBool (TmFBool ty pt f a)
  | TmLPair (TmFPair ty pt f a)
  | TmLTuple (TmFTuple ty pt f a)
  | TmLRecord (TmFRecord ty pt f a)
--  | TmLVariant (TmFVariant Type Void Term a)
  | TmLSTLC (TmFSTLC ty pt f a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

makePrisms ''TermF

instance (Eq1 f, Monad f) => Eq1 (TermF ty pt f) where
  liftEq = $(makeLiftEq ''TermF)

instance (Ord1 f, Monad f) => Ord1 (TermF ty pt f) where
  liftCompare = $(makeLiftCompare ''TermF)

deriveShow1 ''TermF

instance AsTmInt ty pt TermF where
  _TmIntP = _TmLInt

instance AsTmBool ty pt TermF where
  _TmBoolP = _TmLBool

instance AsTmPair ty pt TermF where
  _TmPairP = _TmLPair

instance AsTmTuple ty pt TermF where
  _TmTupleP = _TmLTuple

instance AsTmRecord ty pt TermF where
  _TmRecordP = _TmLRecord

-- instance AsTmVariant Type Term where
--  _TmVariantP = _TmLVariant

instance (TripleConstraint1 Traversable ty pt TermF, Traversable (ty (Type ty)), Bitransversable ty) => AsTmSTLC ty pt TermF where
  _TmSTLCP = _TmLSTLC

instance Bound (TermF ty pt) where
  TmLInt i >>>= f = TmLInt (i >>>= f)
  TmLBool b >>>= f = TmLBool (b >>>= f)
  TmLPair p >>>= f = TmLPair (p >>>= f)
  TmLTuple t >>>= f = TmLTuple (t >>>= f)
  TmLRecord r >>>= f = TmLRecord (r >>>= f)
--  TmLVariant v >>= f = TmLVariant (v >>>= f)
  TmLSTLC lc >>>= f = TmLSTLC (lc >>>= f)

instance Bitransversable (TermF ty tp) where
  bitransverse fT fL (TmLInt i) = TmLInt <$> bitransverse fT fL i
  bitransverse fT fL (TmLBool b) = TmLBool <$> bitransverse fT fL b
  bitransverse fT fL (TmLPair p) = TmLPair <$> bitransverse fT fL p
  bitransverse fT fL (TmLTuple t) = TmLTuple <$> bitransverse fT fL t
  bitransverse fT fL (TmLRecord r) = TmLRecord <$> bitransverse fT fL r
  bitransverse fT fL (TmLSTLC lc) = TmLSTLC <$> bitransverse fT fL lc

data Error ty a =
    EUnexpected (ty a) (ty a)
  | EExpectedEq (ty a) (ty a)
  | EExpectedTyPair (ty a)
  | EExpectedTyTuple (ty a)
  | ETupleOutOfBounds Int Int
  | EExpectedTyRecord (ty a)
  | ERecordNotFound T.Text
  | EExpectedTyVariant (ty a)
  | EVariantNotFound T.Text
  | EExpectedAllEq (N.NonEmpty (ty a))
  | EExpectedTyArr (ty a)
  | EUnboundTermVariable a
  | EUnknownTypeError
  deriving (Eq, Ord, Show)

makePrisms ''Error

instance AsUnexpected (Error ty a) (ty a) where
  _Unexpected = _EUnexpected

instance AsExpectedEq (Error ty a) (ty a) where
  _ExpectedEq = _EExpectedEq

instance AsExpectedTyPair (Error ty a) (ty a) where
  _ExpectedTyPair = _EExpectedTyPair

instance AsExpectedTyTuple (Error ty a) (ty a) where
  _ExpectedTyTuple = _EExpectedTyTuple

instance AsTupleOutOfBounds (Error ty a) where
  _TupleOutOfBounds = _ETupleOutOfBounds

instance AsExpectedTyRecord (Error ty a) (ty a) where
  _ExpectedTyRecord = _EExpectedTyRecord

instance AsRecordNotFound (Error ty a) where
  _RecordNotFound = _ERecordNotFound

-- instance AsExpectedTyVariant (Error ty a) (ty a) where
--  _ExpectedTyVariant = _EExpectedTyVariant

-- instance AsVariantNotFound (Error ty a) where
--  _VariantNotFound = _EVariantNotFound

-- instance AsExpectedAllEq (Error ty a) (ty a) where
--  _ExpectedAllEq = _EExpectedAllEq

instance AsExpectedTyArr (Error ty a) (ty a) where
  _ExpectedTyArr = _EExpectedTyArr

instance AsUnboundTermVariable (Error ty a) a where
  _UnboundTermVariable = _EUnboundTermVariable

instance AsUnknownTypeError (Error ty a) where
  _UnknownTypeError = _EUnknownTypeError

type LContext e s r m ty pt tm a =
  ( TmVarContext e s r m ty pt tm a
  , PtVarContext e s r m ty pt tm a
  , IntContext e s r m ty pt tm a
  , BoolContext e s r m ty pt tm a
  , PairContext e s r m ty pt tm a
  , TupleContext e s r m ty pt tm a
  , RecordContext e s r m ty pt tm a
  , STLCContext e s r m ty pt tm a
  , AsUnknownTypeError e
  )

fragmentInputBase :: LContext e s r m ty pt tm a => FragmentInput e s r m ty pt tm a
fragmentInputBase = mconcat [ptVarFragment, tmVarFragment, intFragment, boolFragment]

fragmentInputLazy :: LContext e s r m ty pt tm a => FragmentInput e s r m ty pt tm a
fragmentInputLazy = mconcat [fragmentInputBase, pairFragmentLazy, tupleFragmentLazy, recordFragmentLazy, stlcFragmentLazy]

fragmentInputStrict :: LContext e s r m ty pt tm a => FragmentInput e s r m ty pt tm a
fragmentInputStrict = mconcat [fragmentInputBase, pairFragmentStrict, tupleFragmentStrict, recordFragmentStrict, stlcFragmentStrict]

type M e s r = StateT s (ReaderT r (Except e))

runM :: s -> r -> M e s r a -> Either e a
runM s r m =
  runExcept .
  flip runReaderT r .
  flip evalStateT s $
  m

type LTerm = Term TypeF PatternF TermF
type LType = Type TypeF

type Output a = FragmentOutput (Error LType a) Int (TermContext TypeF a a) (M (Error LType a) Int (TermContext TypeF a a)) TypeF PatternF TermF a

fragmentOutputLazy :: (Ord a, Eq (LType a), ToTmVar a) => Output a
fragmentOutputLazy = prepareFragment fragmentInputLazy

fragmentOutputStrict :: (Ord a, Eq (LType a), ToTmVar a) => Output a
fragmentOutputStrict = prepareFragment fragmentInputStrict


runEvalLazy :: (Ord a, Eq (LType a), ToTmVar a) => LTerm a -> LTerm a
runEvalLazy =
  foEval fragmentOutputLazy

runEvalStrict :: (Ord a, Eq (LType a), ToTmVar a) => LTerm a -> LTerm a
runEvalStrict =
  foEval fragmentOutputStrict

runInfer :: (Ord a, ToTmVar a) => LTerm a -> Either (Error LType a) (LType a)
runInfer =
  runM 0 emptyTermContext .
  foInfer fragmentOutputLazy

runCheck :: (Ord a, ToTmVar a) => LTerm a -> LType a -> Either (Error LType a) ()
runCheck tm ty =
  runM 0 emptyTermContext $ foCheck fragmentOutputLazy tm ty

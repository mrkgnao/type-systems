{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
module Fragment.Tuple (
    module X
  , TupleTag
  ) where

import Ast
import Rules.Type
import Rules.Type.Infer.Common
import Rules.Term
import Fragment.KiBase.Ast.Kind

import Fragment.Tuple.Ast as X
import Fragment.Tuple.Helpers as X

import Fragment.Tuple.Rules.Type
import Fragment.Tuple.Rules.Type.Infer.Common
import Fragment.Tuple.Rules.Term

data TupleTag

instance AstIn TupleTag where
  type KindList TupleTag = '[KiFBase]
  type TypeList TupleTag = '[TyFTuple]
  type PatternList TupleTag = '[PtFTuple]
  type TermList TupleTag = '[TmFTuple]

instance EvalRules EStrict TupleTag where
  type EvalConstraint ki ty pt tm a EStrict TupleTag =
    TupleEvalConstraint ki ty pt tm a

  evalInput _ _ =
    tupleEvalRulesStrict

instance EvalRules ELazy TupleTag where
  type EvalConstraint ki ty pt tm a ELazy TupleTag =
    TupleEvalConstraint ki ty pt tm a

  evalInput _ _ =
    tupleEvalRulesLazy

instance NormalizeRules TupleTag where
  type NormalizeConstraint ki ty a TupleTag =
    TupleNormalizeConstraint ki ty a

  normalizeInput _ =
    tupleNormalizeRules

instance MkInferType i => InferTypeRules i TupleTag where
  type InferTypeConstraint e w s r m ki ty pt tm a i TupleTag =
    TupleInferTypeConstraint e w s r m ki ty pt tm a i
  type ErrorList ki ty pt tm a i TupleTag =
    '[ ErrExpectedTyTuple ki ty a
     , ErrTupleOutOfBounds
     ]
  type WarningList ki ty pt tm a i TupleTag =
    '[]

  inferTypeInput' m i _ =
    tupleInferTypeInput m i

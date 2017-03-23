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
module Fragment.Pair (
    module X
  , PairTag
  ) where

import Ast
import Rules.Type
import Rules.Type.Infer.Common
import Rules.Term
import Fragment.KiBase.Ast.Kind

import Fragment.Pair.Ast as X
import Fragment.Pair.Helpers as X

import Fragment.Pair.Rules.Type
import Fragment.Pair.Rules.Type.Infer.Common
import Fragment.Pair.Rules.Term

data PairTag

instance AstIn PairTag where
  type KindList PairTag = '[KiFBase]
  type TypeList PairTag = '[TyFPair]
  type PatternList PairTag = '[PtFPair]
  type TermList PairTag = '[TmFPair]

instance EvalRules EStrict PairTag where
  type EvalConstraint ki ty pt tm a EStrict PairTag =
    PairEvalConstraint ki ty pt tm a

  evalInput _ _ =
    pairEvalRulesStrict

instance EvalRules ELazy PairTag where
  type EvalConstraint ki ty pt tm a ELazy PairTag =
    PairEvalConstraint ki ty pt tm a

  evalInput _ _ =
    pairEvalRulesLazy

instance NormalizeRules PairTag where
  type NormalizeConstraint ki ty a PairTag =
    PairNormalizeConstraint ki ty a

  normalizeInput _ =
    pairNormalizeRules

instance MkInferType i => InferTypeRules i PairTag where
  type InferTypeConstraint e w s r m ki ty pt tm a i PairTag =
    PairInferTypeConstraint e w s r m ki ty pt tm a i
  type ErrorList ki ty pt tm a i PairTag =
    '[ErrExpectedTyPair ki ty a]
  type WarningList ki ty pt tm a i PairTag =
    '[]

  inferTypeInput' m i _ =
    pairInferTypeInput m i

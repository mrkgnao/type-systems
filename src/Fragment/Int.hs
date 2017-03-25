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
module Fragment.Int (
    module X
  , IntTag
  ) where

import Ast
import Rules.Type
import Rules.Type.Infer.Common
import Rules.Term
import Fragment.KiBase.Ast.Kind

import Fragment.Int.Ast as X
import Fragment.Int.Helpers as X

import Fragment.Int.Rules.Type
import Fragment.Int.Rules.Type.Infer.Common
import Fragment.Int.Rules.Term

data IntTag

instance AstIn IntTag where
  type KindList IntTag = '[KiFBase]
  type TypeList IntTag = '[TyFInt]
  type PatternList IntTag = '[PtFInt]
  type TermList IntTag = '[TmFInt]

instance EvalRules e IntTag where
  type EvalConstraint ki ty pt tm a e IntTag =
    IntEvalConstraint ki ty pt tm a

  evalInput _ _ =
    intEvalRules

instance NormalizeRules IntTag where
  type NormalizeConstraint ki ty a IntTag =
    IntNormalizeConstraint ki ty a

  normalizeInput _ =
    intNormalizeRules

instance MkInferType i => InferTypeRules i IntTag where
  type InferTypeConstraint e w s r m ki ty pt tm a i IntTag =
    IntInferTypeConstraint e w s r m ki ty pt tm a i
  type ErrorList ki ty pt tm a i IntTag =
    '[]
  type WarningList ki ty pt tm a i IntTag =
    '[]

  inferTypeInput m i _ =
    intInferTypeInput m i

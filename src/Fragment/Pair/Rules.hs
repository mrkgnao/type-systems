{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
module Fragment.Pair.Rules (
    RPair
  ) where

import Ast
import Rules

import Fragment.KiBase.Ast.Kind

import Fragment.Pair.Ast
import qualified Fragment.Pair.Rules.Kind.Infer.SyntaxDirected as KSD
import qualified Fragment.Pair.Rules.Type.Infer.SyntaxDirected as TSD
import qualified Fragment.Pair.Rules.Type.Infer.Offline as TUO

data RPair

instance AstIn RPair where
  type KindList RPair = '[KiFBase]
  type TypeList RPair = '[TyFPair]
  type PatternList RPair = '[PtFPair]
  type TermList RPair = '[TmFPair]

instance RulesIn RPair where
  type InferKindContextSyntax e w s r m ki ty a RPair = KSD.PairInferKindContext e w s r m ki ty a
  type InferTypeContextSyntax e w s r m ki ty pt tm a RPair = TSD.PairInferTypeContext e w s r m ki ty pt tm a
  type InferTypeContextOffline e w s r m ki ty pt tm a RPair = TUO.PairInferTypeContext e w s r m ki ty pt tm a
  type ErrorList ki ty pt tm a RPair = '[ErrExpectedTyPair ki ty a]
  type WarningList ki ty pt tm a RPair = '[]

  inferKindInputSyntax _ = KSD.pairInferKindRules
  inferTypeInputSyntax _ = TSD.pairInferTypeRules
  inferTypeInputOffline _ = TUO.pairInferTypeRules

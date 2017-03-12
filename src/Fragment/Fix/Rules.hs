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
module Fragment.Fix.Rules (
    RFix
  ) where

import GHC.Exts (Constraint)

import Rules

import Fragment.TyArr.Ast.Error
import Fragment.TyArr.Ast.Type

import Fragment.Fix.Ast
import qualified Fragment.Fix.Rules.Type.Infer.SyntaxDirected as TSD
import qualified Fragment.Fix.Rules.Type.Infer.Offline as TUO
import Fragment.Fix.Rules.Term

data RFix

instance RulesIn RFix where
  type InferKindContextSyntax e w s r m ki ty a RFix =
    (() :: Constraint)
  type InferTypeContextSyntax e w s r m ki ty pt tm a RFix =
    TSD.FixInferTypeContext e w s r m ki ty pt tm a
  type InferTypeContextOffline e w s r m ki ty pt tm a RFix =
    TUO.FixInferTypeContext e w s r m ki ty pt tm a
  type RuleTypeContext ki ty a RFix =
    (() :: Constraint)
  type RuleTermContext ki ty pt tm a RFix = FixTermContext ki ty pt tm a
  type KindList RFix = '[]
  type TypeList RFix = '[TyFArr]
  type ErrorList ki ty pt tm a RFix = '[ErrExpectedTyArr ki ty a]
  type WarningList ki ty pt tm a RFix = '[]
  type PatternList RFix = '[]
  type TermList RFix = '[TmFFix]

  inferKindInputSyntax _ = mempty
  inferTypeInputSyntax _ = TSD.fixInferTypeRules
  inferTypeInputOffline _ = TUO.fixInferTypeRules
  typeInput _ = mempty
  termInput _ = fixTermRules

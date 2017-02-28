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
module Fragment.Case.Rules (
    RCase
  ) where

import Rules
import Ast.Error.Common
import Context.Term.Error

import Fragment.Case.Ast
import qualified Fragment.Case.Rules.Infer.SyntaxDirected as SD
import qualified Fragment.Case.Rules.Infer.Unification.Offline as UO
import Fragment.Case.Rules.Eval

data RCase

instance RulesIn RCase where
  type RuleInferSyntaxContext e w s r m ty pt tm a RCase = SD.CaseInferContext e w s r m ty pt tm a
  type RuleInferOfflineContext e w s r m ty pt tm a RCase = UO.CaseInferContext e w s r m ty pt tm a
  type RuleEvalContext ty pt tm a RCase = CaseEvalContext ty pt tm a
  type TypeList RCase = '[]
  type ErrorList ty pt tm a RCase = '[ErrExpectedAllEq ty a, ErrUnboundTermVariable a, ErrExpectedPattern ty pt tm a, ErrDuplicatedPatternVariables a]
  type WarningList ty pt tm a RCase = '[WarnUnusedPatternVariables a, WarnShadowingPatternVariables a]
  type PatternList RCase = '[]
  type TermList RCase = '[TmFCase]

  inferSyntaxInput _ = SD.caseInferRules
  inferOfflineInput _ = UO.caseInferRules
  evalLazyInput _ = caseEvalRulesLazy
  evalStrictInput _ = caseEvalRulesStrict

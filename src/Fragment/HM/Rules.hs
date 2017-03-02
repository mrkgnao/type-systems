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
module Fragment.HM.Rules (
    RHM
  ) where

import GHC.Exts (Constraint)

import Rules

import Fragment.HM.Ast
import Fragment.HM.Rules.Infer.Unification.Offline
import Fragment.HM.Rules.Type
import Fragment.HM.Rules.Term

data RHM

instance RulesIn RHM where
  type RuleInferSyntaxContext e w s r m ki ty pt tm a RHM = (() :: Constraint)
  type RuleInferOfflineContext e w s r m ki ty pt tm a RHM = HMInferContext e w s r m ki ty pt tm a
  type RuleTypeContext ki ty a RHM = HMTypeContext ki ty a
  type RuleTermContext ki ty pt tm a RHM = HMTermContext ki ty pt tm a
  type KindList RHM = '[]
  type TypeList RHM = '[TyFHM]
  type ErrorList ki ty pt tm a RHM = '[ErrExpectedTyArr ki ty a]
  type WarningList ki ty pt tm a RHM = '[]
  type PatternList RHM = '[]
  type TermList RHM = '[TmFHM]

  inferSyntaxInput _ = mempty
  inferOfflineInput _ = hmInferRules
  typeInput _ = hmTypeRules
  termInput _ = hmTermRules

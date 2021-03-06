{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
module Fragment.Annotation.Rules.Term (
    AnnotationEvalConstraint
  , annotationEvalRules
  ) where

import Control.Lens (review, preview)

import Rules.Term
import Ast.Pattern
import Ast.Term

import Fragment.Annotation.Ast.Term

type AnnotationEvalConstraint ki ty pt tm a = AsTmAnnotation ki ty pt tm

valueAnnotation :: AsTmAnnotation ki ty pt tm
                => (Term ki ty pt tm a -> Maybe (Term ki ty pt tm a))
                -> Term ki ty pt tm a
                -> Maybe (Term ki ty pt tm a)
valueAnnotation valueFn tm = do
  (tyA, tmA) <- preview _TmAnnotation tm
  vA <- valueFn tmA
  return $ review _TmAnnotation (tyA, vA)

stepAnnotation :: AsTmAnnotation ki ty pt tm
               => (Term ki ty pt tm a -> Maybe (Term ki ty pt tm a))
               -> Term ki ty pt tm a
               -> Maybe (Term ki ty pt tm a)
stepAnnotation stepFn tm = do
  (tyA, tmA) <- preview _TmAnnotation tm
  tmA' <- stepFn tmA
  return $ review _TmAnnotation (tyA, tmA')

matchAnnotation :: AsTmAnnotation ki ty pt tm
                => (Pattern pt a -> Term ki ty pt tm a -> Maybe [Term ki ty pt tm a])
                -> Pattern pt a
                -> Term ki ty pt tm a
                -> Maybe [Term ki ty pt tm a]
matchAnnotation matchFn pt tm = do
  (_, tmA) <- preview _TmAnnotation tm
  matchFn pt tmA

annotationEvalRules :: AnnotationEvalConstraint ki ty pt tm a
                    => EvalInput ki ty pt tm a
annotationEvalRules =
  EvalInput
    [ ValueRecurse valueAnnotation ]
    [ StepRecurse stepAnnotation ]
    [ MatchRecurse matchAnnotation ]


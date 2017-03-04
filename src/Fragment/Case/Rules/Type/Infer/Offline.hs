{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
module Fragment.Case.Rules.Type.Infer.Offline (
    CaseInferContext
  , caseInferRules
  ) where

import Control.Monad (replicateM)
import Data.Foldable (toList)

import Bound (instantiate)
import Bound.Scope (bindings)
import Control.Monad.Reader (MonadReader, local)
import Control.Monad.State (MonadState)
import Control.Monad.Writer (MonadWriter)
import Control.Monad.Trans (lift)
import Control.Lens (review, preview, (%~))
import Control.Lens.Wrapped (_Wrapped, _Unwrapped)

import Rules.Type.Infer.Offline
import Ast.Type
import Ast.Error.Common
import Ast.Pattern
import Ast.Term
import Ast.Term.Var
import Context.Term

import Fragment.Case.Ast.Error
import Fragment.Case.Ast.Warning
import Fragment.Case.Ast.Term

inferTmCase :: CaseInferContext e w s r m ki ty pt tm a
            => (Term ki ty pt tm a -> UnifyT ki ty a m (Type ki ty a))
            -> (Pattern pt a -> Type ki ty a -> UnifyT ki ty a m [Type ki ty a])
            -> Term ki ty pt tm a
            -> Maybe (UnifyT ki ty a m (Type ki ty a))
inferTmCase inferFn checkFn tm = do
  (tmC, alts) <- preview _TmCase tm
  return $ do
    let go ty (Alt p s) = do
          p' <- expectPattern p

          let vp = toList p'
          checkForDuplicatedPatternVariables vp
          let scopeBindings = bindings s
          lift $ checkForUnusedPatternVariables vp scopeBindings
          contextBindings <- lookupTermBindings
          -- this won't fire at the moment, because bound is taking care of shadowing for us
          -- we'll need to track a bit more info about the original form of the AST before this works
          lift $ checkForShadowingPatternVariables vp contextBindings

          vs <- replicateM (length p') freshTmVar
          tys <- checkFn p' ty
          let setup = foldr (.) id (zipWith insertTerm vs tys)

          let tm' = review _Wrapped .
                    instantiate (review (_Unwrapped . _TmVar) . (vs !!)) $
                    s
          local (termContext %~ setup) $ inferFn tm'
    tyC <- inferFn tmC
    tys <- mapM (go tyC) alts
    expectTypeAllEq tys

type CaseInferContext e w s r m ki ty pt tm a = (Ord a, AstBound ki ty pt tm, InferContext e w s r m ki ty pt tm a, MonadState s m, HasTmVarSupply s, ToTmVar a, MonadReader r m, HasTermContext r ki ty a, AsExpectedPattern e ki ty pt tm a, AsDuplicatedPatternVariables e a, MonadWriter [w] m, AsUnusedPatternVariables w a, AsShadowingPatternVariables w a, AsExpectedTypeAllEq e ki ty a, AsTmCase ki ty pt tm)

caseInferRules :: CaseInferContext e w s r m ki ty pt tm a
               => InferInput e w s r m ki ty pt tm a
caseInferRules =
  InferInput
    []
    [ InferPCheck inferTmCase ]
    []
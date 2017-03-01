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
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}
module Fragment.HM.Ast.Type (
    TyFHM
  , AsTyHM(..)
  ) where

import Data.Functor.Classes (showsBinaryWith)

import Bound (Bound(..))
import Control.Lens.Prism (Prism')
import Control.Lens.TH (makePrisms)
import Data.Deriving (deriveEq1, deriveOrd1, deriveShow1)

import Ast.Type
import Data.Bitransversable
import Data.Functor.Rec

data TyFHM f a =
  TyArrF (f a) (f a)
  deriving (Eq, Ord, Show, Functor, Foldable, Traversable)

deriveEq1 ''TyFHM
deriveOrd1 ''TyFHM
deriveShow1 ''TyFHM

makePrisms ''TyFHM

instance EqRec TyFHM where
  liftEqRec eR _ (TyArrF x1 y1) (TyArrF x2 y2) = eR x1 x2 && eR y1 y2

instance OrdRec TyFHM where
  liftCompareRec cR _ (TyArrF x1 y1) (TyArrF x2 y2) =
    case cR x1 x2 of
      EQ -> cR y1 y2
      x -> x

instance ShowRec TyFHM where
  liftShowsPrecRec sR _ _ _ n (TyArrF x y) =
    showsBinaryWith sR sR "TyArrF" n x y

instance Bound TyFHM where
  TyArrF x y >>>= f = TyArrF (x >>= f) (y >>= f)

instance Bitransversable TyFHM where
  bitransverse fT fL (TyArrF x y) = TyArrF <$> fT fL x <*> fT fL y

class AsTyHM ty where
  _TyHMP :: Prism' (ty k a) (TyFHM k a)

  _TyArr :: Prism' (Type ty a) (Type ty a, Type ty a)
  _TyArr = _TyTree . _TyHMP . _TyArrF

instance AsTyHM TyFHM where
  _TyHMP = id

instance {-# OVERLAPPABLE #-} AsTyHM (TySum xs) => AsTyHM (TySum (x ': xs)) where
  _TyHMP = _TyNext . _TyHMP

instance {-# OVERLAPPING #-} AsTyHM (TySum (TyFHM ': xs)) where
  _TyHMP = _TyNow . _TyHMP
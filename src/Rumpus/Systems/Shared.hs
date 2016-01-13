{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}
module Rumpus.Systems.Shared where
import Control.Monad.State
import Control.Monad.Reader
import Rumpus.Types
import Linear.Extra
import Control.Lens.Extra
import qualified Data.Map as Map
import Data.Maybe
import Graphics.GL.Pal
import Data.Foldable
setEntityColor :: (MonadState World m, MonadReader WorldStatic m) => V4 GLfloat -> EntityID -> m ()
setEntityColor newColor entityID = wldComponents . cmpColor . ix entityID .= newColor

useMaybeM_ :: (MonadState s m) => Lens' s (Maybe a) -> (a -> m b) -> m ()
useMaybeM_ aLens f = do
    current <- use aLens
    mapM_ f current



getEntityIDsWithName :: MonadState World m => String -> m [EntityID]
getEntityIDsWithName name = 
    Map.keys . Map.filter (== name) <$> use (wldComponents . cmpName)

getEntityName :: MonadState World m => EntityID -> m String
getEntityName entityID = fromMaybe "No Name" <$> use (wldComponents . cmpName . at entityID)

getEntityPose :: MonadState World m => EntityID -> m (Pose GLfloat)
getEntityPose entityID = fromMaybe newPose <$> use (wldComponents . cmpPose . at entityID)

traverseM :: (Monad m, Traversable t) => m (t a) -> (a -> m b) -> m (t b)
traverseM f x = f >>= traverse x

traverseM_ :: (Monad m, Foldable t) => m (t a) -> (a -> m b) -> m ()
traverseM_ f x = f >>= traverse_ x
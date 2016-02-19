{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
module Rumpus.Systems.Shared where
import PreludeExtra

import Data.ECS
import qualified Data.Map as Map

data ShapeType = CubeShape | SphereShape | StaticPlaneShape 
    deriving (Eq, Show, Ord, Enum, Generic, FromJSON, ToJSON)
defineComponentKey ''ShapeType


defineComponentKeyWithType "Name"   [t|String|]
defineComponentKeyWithType "Pose"   [t|Pose GLfloat|]
defineComponentKeyWithType "Size"   [t|V3 GLfloat|]
defineComponentKeyWithType "Color"  [t|V4 GLfloat|]
defineComponentKeyWithType "Parent" [t|EntityID|]
defineComponentKeyWithType "InheritParentTransform" [t|Bool|]

initSharedSystem :: MonadState ECS m => m ()
initSharedSystem = do
    registerComponent "Name" cmpName (defaultComponentInterface cmpName "New Entity")
    registerComponent "Pose" cmpPose (defaultComponentInterface cmpPose newPose)
    registerComponent "Size" cmpSize (defaultComponentInterface cmpSize (V3 1 1 1))
    registerComponent "Color" cmpColor (defaultComponentInterface cmpColor (V4 1 1 1 1))
    registerComponent "ShapeType" cmpShapeType (defaultComponentInterface cmpShapeType CubeShape)
    registerComponent "Parent" cmpParent $ (newComponentInterface cmpParent)
        { ciRemoveComponent = removeChildren
        }
    registerComponent "InheritParentTransform" cmpInheritParentTransform (newComponentInterface cmpInheritParentTransform)

removeChildren :: (MonadState ECS m, MonadReader EntityID m, MonadIO m) => m ()
removeChildren = do
    entityID <- ask
    forEntitiesWithComponent cmpParent $ \(childID, parentID) -> do
        when (parentID == entityID) $ 
            removeEntity childID

setEntityColor :: (MonadState ECS m, MonadIO m) => V4 GLfloat -> EntityID -> m ()
setEntityColor newColor entityID = setEntityComponent cmpColor newColor entityID

setColor :: (MonadReader EntityID m, MonadState ECS m, MonadIO m) => V4 GLfloat -> m ()
setColor newColor = setComponent cmpColor newColor


getEntityIDsWithName :: MonadState ECS m => String -> m [EntityID]
getEntityIDsWithName name = fromMaybe [] <$> withComponentMap cmpName (return . Map.keys . Map.filter (== name))

getEntityName :: MonadState ECS m => EntityID -> m String
getEntityName entityID = fromMaybe "No Name" <$> getEntityComponent entityID cmpName

getName :: (MonadReader EntityID m, MonadState ECS m) => m String
getName = getEntityName =<< ask

getEntityPose :: MonadState ECS m => EntityID -> m (Pose GLfloat)
getEntityPose entityID = fromMaybe newPose <$> getEntityComponent entityID cmpPose

getPose :: (MonadReader EntityID m, MonadState ECS m) => m (Pose GLfloat)
getPose = getEntityPose =<< ask

getEntitySize :: MonadState ECS m => EntityID -> m (V3 GLfloat)
getEntitySize entityID = fromMaybe 1 <$> getEntityComponent entityID cmpSize

getSize :: (MonadReader EntityID m, MonadState ECS m) => m (V3 GLfloat)
getSize = getEntitySize =<< ask

getEntityColor :: MonadState ECS m => EntityID -> m (V4 GLfloat)
getEntityColor entityID = fromMaybe 1 <$> getEntityComponent entityID cmpColor

getColor :: (MonadReader EntityID m, MonadState ECS m) => m (V4 GLfloat)
getColor = getEntityColor =<< ask

getEntityInheritParentTransform entityID = fromMaybe False <$> getEntityComponent entityID cmpInheritParentTransform
getInheritParentTransform entityID = getEntityInheritParentTransform =<< ask

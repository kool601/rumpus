{-# LANGUAGE FlexibleContexts #-}
module BuildTree where
import Rumpus

start :: OnStart
start = do
    removeChildren
    
    let branch parentID n pos = do
            childID <- spawnEntity Transient $ do
                cmpParent ==> parentID
                cmpPose   ==> mkTransformation (axisAngle (V3 0 0 1) 0.3) pos
                cmpShapeType              ==> SphereShape
                cmpPhysicsProperties      ==> [NoPhysicsShape]
                cmpInheritParentTransform ==> InheritFull
                cmpSize                   ==> V3 0.5 0.6 0.6
                cmpColor ==> hslColor (fromIntegral n/9) 0.8 0.5 1
                cmpOnUpdate ==> do
                    now <- sin <$> getNow
                    cmpPose ==> mkTransformation (axisAngle (V3 0 1 1) (now*2)) pos
            when (n > 0) $ do
                branch childID (n - 1) (V3 1 1 0)
                branch childID (n - 1) (V3 (-1) 1 0)
    rootEntityID <- ask
    branch rootEntityID (2::Int) (V3 0 1 0)
    return Nothing

{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE LambdaCase #-}

module Rumpus.Main where
import PreludeExtra

import Data.ECS

import Rumpus.Systems.Animation
import Rumpus.Systems.Attachment
import Rumpus.Systems.CodeEditor
import Rumpus.Systems.Collisions
import Rumpus.Systems.Constraint
import Rumpus.Systems.Controls
import Rumpus.Systems.Lifetime
import Rumpus.Systems.Physics
import Rumpus.Systems.Render
import Rumpus.Systems.SceneEditor
import Rumpus.Systems.Script
import Rumpus.Systems.Selection
import Rumpus.Systems.Shared
import Rumpus.Systems.Sound
import Rumpus.Systems.PlayPause

import Halive.Utils

main :: IO ()
-- main = withPd $ \pd -> do

main = do
    vrPal <- reacquire 0 $ initVRPal "Rumpus" [UseOpenVR]
    pd    <- reacquire 1 $ initLibPd
    
    args <- getArgs
    let sceneName = fromMaybe "default-scene" (listToMaybe args)

    void . flip runStateT newECS $ do 

        initAnimationSystem
        initAttachmentSystem
        initCodeEditorSystem
        initCollisionsSystem
        initConstraintSystem
        initControlsSystem vrPal
        initLifetimeSystem
        initPhysicsSystem
        initPlayPauseSystem
        initRenderSystem
        initSceneEditorSystem
        initScriptSystem
        initSoundSystem pd
        initSelectionSystem
        initSharedSystem

        loadScene sceneName

        let handColor = V4 0.6 0.6 0.9 1
        when (gpRoomScale vrPal == RoomScale) $ do
            _ <- spawnEntity Transient $ do
                cmpColor ==> handColor
                cmpSize  ==> V3 0.2 0.2 0.6
                cmpName  ==> "Left Hand"
                cmpPhysicsProperties ==> [IsKinematic, NoContactResponse]
            return ()
        _ <- spawnEntity Transient $ do
            cmpColor ==> handColor
            cmpSize  ==> V3 0.2 0.2 0.6
            cmpName  ==> "Right Hand"
            cmpPhysicsProperties ==> [IsKinematic, NoContactResponse]

        
        -- testEntity <- spawnEntity Transient $ return ()
        -- addCodeExpr testEntity "CollisionStart" "collisionStart" cmpOnCollisionStartExpr cmpOnCollisionStart
        
        -- selectEntity testEntity
        -- buildRecorderTestPatch

        whileVR vrPal $ \headM44 hands vrEvents -> do
            
            tickControlEventsSystem headM44 hands vrEvents
            tickCodeEditorSystem
            tickSyncCodeEditorSystem
            tickAttachmentSystem
            tickConstraintSystem
            tickScriptSystem
            tickLifetimeSystem
            tickAnimationSystem
            tickPhysicsSystem
            tickSyncPhysicsPosesSystem
            tickCollisionsSystem
            tickSceneEditorSystem
            tickSoundSystem headM44
            tickRenderSystem headM44




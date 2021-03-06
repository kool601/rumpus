module Rumpus.Systems.HandControls where
import PreludeExtra

import Rumpus.Systems.Drag
import Rumpus.Systems.Hands
import Rumpus.Systems.Physics
import Rumpus.Systems.Attachment
import Rumpus.Systems.Creator
import Rumpus.Systems.Haptics
import Rumpus.Systems.Teleport
import Rumpus.Systems.SceneWatcher
import Rumpus.Systems.CodeEditor
import Rumpus.Systems.Selection
import Rumpus.Systems.KeyPads
import Rumpus.Systems.Shared
import Rumpus.Systems.Animation


tickHandControlsSystem :: ECSMonad ()
tickHandControlsSystem = runUserScriptsWithTimeout_ $ do

    let editSceneWithHand whichHand handEntityID event = case event of
            HandStateEvent hand -> do
                -- Shift the hands down a bit, since OpenVR gives us the position
                -- of center of the controller's ring rather than its body
                let newHandPoseRaw = hand ^. hndMatrix
                    --handRotation = newHandPoseRaw ^. _m33
                    --handOffset = handRotation !* V3 0 0 0.05
                    --newHandPose = newHandPoseRaw & translation +~ handOffset
                    newHandPose = newHandPoseRaw
                --printIO whichHand
                --printIO newHandPose
                --setEntityPose handEntityID newHandPose
                setEntityPose handEntityID newHandPose
                continueDrag handEntityID
                continueHapticDrag whichHand newHandPose
                updateBeam whichHand
            HandButtonEvent HandButtonGrip ButtonDown ->
                beginBeam whichHand
            HandButtonEvent HandButtonGrip ButtonUp ->
                endBeam whichHand
            HandButtonEvent HandButtonTrigger ButtonDown ->
                initiateGrab whichHand handEntityID
            HandButtonEvent HandButtonTrigger ButtonUp -> do
                maybeHeldEntity <- getOneEntityAttachment handEntityID
                wasDestroyed    <- checkForDestruction whichHand

                endHapticDrag whichHand
                endDrag handEntityID
                detachAttachedEntities handEntityID

                forM_ maybeHeldEntity $ \entityID -> do
                    selectedEntityID <- getSelectedEntityID
                    if Just entityID == selectedEntityID && wasDestroyed
                        then do
                            clearSelection
                        else do
                            isPersistent <- isEntityPersistent entityID
                            when isPersistent $
                                sceneWatcherSaveEntity entityID

                handBecomeEthereal handEntityID
            HandButtonEvent HandButtonStart ButtonDown ->
                openEntityLibrary whichHand
            HandButtonEvent HandButtonStart ButtonUp ->
                closeCreator whichHand
            _ -> return ()

    leftHandID  <- getLeftHandID
    rightHandID <- getRightHandID
    withLeftHandEvents  (editSceneWithHand LeftHand leftHandID)
    withRightHandEvents (editSceneWithHand RightHand rightHandID)

handBecomeEthereal :: (MonadIO m, MonadState ECS m) => EntityID -> m ()
handBecomeEthereal handEntityID = do
    animateEntityColorTo handEntityID handColor 0.3
    animateEntitySizeTo handEntityID handSize 0.3
    setEntityBody handEntityID Detector

handBecomeSolid :: (MonadIO m, MonadState ECS m) => EntityID -> m ()
handBecomeSolid handEntityID = do
    animateEntityColorTo handEntityID (handColor * 0.9) 0.3
    animateEntitySizeTo handEntityID (handSize * 1.1) 0.3
    setEntityBody handEntityID Animated

filterUngrabbableEntityIDs :: MonadState ECS m => [EntityID] -> m [EntityID]
filterUngrabbableEntityIDs = filterM (fmap (notElem Ungrabbable) . getEntityBodyFlags)

getGrabbableEntityIDs :: EntityID -> ECSMonad [EntityID]
getGrabbableEntityIDs = filterUngrabbableEntityIDs <=< getEntityOverlappingEntityIDs

initiateGrab :: WhichHand -> EntityID -> ECSMonad ()
initiateGrab whichHand handEntityID = do
    -- Find the entities overlapping the hand, and attach them to it
    overlappingEntityIDs <- getGrabbableEntityIDs handEntityID

    if null overlappingEntityIDs then do
        clearSelection
        handBecomeSolid handEntityID
        --didPlaceCursor <- raycastCursor handEntityID

    else forM_ (listToMaybe overlappingEntityIDs) $ \grabbedID -> do
        handPose <- getEntityPose handEntityID
        beginHapticDrag whichHand handPose

        wantsToHandleDrag <- getEntityDragOverride grabbedID
        unless wantsToHandleDrag $
            grabEntity handEntityID grabbedID

        -- Call beginDrag after grabEntity so we can override selection if we want (i.e., call clearSelection)
        beginDrag handEntityID grabbedID

grabEntity :: (MonadIO m, MonadState ECS m) => EntityID -> EntityID -> m ()
grabEntity handEntityID grabbedID = do
    selectEntity grabbedID
    detachAttachedEntities handEntityID
    attachEntityToEntityAtCurrentOffset handEntityID grabbedID

--grabDuplicateEntity grabbedID otherHandEntityID = do
    --isBeingHeldByOtherHand <- isEntityAttachedTo grabbedID otherHandEntityID
    --when isBeingHeldByOtherHand $ do
    --    -- Trying things out with this disabled, as it's too
    --    -- easy to cause performance problems by effortlessly
    --    -- duplicating expensive objects. Effort to dupe should
    --    -- roughly scale with how often we want users to do it.
    --    let allowDuplication = False
    --    when allowDuplication $ do
    --        duplicateID <- duplicateEntity Persistent grabbedID
    --        --forkCode grabbedID duplicateID
    --        grabEntity handEntityID duplicateID
    --return isBeingHeldByOtherHand

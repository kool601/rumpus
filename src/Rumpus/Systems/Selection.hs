{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards #-}
module Rumpus.Systems.Selection where
import Data.ECS
import PreludeExtra

data Scene = Scene
    { _scnFolder :: !FilePath
    }
makeLenses ''Scene

scenesRoot :: FilePath
scenesRoot = "scenes"

newScene :: Scene
newScene = Scene 
    { _scnFolder = scenesRoot </> "NewScene"
    }

data SelectionSystem = SelectionSystem 
    { _selSelectedEntityID   :: !(Maybe EntityID) 
    , _selScene :: !Scene
    }
makeLenses ''SelectionSystem

defineSystemKey ''SelectionSystem

initSelectionSystem :: MonadState ECS m => m ()
initSelectionSystem = do
    registerSystem sysSelection (SelectionSystem Nothing newScene)


loadScene :: (MonadIO m, MonadState ECS m) => String -> m ()
loadScene sceneName = do
    let sceneFolder = scenesRoot </> sceneName
    printIO sceneFolder
    modifySystemState sysSelection (selScene . scnFolder .= sceneFolder)
    loadEntities sceneFolder

saveScene :: ECSMonad ()
saveScene = do
    sceneFolder <- viewSystem sysSelection (selScene . scnFolder)
    saveEntities sceneFolder

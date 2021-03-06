module Paint where
import Rumpus
import qualified Data.Sequence as Seq

maxBlots = 1000


start :: Start
start = do

    initialPosition <- getPosition
    setState (initialPosition, Seq.empty :: Seq EntityID)
    myDragContinues ==> \_ -> withState $ \(lastPosition, blots) -> do
        newPose <- getPose
        let newPosition = newPose ^. translation
        when (distance lastPosition newPosition > 0.05) $ do
            -- This paintbrush is persistent, via
            -- spawnPersistentEntity and sceneWatcherSaveEntity
            newBlot <- spawnPersistentEntity $ do
                myPose          ==> newPose
                myShape         ==> Cube
                mySize          ==> 0.1
                myTransformType ==> AbsolutePose
                myBody          ==> Animated
                myColor         ==> colorHSL
                    (newPosition ^. _x) 0.7 0.8
            sceneWatcherSaveEntity newBlot

            let (newBlots, oldBlots) = Seq.splitAt maxBlots blots
            forM_ oldBlots removeEntity
            setState (newPosition, newBlot <| newBlots)
module Door where
import Rumpus

dW, dH :: Num a => a
dH = 2
dW = 1
dD = 0.1

normalDoorColor = colorHSL 0.1 0.1 0.09

doorColorAnimDur = 0.3

startDoorTransitionAnimation = do
    removeComponent myShape

    doorColor <- getColor
    let cubeW = 0.1
    let xs = floor $ fromIntegral dW / cubeW
        ys = floor $ fromIntegral dH / cubeW

    let cubePositions = [V2 x y | x <- [0..xs - 1], y <- [0..ys - 1]]
        numCubes = fromIntegral $ length cubePositions
    forM_ (zip [0..] cubePositions) $ \(i, V2 xI yI) -> do
        n <- randomRange (0,1)
        let x = fromIntegral xI * cubeW - (dW / 2) + cubeW / 2
            y = fromIntegral yI * cubeW - (dH / 2) + cubeW / 2
        spawnChild $ do
            myPose  ==> position (V3 x y 0)
            mySize  ==> realToFrac cubeW
            myShape ==> Cube
            myColor ==> doorColor
            myStart ==> do
                setDelayedAction (0.5 * fromIntegral i / numCubes) $ do
                    -- Match hue with escape delay
                    animateColor doorColor (colorHSL n 0.3 0.5) doorColorAnimDur
                    setDelayedAction (doorColorAnimDur + realToFrac n) $ do
                        animatePositionTo (V3 x y -500) 1

start :: Start
start = do

    (maybeSceneName, sceneHue) <- getState (Just "Lobby", 0)

    myCodeHidden ==> True
    setShape Cube
    setSize $ V3 dW dH dD
    myBody ==> Animated
    myPose ==> positionRotation
        (V3 -1 1 0)
        (axisAngle (V3 0 1 0) (pi / 2))
    myColor ==> normalDoorColor

    -- A nothing scene name means this is the "New Scene" door
    -- so we pulse it!
    when (isNothing maybeSceneName) $ do
        myUpdate ==> do
            now <- getNow
            setColor (colorHSL now 0.3 0.8)

    doorID <- ask
    -- Plaque
    let plaqueH = dH * 0.3
    plaqueID <- spawnChild $ do
        mySize ==> 1
        myPose ==> position (V3 0 plaqueH 0)
    spawnChildOf plaqueID $ do
        myShape ==> Cube
        mySize  ==> V3 0.4 0.1 (dD + 0.01)
        myColor ==> colorHSL sceneHue 0.35 0.12
        myTransformType ==> RelativeFull
    spawnChildOf plaqueID $ do
        myText ==> fromMaybe "New Scene" maybeSceneName
        mySize ==> 0.05
        myPose ==> position $ V3 0 0 ((dD + 0.02) / 2)
        myTransformType ==> RelativeFull

    -- Knob
    let knobColor = colorHSL sceneHue 0.35 0.5
    doorKnob <- spawnChild $ do
        myShape        ==> Sphere
        mySize         ==> 0.1
        myBody         ==> Animated
        myColor        ==> knobColor
        myDragOverride ==> True
        myDragBegan    ==> do
            mSceneName <- case maybeSceneName of
                Just sceneName -> return $ Just sceneName
                Nothing        -> createNewScene
            forM_ mSceneName $ \sceneName -> do
                removeComponent myDragBegan
                inEntity doorID $ do

                    startDoorTransitionAnimation
                    inEntity plaqueID $ animateSizeOutTo0 doorColorAnimDur
                    setDelayedAction 1 $
                        transitionToSceneOverTime sceneName 1

    -- Knob shaft
    spawnChildOf doorKnob $ do
        myColor ==> knobColor
        mySize  ==> V3 0.02 0.02 0.1
        myPose  ==> position $ V3 0 0 -0.05
        myShape ==> Cube

    attachEntity doorKnob
        (position $ V3 (dW * 0.33) 0 (dD + 0.03))

    -- Door frame
    let fW = 0.1
        frameColor = colorHSL sceneHue 0.5 0.5
    spawnChild_ $ do
       myShape ==> Cube
       mySize  ==> V3 fW dH dD
       myPose  ==> position (V3 (dW / 2 + fW / 2) 0 0)
       myColor ==> frameColor

    spawnChild_ $ do
       myShape ==> Cube
       mySize  ==> V3 fW dH dD
       myPose  ==> position (V3 (-dW / 2 - fW / 2) 0 0)
       myColor ==> frameColor

    spawnChild_ $ do
       mySize  ==> V3 (dW + fW * 2) fW dD
       myPose  ==> position (V3 0 (dH/2 + fW / 2) 0)
       myColor ==> frameColor
       myShape ==> Cube

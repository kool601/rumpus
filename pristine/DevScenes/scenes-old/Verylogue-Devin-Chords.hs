{-# LANGUAGE FlexibleContexts #-}
module DefaultStart where
import Rumpus

majorScale = [0,2,4,5,7,9,11,12]
minorScale = [0,2,3,5,7,9,10,12]
chromaticScale = [0..12]

whiteKeys = [0,2,4,5,7,9,11,12]
blackKeys = [1,3,6,8,10]

chords = [[0,4,7],[0,5,9],[9,12,4],[11,4,7],[3,8,11]]

start :: Start
start = do
    removeChildren


    forM_ chromaticScale $ \n -> do
        let note = fromIntegral $ n + 60
        sendPd "piano-key" (List [note, 0])
    rootEntityID <- ask
    rootPose <- getPose
    forM_ (zip [0..] chords) $ \(i, chord) -> do
        forM_ (zip [0..] chord) $ \(j, note) -> do
            keyID <- spawnEntity $ do
                pianokey rootEntityID rootPose i j note
            attachEntity rootEntityID keyID False
    return Nothing

pianokey parentID parentPose i j noteDegree = do
    --let isMajor = elem noteDegree majorScale
    let note = fromIntegral $ noteDegree + 60
        x = (1/10) * fromIntegral i - 0.16 + 0.011 * fromIntegral j
        pose = V3 x 0.4 0
        hue  = fromIntegral i / fromIntegral (length majorScale)
        colorOn = hslColor hue 0.8 0.8
        colorOff = hslColor hue 0.8 0.4
    myColor ==> colorOff
    myParent            ==> parentID
    myShape         ==> Cube
    myProperties ==> [Floating, Ghostly]
    myPose              ==> parentPose !*! (identity & translation .~ pose)
    mySize              ==> V3 0.01 0.2 0.3
    myCollisionStart  ==> \_ _ -> do
        myColor ==> colorOn
        sendEntityPd parentID "piano-key" (List [note, 1])
    myCollisionEnd    ==> \_ -> do
        myColor ==> colorOff
        sendEntityPd parentID "piano-key" (List [note, 0])
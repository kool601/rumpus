module KeyPads where
import PreludeExtra

import Rumpus.Systems.Controls
import Rumpus.Systems.Hands
import Rumpus.Systems.Shared
import Rumpus.Systems.Physics
import Rumpus.Systems.Text
import Rumpus.Systems.Selection
import Rumpus.Systems.Animation
import Rumpus.Systems.Clock

import qualified Graphics.UI.GLFW.Pal as GLFW
import qualified Data.HashMap.Strict as Map

data HandKey = HandKeyChar Char Char
             | HandKeyEnter
             | HandKeyBackspace
             | HandKeyTab
             | HandKeyCut
             | HandKeyCopy
             | HandKeyPaste
             | HandKeyMoveLineUp
             | HandKeyMoveLineDown
             | HandKeyIndent
             | HandKeyUnIndent
             | HandKeyUp
             | HandKeyDown
             | HandKeyLeft
             | HandKeyRight
             | HandKeyShift
             | HandKeyBlank -- Just a spacer
             deriving (Eq, Show)

keyCapWidth :: HandKey -> Int
keyCapWidth  (HandKeyChar _ _)     = 1
keyCapWidth  HandKeyEnter          = 2
keyCapWidth  HandKeyShift          = 2
keyCapWidth  HandKeyBackspace      = 2
keyCapWidth  HandKeyTab            = 2
keyCapWidth  HandKeyCut            = 2
keyCapWidth  HandKeyCopy           = 2
keyCapWidth  HandKeyPaste          = 2
keyCapWidth  HandKeyMoveLineUp     = 2
keyCapWidth  HandKeyMoveLineDown   = 2
keyCapWidth  HandKeyIndent         = 2
keyCapWidth  HandKeyUnIndent       = 2
keyCapWidth  HandKeyUp             = 2
keyCapWidth  HandKeyDown           = 2
keyCapWidth  HandKeyLeft           = 2
keyCapWidth  HandKeyRight          = 2
keyCapWidth  HandKeyBlank          = 2


showKey :: Bool -> HandKey -> [Char]
showKey False (HandKeyChar unshifted _) = [unshifted]
showKey True  (HandKeyChar _ shifted)   = [shifted]
showKey _ HandKeyEnter                  = "Enter"
showKey _ HandKeyShift                  = "Shift"
showKey _ HandKeyBackspace              = "Backspace"
showKey _ HandKeyTab                    = "Tab"
showKey _ HandKeyCut                    = "Cut"
showKey _ HandKeyCopy                   = "Copy"
showKey _ HandKeyPaste                  = "Paste"
showKey _ HandKeyMoveLineUp             = "Line ^"
showKey _ HandKeyMoveLineDown           = "Line v"
showKey _ HandKeyIndent                 = "Indent"
showKey _ HandKeyUnIndent               = "Unindent"
showKey _ HandKeyUp                     = "^"
showKey _ HandKeyDown                   = "v"
showKey _ HandKeyLeft                   = "<"
showKey _ HandKeyRight                  = ">"
showKey _ HandKeyBlank                  = ""

keyToEvent :: Bool -> HandKey -> Maybe Event
--         shift                                                shift ctrl
keyToEvent shift HandKeyEnter              = Just (toPressedKey shift False Key'Enter)
keyToEvent shift HandKeyBackspace          = Just (toPressedKey shift False Key'Backspace)
keyToEvent shift HandKeyTab                = Just (toPressedKey shift False Key'Tab)
keyToEvent shift HandKeyUp                 = Just (toPressedKey shift False Key'Up)
keyToEvent shift HandKeyDown               = Just (toPressedKey shift False Key'Down)
keyToEvent shift HandKeyLeft               = Just (toPressedKey shift False Key'Left)
keyToEvent shift HandKeyRight              = Just (toPressedKey shift False Key'Right)
keyToEvent shift HandKeyIndent             = Just (toPressedKey shift True Key'RightBracket)
keyToEvent shift HandKeyUnIndent           = Just (toPressedKey shift True Key'LeftBracket)
keyToEvent _     HandKeyMoveLineUp         = Just (toPressedKey True  True Key'Up)
keyToEvent _     HandKeyMoveLineDown       = Just (toPressedKey True  True Key'Down)
keyToEvent _     HandKeyCut                = Just (toPressedKey False True Key'X)
keyToEvent _     HandKeyCopy               = Just (toPressedKey False True Key'C)
keyToEvent _     HandKeyPaste              = Just (toPressedKey False True Key'V)
keyToEvent False (HandKeyChar unshifted _) = Just (Character unshifted)
keyToEvent True  (HandKeyChar _ shifted)   = Just (Character shifted)
keyToEvent _ _ = Nothing

toPressedKey :: Bool -> Bool -> GLFW.Key -> Event
toPressedKey shift control key = KeyboardKey key noKeyCode KeyState'Pressed modifierKeys
    where
        -- (FIXME: we don't use keycodes anywhere, remove from API for now)
        noKeyCode = 0
        modifierKeys = GLFW.ModifierKeys shift control alt super
        (alt, super) = (False, False)


leftHandKeys :: [[HandKey]]
leftHandKeys =
    [ replicate 4 HandKeyUp
    , [HandKeyCut, HandKeyCopy, HandKeyPaste, HandKeyIndent, HandKeyUnIndent, HandKeyMoveLineUp, HandKeyMoveLineDown]
    , HandKeyLeft :                cs "`12345" "~!@#$%" ++ [HandKeyRight]
    , HandKeyLeft : HandKeyTab   : cs "qwert"  "QWERT"  ++ [HandKeyRight]
    , HandKeyLeft : HandKeyBlank : cs "asdfg"  "ASDFG"  ++ [HandKeyRight]
    , HandKeyLeft : HandKeyShift : cs "zxcvb"  "ZXCVB"  ++ [HandKeyRight]
    , replicate 4 (HandKeyChar ' ' ' ')
    , replicate 4 HandKeyDown
    ]
    where
        cs unshifted shifted = map (uncurry HandKeyChar) (zip unshifted shifted)

rightHandKeys :: [[HandKey]]
rightHandKeys =
    [ replicate 4 HandKeyUp
    , [HandKeyCut, HandKeyCopy, HandKeyPaste, HandKeyIndent, HandKeyUnIndent, HandKeyMoveLineUp, HandKeyMoveLineDown]
    , HandKeyLeft : cs "67890-="   "^&*()_+"  ++ [HandKeyBackspace,           HandKeyRight]
    , HandKeyLeft : cs "yuiop[]\\" "YUIOP{}|" ++ [                            HandKeyRight]
    , HandKeyLeft : cs "hjkl;'"    "HJKL:\""  ++ [HandKeyEnter, HandKeyEnter, HandKeyRight]
    , HandKeyLeft : cs "nm,./"     "NM<>?"    ++ [HandKeyShift,               HandKeyRight]
    , replicate 4 (HandKeyChar ' ' ' ')
    , replicate 4 HandKeyDown
    ]
    where
        cs unshifted shifted = map (uncurry HandKeyChar) (zip unshifted shifted)

keyWidth, keyHeight, keyDepth, keyPadding :: GLfloat
keyWidth        = 0.05
keyHeight       = 0.05
keyDepth        = 0.02
keyPadding      = 0.01

keyHeightT, keyWidthT :: GLfloat
keyWidthT       = keyWidth + keyPadding
keyHeightT      = keyHeight + keyPadding

keyColorOn, keyColorOff :: V4 GLfloat
keyColorOn               = colorHSL 0.2 0.8 0.8
keyColorOff              = colorHSL 0.3 0.8 0.4

-- How far up the keyboard appears
keyboardOffsetY, keyboardOffsetZ :: GLfloat
keyboardOffsetY = -0.2
-- How close the keyboard floats
keyboardOffsetZ = 0.1

data KeyPad = KeyPad
    { _kpdKeyPadID    :: EntityID
    , _kpdKeys        :: [KeyPadKey]
    , _kpdThumbNub    :: EntityID
    , _kpdKeyRepeater :: Maybe EntityID
    , _kpdDims        :: (V2 Float)
    , _kpdShiftDown   :: Bool
    , _kpdCurrentKey  :: Maybe HandKey
    , _kpdLastKey     :: Maybe HandKey
    }
data KeyPadKey = KeyPadKey
    { _kpkKeyID        :: EntityID
    , _kpkKey          :: HandKey
    , _kpkPointIsInKey :: V2 GLfloat -> Bool
    }
makeLenses ''KeyPadKey
makeLenses ''KeyPad

start :: ECSMonad ()
start = do

    -- Have hands write their key events to this entityID
    -- so we can pass them along on click to the InternalEvents channel
    let handsWithKeys = [ (LeftHand,  leftHandKeys,  V3 (-0.2) (-0.25) 0.1)
                        , (RightHand, rightHandKeys, V3   0.2  (-0.25) 0.1)
                        ]
    keyPadContainerID <- spawnEntity $ do
        myInheritTransform ==> InheritPose
        return ()
    keyPads <- forM handsWithKeys $ \(whichHand, keyRows, offset) -> do

        keyPadID         <- spawnEntity $ do
            myParent             ==> keyPadContainerID
            myInheritTransform   ==> InheritPose
            mySize               ==> 0.3
            myPose               ==> mkTransformation (axisAngle (V3 1 0 0) (pi/2)) offset
        scaleContainerID <- spawnEntity $ do
            myParent             ==> keyPadID
            myInheritTransform   ==> InheritFull


        -- Add the indicator of thumb position
        thumbNubID <- spawnEntity $ makeThumbNub scaleContainerID

        keyPadKeys <- spawnKeysForHand scaleContainerID keyRows

        let numRows    = fromIntegral (length keyRows)
            maxNumKeys = fromIntegral $ maximum (map length keyRows)
            keyPadDims = V2 (maxNumKeys * keyWidthT) (numRows * keyHeightT)
            keyPad = KeyPad
                { _kpdKeyPadID    = keyPadID
                , _kpdKeys        = keyPadKeys
                , _kpdKeyRepeater = Nothing
                , _kpdThumbNub    = thumbNubID
                , _kpdDims        = keyPadDims
                , _kpdShiftDown   = False
                , _kpdCurrentKey  = Nothing
                , _kpdLastKey     = Nothing
                }
        return (whichHand, keyPad)

spawnKeysForHand :: (MonadIO m, MonadState ECS m)
                 => EntityID
                 -> [[HandKey]]
                 -> m [KeyPadKey]
spawnKeysForHand containerID keyRows = do

    -- Spawn the keys and return their entityIDs
    fmap concat . forM (zip [0..] keyRows) $ \(y, keyRow) -> do
        let numKeys = fromIntegral (length keyRow)
            rowXCentering = -keyWidthT * (numKeys - 1) / 2
        forM (zip [0..] keyRow) $ \(x, key) -> do

            let (keyPose, pointIsInKey) = getKeyPose x y rowXCentering

            keyID <- spawnEntity $ makeKeyboardKey containerID key keyPose

            return KeyPadKey
                { _kpkKeyID        = keyID
                , _kpkKey          = key
                , _kpkPointIsInKey = pointIsInKey
                }

getKeyPose :: Int -> Int -> GLfloat -> (V3 GLfloat, V2 GLfloat -> Bool)
getKeyPose (fromIntegral -> x) (fromIntegral -> y) rowXCentering = (keyPose, pointIsInKey)
    where
        keyTopLeft            = keyXY - keyDimsT/2
        keyDimsT              = V2 keyWidthT keyHeightT
        pointIsInKey          = inRect keyTopLeft keyDimsT

        keyXY@(V2 keyX keyY)  = V2 (rowXCentering + x * keyWidthT) (keyboardOffsetY + y * keyHeightT)

        keyPose               = V3 keyX keyboardOffsetZ keyY



makeKeyboardKey :: (MonadState ECS m, MonadReader EntityID m) => EntityID -> HandKey -> V3 GLfloat -> m ()
makeKeyboardKey containerID key keyPosition = do
    let keyTitleScale         = 1 / (fromIntegral (length keyTitle))
        keyTitle              = showKey False key
    myParent                 ==> containerID
    myText                   ==> keyTitle
    myTextPose               ==> mkTransformation
                                      (axisAngle (V3 1 0 0) (-pi/2)) (V3 0 1 0)
                                    !*! scaleMatrix keyTitleScale
    myColor                  ==> keyColorOff
    myShape                  ==> Cube
    myProperties             ==> [Holographic]
    myPose                   ==> translateMatrix keyPosition
    mySize                   ==> V3 keyWidth keyDepth keyHeight
    myInheritTransform       ==> InheritPose


getThumbPos :: Hand -> V2 GLfloat
getThumbPos hand = hand ^. hndXY
    & _y  *~ (-1) -- y is flipped
    & _xy *~ 0.5  -- scale to -0.5 - 0.5

thumbPosInKeyboard :: Hand -> V2 GLfloat -> V3 GLfloat
thumbPosInKeyboard hand keyboardDims = V3 x keyboardOffsetZ offsetY
    where V2 x y  = getThumbPos hand * keyboardDims
          offsetY = y + keyboardOffsetY + keyboardDims ^. _y / 2 - (keyHeightT / 2)

-- | Create a ball that tracks the position of the thumb mapped to the position of the keys
makeThumbNub :: (MonadState ECS m, MonadReader EntityID m) => EntityID -> m ()
makeThumbNub containerID = do

    myParent           ==> containerID
    myColor            ==> keyColorOn
    myShape            ==> Sphere
    myProperties       ==> [Holographic]
    mySize             ==> realToFrac keyDepth * 2
    myInheritTransform ==> InheritPose

-- | Check if a point is in the given rectangle
inRect :: (Num a, Ord a) => V2 a -> V2 a -> V2 a -> Bool
inRect (V2 x y) (V2 w h) (V2 ptX ptY) =
    ptX > x && ptX < (x + w) && ptY > y && ptY < (y + h)

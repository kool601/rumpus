module NoteCollision where
import Rumpus

collision :: OnCollision
collision entityID _collidedID _impulse = do
    
    sendEntityPd entityID "trigger" (Atom 1)
    
    animation <- makeAnimation 0.2 (V4 1 0 1 1) (V4 1 1 1 1)
    wldComponents . cmpAnimationColor . at entityID ?= animation
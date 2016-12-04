import Control.Concurrent
import Control.Exception
-- import Control.Monad.Trans.Either
import Data.Map
import Network.Transport
import Network.Transport.UpHere (createTransport, defaultTCPParameters, DualHostPortPair(..))
import System.Environment

main :: IO ()
main = do
  [hostg,portg,hostl,portl]     <- getArgs
  let dhpp = DHPP (hostg,portg) (hostl,portl)
  serverDone      <- newEmptyMVar
  etransport <- createTransport dhpp defaultTCPParameters
  case etransport of
    Left err -> print err
    Right transport -> do
      eendpoint  <- newEndPoint transport
      case eendpoint of
        Left err' -> print err'
        Right endpoint -> do
          forkIO $ echoServer endpoint serverDone
          putStrLn $ "Echo server started at " ++ show (address endpoint)
          readMVar serverDone `onCtrlC` closeTransport transport
  
echoServer :: EndPoint -> MVar () -> IO ()
echoServer endpoint serverDone = go empty
  where
    go :: Map ConnectionId (MVar Connection) -> IO () 
    go cs = do
      event <- receive endpoint
      case event of
        ConnectionOpened cid rel addr -> do
          connMVar <- newEmptyMVar
          forkIO $ do
            Right conn <- connect endpoint addr rel defaultConnectHints
            putMVar connMVar conn 
          go (insert cid connMVar cs) 
        Received cid payload -> do
          forkIO $ do
            conn <- readMVar (cs ! cid)
            send conn payload 
            return ()
          go cs
        ConnectionClosed cid -> do 
          forkIO $ do
            conn <- readMVar (cs ! cid)
            close conn 
          go (delete cid cs) 
        EndPointClosed -> do
          putStrLn "Echo server exiting"
          putMVar serverDone ()

onCtrlC :: IO a -> IO () -> IO a
p `onCtrlC` q = catchJust isUserInterrupt p (const $ q >> p `onCtrlC` q)
  where
    isUserInterrupt :: AsyncException -> Maybe () 
    isUserInterrupt UserInterrupt = Just ()
    isUserInterrupt _             = Nothing


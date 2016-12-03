import Network.Transport
import Network.Transport.UpHere (createTransport, defaultTCPParameters)
import Control.Concurrent
import Data.Map
import Control.Exception
import System.Environment

main :: IO ()
main = do
  [host,port]     <- getArgs
  let dhpp = DHPP (host,port) (host,port)
  serverDone      <- newEmptyMVar
  Right transport <- createTransport dhpp defaultTCPParameters
  Right endpoint  <- newEndPoint transport
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


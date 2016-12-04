{-# LANGUAGE LambdaCase, OverloadedStrings #-}
module Main where

-- | Like Latency, but creating lots of channels

import           Control.Applicative
import           Control.Concurrent          (forkIO)
import           Control.Monad               (void,forM_,forever,replicateM_)
import           Control.Concurrent.MVar
import           Control.Concurrent          (forkOS,threadDelay)
import           Control.Concurrent.STM
import           Control.Applicative
import           Control.Distributed.Process
import           Control.Distributed.Process.Node
import           Data.Binary                 (encode,decode,Word32,Binary(..))
import           Data.ByteString             (ByteString)
import qualified Data.ByteString.Char8 as B
import           Network.Transport.UpHere    (createTransport,defaultTCPParameters
                                             ,DualHostPortPair(..))
import qualified Data.ByteString.Lazy  as BL
import           Network.Simple.TCP         
import           System.Environment
import           Text.Printf


packNumBytes :: B.ByteString -> B.ByteString
packNumBytes bstr =
  let len = (fromIntegral . B.length) bstr :: Word32
  in BL.toStrict (encode len)

packAndSend :: (Binary a) => Socket -> a -> IO ()
packAndSend sock x = do
  let msg = (BL.toStrict . encode) x
      sizebstr = packNumBytes msg
  Network.Simple.TCP.send sock sizebstr
  Network.Simple.TCP.send sock msg

broadcastProcessId :: ProcessId -> String -> IO ()
broadcastProcessId pid port = do
  serve HostAny port $ \(sock,addr) -> do
    putStrLn $ "TCP connection established from " ++ show addr
    packAndSend sock pid


broadcaster :: TVar Int -> Process ()
broadcaster var = forever $ do
  them <- expect
  say $ "got " ++ show them
  
  spawnLocal $ forever $ do
    
    liftIO $ threadDelay 1000000
    n <- liftIO $ readTVarIO var 
    sendChan them n

initialServer :: String -> TVar Int -> Process ()
initialServer port var = do
  us <- getSelfPid
  liftIO $ print us
  void . liftIO $ forkIO (broadcastProcessId us port)  
  spawnLocal $ forever $ liftIO $ do
    threadDelay 1000000
    atomically $ modifyTVar var (+1)
  
  -- liftIO $ BSL.writeFile "server.pid" (encode us)
  broadcaster var

main :: IO ()
main = do
    var <- newTVarIO 0
    [hostg,portg,hostl,portl,bcastport] <- getArgs
    let dhpp = DHPP (hostg,portg) (hostl,portl)
    Right transport <- createTransport dhpp defaultTCPParameters
    node <- newLocalNode transport initRemoteTable
    runProcess node (initialServer bcastport var)

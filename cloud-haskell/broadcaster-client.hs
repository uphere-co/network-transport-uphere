{-# LANGUAGE LambdaCase, OverloadedStrings #-}
module Main where

-- | Like Latency, but creating lots of channels

import System.Environment
import Control.Applicative
import Control.Monad (void, forM_, forever, replicateM_)
import Control.Concurrent.MVar
import Control.Concurrent (forkOS, threadDelay)
import Control.Applicative
import Control.Distributed.Process
import Control.Distributed.Process.Node
import Data.Binary (encode, decode,Binary(..),Word32)
import Data.ByteString.Char8 (pack)
import qualified Network.Simple.TCP       as NS
import           Network.Transport.UpHere        (createTransport, defaultTCPParameters, DualHostPortPair(..))
import qualified Data.ByteString.Lazy     as BL
import Text.Printf

recvAndUnpack :: Binary a => NS.Socket -> IO (Maybe a)
recvAndUnpack sock = do
  msizebstr <- NS.recv sock 4
  case msizebstr of
    Nothing -> return Nothing
    Just sizebstr -> do
      let s32 = (decode . BL.fromStrict) sizebstr :: Word32
          s = fromIntegral s32 :: Int
      mmsg <- NS.recv sock s
      case mmsg of
        Nothing -> return Nothing
        Just msg -> (return . Just . decode . BL.fromStrict) msg



subscriber :: ProcessId -> Process ()
subscriber them = do
    (sc, rc) <- newChan :: Process (SendPort Int, ReceivePort Int)
    send them sc
    forever $ do
      n <- receiveChan rc
      liftIO $ print n

{- 
initialClient :: ProcessId -> Process ()
initialClient them = do
  -- them <- liftIO $ decode <$> BSL.readFile "server.pid"
  subscriber them
-}

retrieveServerPid :: String -> String -> IO (Maybe ProcessId)
retrieveServerPid server port = do
  NS.connect server port $ \(sock,addr) -> do
    putStrLn $ "connection established to " ++ show addr
    recvAndUnpack sock

main :: IO ()
main = do
  [hostg,portg,hostl,portl,server,port] <- getArgs
  let dhpp = DHPP (hostg,portg) (hostl,portl)
  Right transport <- createTransport dhpp defaultTCPParameters
  node <- newLocalNode transport initRemoteTable
  mthem <- retrieveServerPid server port
  case mthem of
    Nothing -> putStrLn "no pid"
    Just them -> do
      print them
      runProcess node (subscriber them)

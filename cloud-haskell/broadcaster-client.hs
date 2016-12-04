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
import Data.Binary (encode, decode)
import Data.ByteString.Char8 (pack)
import Network.Transport.UpHere (createTransport, defaultTCPParameters, DualHostPortPair(..))
import qualified Data.ByteString.Lazy as BSL
import Text.Printf


subscriber :: ProcessId -> Process ()
subscriber them = do
    (sc, rc) <- newChan :: Process (SendPort Int, ReceivePort Int)
    send them sc
    forever $ do
      n <- receiveChan rc
      liftIO $ print n


initialClient :: Process ()
initialClient = do
  them <- liftIO $ decode <$> BSL.readFile "server.pid"
  subscriber them

main :: IO ()
main = do
  [hostg,portg,hostl,portl] <- getArgs
  let dhpp = DHPP (hostg,portg) (hostl,portl)    
  Right transport <- createTransport dhpp defaultTCPParameters
  node <- newLocalNode transport initRemoteTable
  runProcess node initialClient

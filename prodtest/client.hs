{-# LANGUAGE OverloadedStrings #-}

import Network.Transport
import Network.Transport.UpHere (createTransport, defaultTCPParameters)
import System.Environment
import Data.ByteString.Char8
import Control.Monad

main :: IO ()
main = do
  [host, port, serverAddr] <- getArgs
  let dhpp = DHPP (host,port) (host,port)
  Right transport <- createTransport dhpp defaultTCPParameters
  Right endpoint <- newEndPoint transport
  print (address endpoint)
  let addr = EndPointAddress (pack serverAddr)
  econn <- connect endpoint addr ReliableOrdered defaultConnectHints
  case econn of
    Left err -> print err
    Right conn  -> do
      send conn ["Hello world"]
      close conn
      replicateM_ 3 $ receive endpoint >>= print
  closeTransport transport

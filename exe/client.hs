{-# LANGUAGE OverloadedStrings #-}

import Network.Transport
import Network.Transport.UpHere (createTransport, defaultTCPParameters, DualHostPortPair(..))
import System.Environment
import Data.ByteString.Char8
import Control.Monad

main :: IO ()
main = do
  [hostg, portg, hostl, portl, serverAddr] <- getArgs
  let dhpp = DHPP (hostg,portg) (hostl,portl)
  etransport <- createTransport dhpp defaultTCPParameters
  case etransport of
    Left err -> print err
    Right transport -> do
      eendpoint <- newEndPoint transport
      case eendpoint of
        Left err' -> print err'
        Right endpoint -> do
          print (address endpoint)
          let addr = EndPointAddress (pack serverAddr)
          econn <- connect endpoint addr ReliableOrdered defaultConnectHints
          case econn of
            Left err'' -> print err''
            Right conn  -> do
              send conn ["Hello world"]
              close conn
              replicateM_ 3 $ receive endpoint >>= print
          closeTransport transport

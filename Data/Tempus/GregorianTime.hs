module Data.Tempus.GregorianTime
  ( -- * Type
    GregorianTime()
  -- * Creation
  , fromUnixTime
    -- * Low-Level
    -- ** Parsing
  , rfc3339Parser
    -- ** Rendering
  , rfc3339Builder
  ) where

import Control.Monad

import Debug.Trace

import Data.Int
import Data.Monoid
import Data.String

import Data.Attoparsec.ByteString ( parseOnly )

import qualified Data.ByteString as BS
import qualified Data.ByteString.Builder as BS
import qualified Data.ByteString.Lazy as BSL

import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL

import Data.Tempus.Class
import Data.Tempus.Rfc3339
import Data.Tempus.GregorianTime.Type
import Data.Tempus.GregorianTime.FromUnixTime
import Data.Tempus.GregorianTime.Rfc3339Parser
import Data.Tempus.GregorianTime.Rfc3339Builder
import Data.Tempus.UnixTime.Type
import Data.Tempus.RealtimeClock as RT

instance Rfc3339 GregorianTime where
  renderRfc3339ByteString
    = return . BSL.toStrict . BS.toLazyByteString . rfc3339Builder
  parseRfc3339ByteString s
    = case parseOnly rfc3339Parser s of
        Right t -> return t
        Left e  -> mzero

instance Show GregorianTime where
  -- The assumption is that every GregorianTime is valid and renderable as Rfc3339 string
  -- and rendering failure is impossible.
  show t
    = case renderRfc3339String t of
        Just s  -> s
        Nothing -> error $ "Invalid Date (this is a bug in the tempus library!)"

instance IsString GregorianTime where
  fromString s
    = case parseOnly rfc3339Parser (T.encodeUtf8 $ T.pack s) of
        Right s -> s
        Left  e -> error $ "Invalid Date '" ++ s ++ "'"

instance Tempus GregorianTime where
  now
    = do n <- RT.now
         case fromUnixTime (UnixTime n) of
           Nothing -> fail "tempus: 'now :: IO GregorianTime' failed"
           Just t  -> return t

  getYear gt
    = return (gdtYear gt)
  getMonth gt
    = return (gdtMonth gt)
  getDay gt
    = return (gdtDay gt)
  getHour gt
    = return (gdtMinutes gt `quot` 60)
  getMinute gt
    = return (gdtMinutes gt `rem` 60)
  getSecond gt
    = return (gdtMilliSeconds gt `quot` 1000)
  getMilliSecond gt
    = return (gdtMilliSeconds gt `rem` 1000)
  setYear x gt
    = validate $ gt { gdtYear = x }
  setMonth x gt
    = validate $ gt { gdtMonth = x }
  setDay x gt
    = validate $ gt { gdtDay = x }
  setHour x gt
    = validate $ gt { gdtMinutes = x*60 + (gdtMinutes gt `rem` 60) }
  setMinute x gt
    = validate $ gt { gdtMinutes = (gdtMinutes gt `quot` 60)*60 + x }
  setSecond x gt
    = validate $ gt { gdtMilliSeconds = x*1000 + (gdtMilliSeconds gt `rem` 1000) }
  setMilliSecond x gt
    = validate $ gt { gdtMilliSeconds = (gdtMilliSeconds gt `quot` 1000)*1000 + x }

{-# LANGUAGE StrictData #-}
{-# LANGUAGE UndecidableInstances #-}

{- |
    In-memory indexer backed by a list.

    See "Marconi.Core.Experiment" for documentation.
-}
module Marconi.Core.Experiment.Indexer.ListIndexer (
  ListIndexer,
  events,
  latest,
  listIndexer,
) where

import Control.Lens (makeLenses, view)

import Control.Lens.Operators ((%~), (&), (.~), (^.))
import Marconi.Core.Experiment.Class (
  Closeable (close),
  HasGenesis (genesis),
  IsIndex (index),
  IsSync (lastSyncPoint),
  Resetable (reset),
  Rollbackable (rollback),
 )
import Marconi.Core.Experiment.Type (Point, TimedEvent, point)

-- | The constructor is not exposed, use 'listIndexer' instead.
data ListIndexer event = ListIndexer
  { _events :: [TimedEvent event]
  -- ^ Stored @event@s, associated with their history 'Point'
  , _latest :: Point event
  -- ^ Ease access to the latest sync point
  }

deriving stock instance (Show event, Show (Point event)) => Show (ListIndexer event)

makeLenses ''ListIndexer

-- | A smart constructor for list indexer, starting at genesis with an empty list§.
listIndexer :: HasGenesis (Point event) => ListIndexer event
listIndexer = ListIndexer [] genesis

instance Monad m => IsIndex m event ListIndexer where
  index timedEvent ix =
    let appendEvent :: ListIndexer event -> ListIndexer event
        appendEvent = events %~ (timedEvent :)

        updateLatest :: ListIndexer event -> ListIndexer event
        updateLatest = latest .~ (timedEvent ^. point)
     in do
          pure $
            ix
              & appendEvent
              & updateLatest

instance Applicative m => IsSync m event ListIndexer where
  lastSyncPoint = pure . view latest

instance Applicative m => Rollbackable m event ListIndexer where
  rollback p ix =
    let adjustLatestPoint :: ListIndexer event -> ListIndexer event
        adjustLatestPoint = latest .~ p

        cleanEventsAfterRollback :: ListIndexer event -> ListIndexer event
        cleanEventsAfterRollback = events %~ dropWhile isEventAfterRollback

        isIndexBeforeRollback :: ListIndexer event -> Bool
        isIndexBeforeRollback x = x ^. latest < p

        isEventAfterRollback :: TimedEvent event -> Bool
        isEventAfterRollback x = x ^. point > p
     in pure $
          if isIndexBeforeRollback ix
            then ix -- if we're already before the rollback, we don't have to do anything
            else
              ix
                & cleanEventsAfterRollback
                & adjustLatestPoint

instance
  ( HasGenesis (Point event)
  , Applicative m
  )
  => Resetable m event ListIndexer
  where
  reset indexer =
    pure $
      indexer
        & events .~ mempty
        & latest .~ genesis

instance Applicative m => Closeable m ListIndexer where
  close = const $ pure ()

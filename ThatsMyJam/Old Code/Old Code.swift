//
//  Old Code.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/14/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//



// MediaManager Code - Not used well

//func getSongsWithCurrentAlbumFor(item: MPMediaItem) -> MPMediaQuery {
//  let albumFilter = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [albumFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  query.addFilterPredicate(albumFilter)
//  return query
//}
//
//
//func removeAlbumLockFor(item: MPMediaItem) -> MPMediaQuery {
//  let albumFilter = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [albumFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  query.removeFilterPredicate(albumFilter)
//  return query
//}
//
//
//func getSongsWithCurrentArtistFor(item: MPMediaItem) -> MPMediaQuery {
//  let artistFilter = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [artistFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  return query
//}
//
//
//func removeArtistLockFor(item: MPMediaItem) -> MPMediaQuery {
//  let artistFilter = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [artistFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  query.removeFilterPredicate(artistFilter)
//  return query
//}
//
//func getSongsWithCurrentGenreFor(item: MPMediaItem) -> MPMediaQuery {
//  let genreFilter = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [genreFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  return query
//}
//
//
//func removeGenreLockFor(item: MPMediaItem) -> MPMediaQuery {
//  let genreFilter = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: MPMediaPredicateComparison.equalTo)
//  let predicates: Set<MPMediaPropertyPredicate> = [genreFilter]
//  let query = MPMediaQuery(filterPredicates: predicates)
//  query.removeFilterPredicate(genreFilter)
//  return query
//}







// MediaPlayerVC Code Works but Not Dry

// GENRE

//let genrePredicate = MPMediaPropertyPredicate(value: nowPlaying.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: .contains)
//let genreQuery = MPMediaQuery()
//genreQuery.addFilterPredicate(genrePredicate)
//if var items = genreQuery.items {
//  items.shuffle()
//  mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//}
//
//
//
//let genrePredicate = MPMediaPropertyPredicate(value: nowPlaying.genre, forProperty: MPMediaItemPropertyGenre)
//let genreQuery = MPMediaQuery()
//genreQuery.removeFilterPredicate(genrePredicate)
//if var items = genreQuery.items {
//  items.shuffle()
//  mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//}

// ARTIST

//@IBAction func artistLockButtonTapped(_ sender: UIButton) {
//  if let nowPlaying = mediaPlayer.nowPlayingItem {
//    if sender.isSelected {
//      sender.isSelected = false
//      artistIsLocked = false
//      let artistUnlockedTrace = Performance.startTrace(name: "artistUnlockedTrace")
//      tappedLockLogic()
//      let artistPredicate = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
//      let artistQuery = MPMediaQuery()
//      artistQuery.removeFilterPredicate(artistPredicate)
//      if var items = artistQuery.items {
//        items.shuffle()
//        mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//      }
//      artistUnlockedTrace?.stop()
//    } else {
//      sender.isSelected = true
//      artistIsLocked = true
//      let artistLockedTrace = Performance.startTrace(name: "artistLockedTrace")
//      let artistPredicate = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
//      let artistQuery = MPMediaQuery()
//      artistQuery.addFilterPredicate(artistPredicate)
//      if var items = artistQuery.items {
//        items.shuffle()
//        mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//      }
//      artistLockedTrace?.stop()
//      tappedLockLogic()
//    }
//  }
//}

//@IBAction func albumLockButtonTapped(_ sender: UIButton) {
//  if let nowPlaying = mediaPlayer.nowPlayingItem {
//    if sender.isSelected {
//      sender.isSelected = false
//      albumIsLocked = false
//      let albumUnlockedTrace = Performance.startTrace(name: "albumUnlockedTrace")
//      tappedLockLogic()
//      let albumPredicate = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
//      let albumQuery = MPMediaQuery()
//      albumQuery.removeFilterPredicate(albumPredicate)
//      if var items = albumQuery.items {
//        items.shuffle()
//        mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//      }
//      albumUnlockedTrace?.stop()
//    } else {
//      sender.isSelected = true
//      albumIsLocked = true
//      let albumLockedTrace = Performance.startTrace(name: "albumLockedTrace")
//      let albumPredicate = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
//      let albumQuery = MPMediaQuery()
//      albumQuery.addFilterPredicate(albumPredicate)
//      if var items = albumQuery.items {
//        items.shuffle()
//        mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
//      }
//      albumLockedTrace?.stop()
//      tappedLockLogic()
//    }
//  }
//}


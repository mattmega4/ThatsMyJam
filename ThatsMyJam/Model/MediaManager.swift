//
//  MediaManager.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 2/2/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import MediaPlayer



class MediaManager: NSObject {
  
  static let shared = MediaManager()
  var playedSongs = [MPMediaItem]()
  var lockedSongs = [MPMediaItem]()
  
  // MARK: - Get All Song Logic
  
  
  func getAllSongs(completion: @escaping (_ songs: [MPMediaItem]?) -> Void) {
    MPMediaLibrary.requestAuthorization { (status) in
      if status == .authorized {
        let query = MPMediaQuery()
        let mediaTypeMusic = MPMediaType.music
        let audioFilter = MPMediaPropertyPredicate(value: mediaTypeMusic.rawValue, forProperty: MPMediaItemPropertyMediaType, comparisonType: MPMediaPredicateComparison.equalTo)
        query.addFilterPredicate(audioFilter)
        let songs = query.items?.filter({ (item) -> Bool in
          return item.mediaType == .music
        })
        completion(songs)
      } else {
        completion(nil)
      }
    }
  }
  
  
  // MARK: - Album Lock Logic
  
  func getSongsWithCurrentAlbumFor(item: MPMediaItem) -> MPMediaQuery {
    let albumFilter = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [albumFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    query.addFilterPredicate(albumFilter)
    return query
  }
  
  // MARK: - Artist Lock Logic
  
  func getSongsWithCurrentArtistFor(item: MPMediaItem) -> MPMediaQuery {
    let artistFilter = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [artistFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    return query
  }
  
  // MARK: - Genre Lock Logic
  
  func getSongsWithCurrentGenreFor(item: MPMediaItem) -> MPMediaQuery {
    let genreFilter = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [genreFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    return query
  }
  
  
  // MARK: - Remove Album Filter Logic
  
  func removeAlbumLockFor(item: MPMediaItem) -> MPMediaQuery {
    let albumFilter = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [albumFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    query.removeFilterPredicate(albumFilter)
    return query
  }
  
  // MARK: - Remove Artist Filter Logic
  
  func removeArtistLockFor(item: MPMediaItem) -> MPMediaQuery {
    let artistFilter = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [artistFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    query.removeFilterPredicate(artistFilter)
    return query
  }
  
  // MARK: - Remove Genre Filter Logic
  
  func removeGenreLockFor(item: MPMediaItem) -> MPMediaQuery {
    let genreFilter = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: MPMediaPredicateComparison.equalTo)
    let predicates: Set<MPMediaPropertyPredicate> = [genreFilter]
    let query = MPMediaQuery(filterPredicates: predicates)
    query.removeFilterPredicate(genreFilter)
    return query
  }
  
  // MARK: - Check if the songs should continue playing from the same genre, album or atrist
  
  func hasPlayedAllSongsFromAlbumFor(song: MPMediaItem) -> Bool {
    if song.albumTitle != nil {
      if let allSongsInAlbum = getSongsWithCurrentAlbumFor(item: song).items {
        return lockedSongsContains(songs: allSongsInAlbum)
      }
    }
    return true
  }
  
  func hasPlayedAllSongsFromArtistFor(song: MPMediaItem) -> Bool {
    if song.artist != nil {
      if let allSongsInArtist = getSongsWithCurrentArtistFor(item: song).items {
        return lockedSongsContains(songs: allSongsInArtist)
      }
    }
    return true
  }
  
  func hasPlayedAllSongsFromGenreFor(song: MPMediaItem) -> Bool {
    if song.genre != nil {
      if let allSongsInGenre = getSongsWithCurrentGenreFor(item: song).items {
        return lockedSongsContains(songs: allSongsInGenre)
      }
    }
    return true
  }
  
  func lockedSongsContains(songs: [MPMediaItem]) -> Bool {
    for aSong in songs {
      if !lockedSongs.contains(aSong) {
        return false
      }
    }
    return true
  }

}


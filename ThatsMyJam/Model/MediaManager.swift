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
  var albumQuery = MPMediaQuery(filterPredicates: nil)
  var artistQuery = MPMediaQuery(filterPredicates: nil)
  var genreQuery = MPMediaQuery(filterPredicates: nil)
  
  // MARK: - Get All Song Logic
  
  
  func getAllSongs(completion: @escaping (_ songs: [MPMediaItem]?) -> Void) {
    MPMediaLibrary.requestAuthorization { (status) in
      if status == .authorized {
//        let query = MPMediaQuery()

        let mediaTypeMusic = MPMediaType.music
        let audioFilter = MPMediaPropertyPredicate(value: mediaTypeMusic.rawValue, forProperty: MPMediaItemPropertyMediaType, comparisonType: MPMediaPredicateComparison.equalTo)
//        let query = MPMediaQuery()
        let query = MPMediaQuery(filterPredicates: [audioFilter])
        query.addFilterPredicate(audioFilter)
        let songs = query.items?.filter({ (item) -> Bool in
          //          return item.mediaType.rawValue == 1
          return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
        })
        completion(songs)
      } else {
        completion(nil)
      }
    }
  }



  // MARK: - Album Lock Logic
  
  func getSongsWithCurrentAlbumFor(item: MPMediaItem) -> MPMediaQuery {

    let artistPredicateWithin = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .contains)
    let albumPredicate = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)

    let compilationPredicate = MPMediaPropertyPredicate(value: item.isCompilation, forProperty: MPMediaItemPropertyIsCompilation)

    var myFilterSet: Set<MPMediaPropertyPredicate>
    var isComp: String
    if item.isCompilation == true {
       myFilterSet = [artistPredicateWithin, albumPredicate, compilationPredicate]
      isComp = "true"
    } else {
       myFilterSet = [artistPredicateWithin, albumPredicate]
      isComp = "false"
    }

    print(isComp)
//    let query = MPMediaQuery()
    var query = MPMediaQuery(filterPredicates: nil)
    query = MPMediaQuery(filterPredicates: myFilterSet)
    query.addFilterPredicate(albumPredicate)
    albumQuery = query
    return albumQuery
  }
  

  // MARK: - Remove Album Filter Logic
  
  func removeAlbumLockFor(item: MPMediaItem) -> MPMediaQuery {
    let albumPredicate = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
//    let query = MPMediaQuery()
    let query = MPMediaQuery(filterPredicates: nil)
    query.removeFilterPredicate(albumPredicate)
    albumQuery = query
//    albumQuery.removeFilterPredicate(albumPredicate)
//    return query
    return albumQuery
  }





  
  // MARK: - Artist Lock Logic
  
  func getSongsWithCurrentArtistFor(item: MPMediaItem) -> MPMediaQuery {
    let artistPredicate = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .contains)
//    let query = MPMediaQuery()
    let query = MPMediaQuery(filterPredicates: nil)
    query.addFilterPredicate(artistPredicate)
    artistQuery = query
    return artistQuery
  }
  
  // MARK: - Remove Artist Filter Logic
  
  func removeArtistLockFor(item: MPMediaItem) -> MPMediaQuery {
    let artistPredicate = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist)
//    let query = MPMediaQuery()
    let query = MPMediaQuery(filterPredicates: nil)
    query.removeFilterPredicate(artistPredicate)
    artistQuery = query
    return artistQuery
  }
  
  
  // MARK: - Genre Lock Logic
  
  func getSongsWithCurrentGenreFor(item: MPMediaItem) -> MPMediaQuery {
    let genrePredicate = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre, comparisonType: .contains)
//    let query = MPMediaQuery()
    let query = MPMediaQuery(filterPredicates: nil)
    query.addFilterPredicate(genrePredicate)
    genreQuery = query
    return genreQuery
  }

  // MARK: - Remove Genre Filter Logic
  
  func removeGenreLockFor(item: MPMediaItem) -> MPMediaQuery {
    let genrePredicate = MPMediaPropertyPredicate(value: item.genre, forProperty: MPMediaItemPropertyGenre)
//    let query = MPMediaQuery()
    let query = MPMediaQuery(filterPredicates: nil)
    query.removeFilterPredicate(genrePredicate)
    genreQuery = query
    return genreQuery
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


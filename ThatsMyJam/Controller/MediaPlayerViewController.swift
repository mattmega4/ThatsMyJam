//
//  MediaPlayerViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 2/2/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import FirebasePerformance

class MediaPlayerViewController: UIViewController {
  
  
  @IBOutlet weak var albumArtImageView: UIImageView!
  @IBOutlet weak var songProgressView: UIProgressView!
  @IBOutlet weak var songProgressSlider: UISlider!
  @IBOutlet weak var songTimePlayedLabel: UILabel!
  @IBOutlet weak var songTimeRemainingLabel: UILabel!
  @IBOutlet weak var songNameLabel: UILabel!
  @IBOutlet weak var songArtistLabel: UILabel!
  @IBOutlet weak var songAlbumLabel: UILabel!
  @IBOutlet weak var rewindSongButton: UIButton!
  @IBOutlet weak var playPauseSongButton: UIButton!
  @IBOutlet weak var forwardSongButton: UIButton!
  @IBOutlet weak var volumeLessIconImageView: UIImageView!
  @IBOutlet weak var volumeView: UIView!
  @IBOutlet weak var volumeMoreIconImageView: UIImageView!
  @IBOutlet weak var albumLockIconButton: UIButton!
  @IBOutlet weak var albumLockLabel: UILabel!
  @IBOutlet weak var artistLockIconButton: UIButton!
  @IBOutlet weak var artistLockLabel: UILabel!
  @IBOutlet weak var genreLockIconButton: UIButton!
  @IBOutlet weak var genreLockLabel: UILabel!
  
  var isPlaying = false
  var albumIsLocked = false
  var artistIsLocked = false
  var genreIsLocked = false
  var albumQuery: MPMediaQuery?
  var artistQuery: MPMediaQuery?
  var genreQuery: MPMediaQuery?
  var newSongs = [MPMediaItem]()
  var currentSong: MPMediaItem?
  let mediaPlayer = MPMusicPlayerApplicationController.systemMusicPlayer
  var songTimer: Timer?
  var firstLaunch = true
  var lastPlayedItem: MPMediaItem?
  var volumeControlView = MPVolumeView()
  var counter = 0
  var aSongIsInChamber = false
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mediaPlayer.beginGeneratingPlaybackNotifications()
    NotificationCenter.default.addObserver(self, selector: #selector(songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
    
    albumArtImageView.createRoundedCorners()
    setUpAudioPlayerAndGetSongsShuffled()
    clearSongInfo()
    songProgressSlider.addTarget(self, action: #selector(playbackSlider(_:)), for: .valueChanged)
    volumeControlView.showsVolumeSlider = true
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if volumeView.subviews.count == 0 {
      let myVolumeView = MPVolumeView(frame: volumeView.bounds)
      volumeView.addSubview(myVolumeView)
    }
  }
  
  
  // MARK: - Initial Audio Player setup Logic
  
  func setUpAudioPlayerAndGetSongsShuffled() {
    try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) //AVAudioSessionCategorySoloAmbient
    try? AVAudioSession.sharedInstance().setActive(true)
    
    MediaManager.shared.getAllSongs { (songs) in
      guard let theSongs = songs else {
        return
      }
      self.mediaPlayer.nowPlayingItem = nil
      DispatchQueue.main.async {
        self.clearSongInfo()
      }
      self.newSongs = theSongs.filter({ (item) -> Bool in
        return !MediaManager.shared.playedSongs.contains(item)
      })
      self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: self.newSongs.shuffled()))
      self.mediaPlayer.shuffleMode = .albums
      self.mediaPlayer.repeatMode = .none
      self.aSongIsInChamber = false
    }
  }
  
  
  // MARK: - Playback Slider
  
  @objc func playbackSlider(_ slider: UISlider) {
    if slider == songProgressSlider {
      mediaPlayer.currentPlaybackTime = Double(slider.value)
    }
  }
  
  @objc func songChanged(_ notification: Notification) {
    songProgressSlider.maximumValue = Float(mediaPlayer.nowPlayingItem?.playbackDuration ?? 0)
    songProgressSlider.minimumValue = 0
    songProgressSlider.value = 0
    songProgressView.progress = 0
    songTimePlayedLabel.text = getTimeElapsed()
    songTimeRemainingLabel.text = getTimeRemaining()
    
    if !firstLaunch {
      getCurrentlyPlayedInfo()
    } else {
      firstLaunch = false
    }
    rewindSongButton.isEnabled = mediaPlayer.indexOfNowPlayingItem != 0
    
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      
      if self.albumIsLocked || self.artistIsLocked || self.genreIsLocked {
        MediaManager.shared.lockedSongs.append(nowPlaying)
      }
      
      MediaManager.shared.playedSongs.append(nowPlaying)
      
      if albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) {
        albumLockButtonTapped(albumLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
      }
      if artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) {
        artistLockButtonTapped(artistLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
      }
      if genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
        genreLockButtonTapped(genreLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
      }
      
      if aSongIsInChamber == true {
        if nowPlaying.albumTitle != nil {
          if MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying).items?.count ?? 0 > 1 {
            albumLockIconButton.isEnabled = true
          }
        } else {
          albumLockIconButton.isEnabled = false
        }
        if nowPlaying.artist != nil {
          if MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying).items?.count ?? 0 > 1 {
            artistLockIconButton.isEnabled = true
          }
        } else {
          artistLockIconButton.isEnabled = false
        }
        if nowPlaying.genre != nil {
          if MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying).items?.count ?? 0 > 1 {
            genreLockIconButton.isEnabled = true
          }
        } else {
          genreLockIconButton.isEnabled = false
        }
      }
    }
  }
  
  
  
  func tappedLockLogic() {
    if !self.albumIsLocked && !self.artistIsLocked && !self.genreIsLocked {
      albumLockIconButton.isEnabled = true
      artistLockIconButton.isEnabled = true
      genreLockIconButton.isEnabled = true
    }
    if albumIsLocked {
      artistLockIconButton.isEnabled = false
      genreLockIconButton.isEnabled = false
    } else if artistIsLocked {
      albumLockIconButton.isEnabled = false
      genreLockIconButton.isEnabled = false
    } else if genreIsLocked {
      albumLockIconButton.isEnabled = false
      artistLockIconButton.isEnabled = false
    }
  }
  
  // MARK: - Reset Buttons and Labels
  
  func resetLockButtonsAndLabels() {
    self.albumLockIconButton.isSelected = false
    self.genreLockIconButton.isSelected = false
    self.albumLockIconButton.isSelected = false
    self.albumLockLabel.font = UIFont(name: "Gill Sans", size: 15.0)
    self.artistLockLabel.font = UIFont(name: "Gill Sans", size: 15.0)
    self.genreLockLabel.font = UIFont(name: "Gill Sans", size: 15.0)
    self.albumLockLabel.tintColor = UIColor.init(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    self.artistLockLabel.tintColor = UIColor.init(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    self.genreLockLabel.tintColor = UIColor.init(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
  }
  
  
  // MARK: - Clear Song Information
  
  func clearSongInfo() {
    albumArtImageView.image = #imageLiteral(resourceName: "lockedIconRed")
    songNameLabel.text = ""
    songArtistLabel.text = ""
    songAlbumLabel.text = ""
  }
  
  
  // MARK: - Get Song Information
  
  func getCurrentlyPlayedInfo() {
    DispatchQueue.main.async {
      if let songInfo = self.mediaPlayer.nowPlayingItem {
        self.songNameLabel.text = songInfo.title ?? ""
        self.songAlbumLabel.text = songInfo.albumTitle ?? ""
        self.songArtistLabel.text = songInfo.artist ?? ""
        self.albumArtImageView.image = songInfo.artwork?.image(at: CGSize(width: 400, height: 400)) ?? #imageLiteral(resourceName: "lockedIconRed")
      }
    }
  }
  
  
  // MARK: - Song Remaining & Duration Logic
  
  func getTimeRemaining() -> String {
    let secondsRemaining = songProgressSlider.maximumValue - songProgressSlider.value
    let minutes = Int(secondsRemaining / 60)
    let seconds = String(format: "%02d", Int(secondsRemaining - Float(60  * minutes)))
    return "\(minutes):\(seconds)"
  }
  
  func getTimeElapsed() -> String {
    let secondsElapsed = songProgressSlider.value
    let minutes = Int(secondsElapsed / 60)
    let seconds = String(format: "%02d", Int(secondsElapsed - Float(60  * minutes)))
    return "\(minutes):\(seconds)"
  }
  
  func updateCurrentPlaybackTime() {
    let elapsedTime = mediaPlayer.currentPlaybackTime
    songProgressSlider.value = Float(elapsedTime)
    songProgressView.progress = Float(elapsedTime / Double(songProgressSlider.maximumValue))
    songTimePlayedLabel.text = getTimeElapsed()
    songTimeRemainingLabel.text = getTimeRemaining()
  }
  
  
  // MARK: - IB Actions
  
  // MARK: - Song Control Button Actions
  
  @IBAction func rewindSongButtonTapped(_ sender: UIButton) {
    
    let secondsElapsed = songProgressSlider.value
    let minutes = Int(secondsElapsed / 60)
    let seconds = Int(secondsElapsed - Float(60  * minutes))
    if seconds < 5 {
      mediaPlayer.skipToPreviousItem()
    } else {
      mediaPlayer.skipToBeginning()
    }
    getCurrentlyPlayedInfo()
  }
  
  
  @IBAction func forwardSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        self.mediaPlayer.skipToNextItem()
      }
    })
    getCurrentlyPlayedInfo()
  }
  
  @IBAction func playPauseSongButtonTapped(_ sender: UIButton) {
    isPlaying = !isPlaying
    sender.isSelected = isPlaying
    if self.isPlaying {
      //      if self.mediaPlayer.playbackState != .playing {
      //        if self.mediaPlayer.isPreparedToPlay {
      //          DispatchQueue.main.async {
      //            self.mediaPlayer.play()
      //            self.aSongIsInChamber = true
      //          }
      //        } else {
      //          DispatchQueue.main.async {
      //            self.mediaPlayer.play()
      //            self.aSongIsInChamber = true
      //          }
      //        }
      //      }
      self.mediaPlayer.play()
    } else {
      //      if self.mediaPlayer.playbackState == .playing {
      self.mediaPlayer.pause()
      //      }
    }
    
    getCurrentlyPlayedInfo()
    if isPlaying {
      songTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
        DispatchQueue.main.async {
          self.updateCurrentPlaybackTime()
          self.getCurrentlyPlayedInfo()
        }
      })
    } else {
      songTimer?.invalidate()
    }
  }
  
  
  // MARK: - Smart Shuffle Button Actions
  
  @IBAction func albumLockButtonTapped(_ sender: UIButton) {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if sender.isSelected {
        sender.isSelected = false
        albumIsLocked = false
        tappedLockLogic()
        let albumPredicate = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
        let albumQuery = MPMediaQuery()
        albumQuery.removeFilterPredicate(albumPredicate)
        if var items = albumQuery.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
      } else {
        sender.isSelected = true
        albumIsLocked = true
        let albumPredicate = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
        let albumQuery = MPMediaQuery()
        albumQuery.addFilterPredicate(albumPredicate)
        mediaPlayer.setQueue(with: albumQuery)
        tappedLockLogic()
      }
    }
  }
  
  
  @IBAction func artistLockButtonTapped(_ sender: UIButton) {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if sender.isSelected {
        sender.isSelected = false
        artistIsLocked = false
        tappedLockLogic()
        let artistPredicate = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
        let artistQuery = MPMediaQuery()
        artistQuery.removeFilterPredicate(artistPredicate)
        mediaPlayer.setQueue(with: artistQuery)
      } else {
        sender.isSelected = true
        artistIsLocked = true
        let artistPredicate = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
        let artistQuery = MPMediaQuery()
        artistQuery.addFilterPredicate(artistPredicate)
        mediaPlayer.setQueue(with: artistQuery)
        tappedLockLogic()
      }
    }
  }
  
  
  @IBAction func genreLockButtonTapped(_ sender: UIButton) {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if sender.isSelected {
        sender.isSelected = false
        genreIsLocked = false
        tappedLockLogic()
        let genrePredicate = MPMediaPropertyPredicate(value: nowPlaying.genre, forProperty: MPMediaItemPropertyGenre)
        let genreQuery = MPMediaQuery()
        genreQuery.removeFilterPredicate(genrePredicate)
        mediaPlayer.setQueue(with: genreQuery)
      } else {
        sender.isSelected = true
        genreIsLocked = true
        let genrePredicate = MPMediaPropertyPredicate(value: nowPlaying.genre, forProperty: MPMediaItemPropertyGenre)
        let genreQuery = MPMediaQuery()
        genreQuery.addFilterPredicate(genrePredicate)
        mediaPlayer.setQueue(with: genreQuery)
        tappedLockLogic()
      }
    }
  }
  
}



// MARK: - AVAudioPlayerDelegate Extension

extension MediaPlayerViewController: AVAudioPlayerDelegate {
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    print("error")
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print("finished playing")
    
  }
  
}


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
import FirebaseAnalytics

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
  //  let mediaPlayer = MPMusicPlayerApplicationController.systemMusicPlayer //applicationQueuePlayer
  let mediaPlayer = MPMusicPlayerController.systemMusicPlayer
  var songTimer: Timer?
  var firstLaunch = true
  var lastPlayedItem: MPMediaItem?
  var volumeControlView = MPVolumeView()
  var counter = 0
  var aSongIsInChamber = false
  var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    DispatchQueue.main.async {
      
      NotificationCenter.default.addObserver(self, selector: #selector(self.songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: self.mediaPlayer)
      self.mediaPlayer.beginGeneratingPlaybackNotifications()
    }
    
    ///
//    NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    //
    
    
    albumArtImageView.createRoundedCorners()
    songProgressSlider.addTarget(self, action: #selector(playbackSlider(_:)), for: .valueChanged)
    volumeControlView.showsVolumeSlider = true
    showReview()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if volumeView.subviews.count == 0 {
      let myVolumeView = MPVolumeView(frame: volumeView.bounds)
      volumeView.addSubview(myVolumeView)
    }
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    clearSongInfo()
    setUpAudioPlayerAndGetSongsShuffled()
  }
  
  // MARK: - Background Tasks
  
//  func registerBackgroundTask() {
//    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
//      self?.endBackgroundTask()
//    }
//    assert(backgroundTask != UIBackgroundTaskInvalid)
//  }
//
//  func endBackgroundTask() {
//    print("Background task ended.")
//    UIApplication.shared.endBackgroundTask(backgroundTask)
//    backgroundTask = UIBackgroundTaskInvalid
//  }
//
//  @objc func reinstateBackgroundTask() {
//    if backgroundTask == UIBackgroundTaskInvalid {
//      registerBackgroundTask()
//    }
//  }
  
  ///
  
  
  // MARK: - Initial Audio Player setup Logic
  
  func setUpAudioPlayerAndGetSongsShuffled() {
    try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
    try? AVAudioSession.sharedInstance().setActive(true)
    
    let setupTrace = Performance.startTrace(name: "setupTrace")
    
    DispatchQueue.main.async {
      self.clearSongInfo()
      MediaManager.shared.getAllSongs { (songs) in
        guard let theSongs = songs else {
          return
        }
        self.mediaPlayer.nowPlayingItem = nil
        
        self.newSongs = theSongs.filter({ (item) -> Bool in
          return !MediaManager.shared.playedSongs.contains(item)
        })
        self.aSongIsInChamber = true
        self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: self.newSongs.shuffled()))
        self.mediaPlayer.shuffleMode = .songs
        self.mediaPlayer.repeatMode = .none
        
        setupTrace?.stop()
      }
    }
  }
  
  
  // MARK: - Playback Slider
  
  @objc func playbackSlider(_ slider: UISlider) {
    DispatchQueue.main.async {
      if slider == self.songProgressSlider {
        self.mediaPlayer.currentPlaybackTime = Double(slider.value)
      }
    }
  }
  
  @objc func songChanged(_ notification: Notification) {
    DispatchQueue.main.async {
      self.songProgressSlider.maximumValue = Float(self.mediaPlayer.nowPlayingItem?.playbackDuration ?? 0)
      self.songProgressSlider.minimumValue = 0
      self.songProgressSlider.value = 0
      self.songProgressView.progress = 0
      self.songTimePlayedLabel.text = self.getTimeElapsed()
      self.songTimeRemainingLabel.text = self.getTimeRemaining()

      
      if !self.firstLaunch {
        self.getCurrentlyPlayedInfo()
      } else {
        self.firstLaunch = false
      }
      self.rewindSongButton.isEnabled = self.mediaPlayer.indexOfNowPlayingItem != 0
      self.checkIfLocksShouldBeEnabled()
      self.checkIfSongHasPlayedAllInLock()
    }
  }
  
  func checkIfSongHasPlayedAllInLock() {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        
        if self.albumIsLocked || self.artistIsLocked || self.genreIsLocked {
          MediaManager.shared.lockedSongs.append(nowPlaying)
        }
        MediaManager.shared.playedSongs.append(nowPlaying)
        
        if self.albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) {
          self.albumLockButtonTapped(self.self.albumLockIconButton)
          MediaManager.shared.lockedSongs.removeAll()
          Analytics.logEvent("albumTriggeredUnlocked", parameters: nil)
        }
        if self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) {
          self.artistLockButtonTapped(self.artistLockIconButton)
          MediaManager.shared.lockedSongs.removeAll()
          Analytics.logEvent("artistTriggeredUnlocked", parameters: nil)
        }
        if self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
          self.genreLockButtonTapped(self.genreLockIconButton)
          MediaManager.shared.lockedSongs.removeAll()
          Analytics.logEvent("genreTriggeredUnlocked", parameters: nil)
        }
      }
    }}
  
  func checkIfLocksShouldBeEnabled() {
    albumLockIconButton.isEnabled = true
    artistLockIconButton.isEnabled = true
    genreLockIconButton.isEnabled = true
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if self.aSongIsInChamber == true {
          if nowPlaying.albumTitle != nil {
            if MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying).items?.count ?? 0 < 2 {
              self.albumLockIconButton.isEnabled = false
            }
          } else {
            self.self.albumLockIconButton.isEnabled = true
          }
          if nowPlaying.artist != nil {
            if MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying).items?.count ?? 0 < 2 {
              self.artistLockIconButton.isEnabled = false
            }
          } else {
            self.artistLockIconButton.isEnabled = true
          }
          if nowPlaying.genre != nil {
            if MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying).items?.count ?? 0 < 2 {
              self.genreLockIconButton.isEnabled = false
            }
          } else {
            self.genreLockIconButton.isEnabled = true
          }
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
    DispatchQueue.main.async {
      self.albumArtImageView.image = #imageLiteral(resourceName: "emptyArtworkImage")
      self.songNameLabel.text = ""
      self.songArtistLabel.text = ""
      self.songAlbumLabel.text = ""
    }
  }
  
  
  // MARK: - Get Song Information
  
  func getCurrentlyPlayedInfo() {
    DispatchQueue.main.async {
      if let songInfo = self.mediaPlayer.nowPlayingItem {
        self.songNameLabel.text = songInfo.title ?? ""
        self.songAlbumLabel.text = songInfo.albumTitle ?? ""
        self.songArtistLabel.text = songInfo.artist ?? ""
        self.albumArtImageView.image = songInfo.artwork?.image(at: CGSize(width: 400, height: 400)) ?? #imageLiteral(resourceName: "emptyArtworkImage")
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
    let localizedMinutes = NSLocalizedString("\(minutes)", comment: "minutes")
    let localizedSeconds = NSLocalizedString("\(seconds)", comment: "seconds")
    return "\(localizedMinutes):\(localizedSeconds)"
  }
  
  func updateCurrentPlaybackTime() {
    let elapsedTime = mediaPlayer.currentPlaybackTime
    songProgressSlider.value = Float(elapsedTime)
    songProgressView.progress = Float(elapsedTime / Double(songProgressSlider.maximumValue))
    songTimePlayedLabel.text = getTimeElapsed()
    songTimeRemainingLabel.text = getTimeRemaining()
    
    

    print(Int(self.songProgressSlider.maximumValue - self.songProgressSlider.value))
    if Int(self.songProgressSlider.maximumValue - self.songProgressSlider.value) < 1 {
      print("song ended naturally, skipped")
      mediaPlayer.prepareToPlay(completionHandler: { (error) in
        DispatchQueue.main.async {
          self.mediaPlayer.skipToNextItem()
        }
      })
    }
    
    ////
//    switch UIApplication.shared.applicationState {
//    case .active:
//      print("active")
//    case .background:
//      print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
//    case .inactive:
//      break
//    }
    /////
  }
  

  
  
  // MARK: - IB Actions
  
  // MARK: - Song Control Button Actions
  
  @IBAction func rewindSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        let secondsElapsed = self.songProgressSlider.value
        let minutes = Int(secondsElapsed / 60)
        let seconds = Int(secondsElapsed - Float(60  * minutes))
        if seconds < 5 {
          self.mediaPlayer.skipToPreviousItem()
        } else {
          self.mediaPlayer.skipToBeginning()
        }
      }
    })
    
    
    //    let secondsElapsed = songProgressSlider.value
    //    let minutes = Int(secondsElapsed / 60)
    //    let seconds = Int(secondsElapsed - Float(60  * minutes))
    //    if seconds < 5 {
    //      mediaPlayer.skipToPreviousItem()
    //    } else {
    //      mediaPlayer.skipToBeginning()
    //    }
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
      self.mediaPlayer.prepareToPlay { error in
        DispatchQueue.main.async {
          self.mediaPlayer.play()
        }
      }
    } else {
      DispatchQueue.main.async {
        self.mediaPlayer.pause()
      }
    }
    
    getCurrentlyPlayedInfo()
    if isPlaying {
      let app = UIApplication.shared
      var task: UIBackgroundTaskIdentifier?
      task  = app.beginBackgroundTask {
        app.endBackgroundTask(task!)
      }
      songTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
        DispatchQueue.main.async {
          self.updateCurrentPlaybackTime()
          //          self.getCurrentlyPlayedInfo()
        }
      })
      DispatchQueue.main.async {
        self.getCurrentlyPlayedInfo()
      }
    } else {
      songTimer?.invalidate()
    }
  }
  
  
  // MARK: - Smart Shuffle Button Actions
  
  @IBAction func albumLockButtonTapped(_ sender: UIButton) {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if sender.isSelected {
          sender.isSelected = false
          self.albumIsLocked = false
          let albumUnlockedTrace = Performance.startTrace(name: "albumUnlockedTrace")
          Analytics.logEvent("albumTapUnlocked", parameters: nil)
          self.tappedLockLogic()
          //          let removeAlbumLock = MediaManager.shared.removeAlbumLockFor(item: nowPlaying)
          //          if var items = removeAlbumLock.items {
          //            items.shuffle()
          //            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          //          }
          let albumPredicate: MPMediaPropertyPredicate  = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
          let query: MPMediaQuery = MPMediaQuery.albums()
          let musicPlayerController: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer
          
          query.removeFilterPredicate(albumPredicate)
          musicPlayerController.setQueue(with: query)
          albumUnlockedTrace?.stop()
        } else {
          sender.isSelected = true
          self.albumIsLocked = true
          let albumLockedTrace = Performance.startTrace(name: "albumLockedTrace")
          Analytics.logEvent("albumTapLocked", parameters: ["album": nowPlaying.albumTitle ?? "Album Title"])
          //          let albumLock = MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying)
          //          if var items = albumLock.items {
          //            items.shuffle()
          //            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          //          }
          let albumPredicate: MPMediaPropertyPredicate  = MPMediaPropertyPredicate(value: nowPlaying.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
          let query: MPMediaQuery = MPMediaQuery.albums()
          let musicPlayerController: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer
          
          query.addFilterPredicate(albumPredicate)
          musicPlayerController.setQueue(with: query)
          albumLockedTrace?.stop()
          self.tappedLockLogic()
        }
      }
    }
  }
  
  
  @IBAction func artistLockButtonTapped(_ sender: UIButton) {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if sender.isSelected {
          sender.isSelected = false
          self.artistIsLocked = false
          let artistUnlockedTrace = Performance.startTrace(name: "artistUnlockedTrace")
          Analytics.logEvent("artistTapUnlocked", parameters: nil)
          self.tappedLockLogic()
          //          let unlockArtist = MediaManager.shared.removeArtistLockFor(item: nowPlaying)
          //          if var items = unlockArtist.items {
          //            items.shuffle()
          //            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          //          }
          let artistPredicate: MPMediaPropertyPredicate  = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
          let query: MPMediaQuery = MPMediaQuery.artists()
          let musicPlayerController: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer
          
          query.removeFilterPredicate(artistPredicate)
          musicPlayerController.setQueue(with: query)
          artistUnlockedTrace?.stop()
        } else {
          sender.isSelected = true
          self.artistIsLocked = true
          let artistLockedTrace = Performance.startTrace(name: "artistLockedTrace")
          Analytics.logEvent("artistTapLocked", parameters: ["artist": nowPlaying.artist ?? "Artist"])
          //          let artistLock = MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying)
          //          if var items = artistLock.items {
          //            items.shuffle()
          //            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          //          }
          let artistPredicate: MPMediaPropertyPredicate  = MPMediaPropertyPredicate(value: nowPlaying.artist, forProperty: MPMediaItemPropertyArtist)
          let query: MPMediaQuery = MPMediaQuery.artists()
          let musicPlayerController: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer
          
          query.addFilterPredicate(artistPredicate)
          musicPlayerController.setQueue(with: query)
          
          artistLockedTrace?.stop()
          self.tappedLockLogic()
        }
      }
    }
  }
  
  
  @IBAction func genreLockButtonTapped(_ sender: UIButton) {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if sender.isSelected {
          sender.isSelected = false
          self.genreIsLocked = false
          let genreUnlockedTrace = Performance.startTrace(name: "genreUnlockedTrace")
          Analytics.logEvent("genreTapUnlocked", parameters: nil)
          self.tappedLockLogic()
          let genreUnlocked = MediaManager.shared.removeGenreLockFor(item: nowPlaying)
          if var items = genreUnlocked.items {
            items.shuffle()
            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          }
          genreUnlockedTrace?.stop()
        } else {
          sender.isSelected = true
          self.genreIsLocked = true
          let genreLockedTrace = Performance.startTrace(name: "genreLockedTrace")
          Analytics.logEvent("genreTapLocked", parameters: ["genre": nowPlaying.genre ?? "Genre"])
          let genreLocked = MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying)
          if var items = genreLocked.items {
            items.shuffle()
            self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
          }
          genreLockedTrace?.stop()
          self.tappedLockLogic()
        }
      }
    }
  }
  
}



// MARK: - AVAudioPlayerDelegate Extension


extension MediaPlayerViewController: AVAudioPlayerDelegate {
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    Analytics.logEvent("audioPlayerDecodeErrorDidOccur", parameters: ["error": error?.localizedDescription ?? "error"])
    print("error")
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Analytics.logEvent("audioPlayerDidFinishPlaying", parameters: nil)
    print("finished playing")
    
  }
  
}


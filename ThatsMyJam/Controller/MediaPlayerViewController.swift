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
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mediaPlayer.beginGeneratingPlaybackNotifications()
    NotificationCenter.default.addObserver(self, selector: #selector(songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
    
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
  
  // MARK: - Initial Audio Player setup Logic
  
  func setUpAudioPlayerAndGetSongsShuffled() {
    try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
    try? AVAudioSession.sharedInstance().setActive(true)
    
    let setupTrace = Performance.startTrace(name: "setupTrace")
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
      self.aSongIsInChamber = true
      self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: self.newSongs.shuffled()))
//      self.mediaPlayer.prepareToPlay()
//      self.mediaPlayer.stop()
      self.mediaPlayer.shuffleMode = .songs
      self.mediaPlayer.repeatMode = .none
      setupTrace?.stop()
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
    checkIfLocksShouldBeEnabled()
    checkIfSongHasPlayedAllInLock()
  }
  
  func checkIfSongHasPlayedAllInLock() {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      
      if self.albumIsLocked || self.artistIsLocked || self.genreIsLocked {
        MediaManager.shared.lockedSongs.append(nowPlaying)
      }
      
      MediaManager.shared.playedSongs.append(nowPlaying)
      
      if albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) {
        albumLockButtonTapped(albumLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
        Analytics.logEvent("albumTriggeredUnlocked", parameters: nil)
      }
      if artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) {
        artistLockButtonTapped(artistLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
        Analytics.logEvent("artistTriggeredUnlocked", parameters: nil)
      }
      if genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
        genreLockButtonTapped(genreLockIconButton)
        MediaManager.shared.lockedSongs.removeAll()
        Analytics.logEvent("genreTriggeredUnlocked", parameters: nil)
      }
      print(aSongIsInChamber)
      
    }
    
  }
  
  func checkIfLocksShouldBeEnabled() {
    albumLockIconButton.isEnabled = true
    artistLockIconButton.isEnabled = true
    genreLockIconButton.isEnabled = true
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if aSongIsInChamber == true {
        if nowPlaying.albumTitle != nil {
          if MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying).items?.count ?? 0 < 2 {
            albumLockIconButton.isEnabled = false
          }
        } else {
          albumLockIconButton.isEnabled = true
        }
        if nowPlaying.artist != nil {
          if MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying).items?.count ?? 0 < 2 {
            artistLockIconButton.isEnabled = false
          }
        } else {
          artistLockIconButton.isEnabled = true
        }
        if nowPlaying.genre != nil {
          if MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying).items?.count ?? 0 < 2 {
            genreLockIconButton.isEnabled = false
          }
        } else {
          genreLockIconButton.isEnabled = true
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
    albumArtImageView.image = #imageLiteral(resourceName: "emptyArtworkImage")
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
//    mediaPlayer.prepareToPlay(completionHandler: { (error) in
//      DispatchQueue.main.async {
//        self.mediaPlayer.skipToNextItem()
//      }
//    })
    self.mediaPlayer.skipToNextItem()
    getCurrentlyPlayedInfo()
  }
  
  @IBAction func playPauseSongButtonTapped(_ sender: UIButton) {
    isPlaying = !isPlaying
    sender.isSelected = isPlaying
    if self.isPlaying {
      self.mediaPlayer.prepareToPlay { error in
        self.mediaPlayer.play()
      }
    } else {
      self.mediaPlayer.pause()
    }
    
    getCurrentlyPlayedInfo()
    if isPlaying {
      songTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
        DispatchQueue.main.async {
          self.updateCurrentPlaybackTime()
//          self.getCurrentlyPlayedInfo()
        }
      })
      self.getCurrentlyPlayedInfo()
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
        let albumUnlockedTrace = Performance.startTrace(name: "albumUnlockedTrace")
        Analytics.logEvent("albumTapUnlocked", parameters: nil)
        tappedLockLogic()
        let removeAlbumLock = MediaManager.shared.removeAlbumLockFor(item: nowPlaying)
        if var items = removeAlbumLock.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        albumUnlockedTrace?.stop()
      } else {
        sender.isSelected = true
        albumIsLocked = true
        let albumLockedTrace = Performance.startTrace(name: "albumLockedTrace")
        Analytics.logEvent("albumTapLocked", parameters: ["album": nowPlaying.albumTitle ?? "Album Title"])
        let albumLock = MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying)
        if var items = albumLock.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        albumLockedTrace?.stop()
        tappedLockLogic()
      }
    }
  }
  
  
  @IBAction func artistLockButtonTapped(_ sender: UIButton) {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if sender.isSelected {
        sender.isSelected = false
        artistIsLocked = false
        let artistUnlockedTrace = Performance.startTrace(name: "artistUnlockedTrace")
        Analytics.logEvent("artistTapUnlocked", parameters: nil)
        tappedLockLogic()
        let unlockArtist = MediaManager.shared.removeArtistLockFor(item: nowPlaying)
        if var items = unlockArtist.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        artistUnlockedTrace?.stop()
      } else {
        sender.isSelected = true
        artistIsLocked = true
        let artistLockedTrace = Performance.startTrace(name: "artistLockedTrace")
        Analytics.logEvent("artistTapLocked", parameters: ["artist": nowPlaying.artist ?? "Artist"])
        let artistLock = MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying)
        if var items = artistLock.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        artistLockedTrace?.stop()
        tappedLockLogic()
      }
    }
  }
  
  
  @IBAction func genreLockButtonTapped(_ sender: UIButton) {
    if let nowPlaying = mediaPlayer.nowPlayingItem {
      if sender.isSelected {
        sender.isSelected = false
        genreIsLocked = false
        let genreUnlockedTrace = Performance.startTrace(name: "genreUnlockedTrace")
        Analytics.logEvent("genreTapUnlocked", parameters: nil)
        tappedLockLogic()
        let genreUnlocked = MediaManager.shared.removeGenreLockFor(item: nowPlaying)
        if var items = genreUnlocked.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        genreUnlockedTrace?.stop()
      } else {
        sender.isSelected = true
        genreIsLocked = true
        let genreLockedTrace = Performance.startTrace(name: "genreLockedTrace")
        Analytics.logEvent("genreTapLocked", parameters: ["genre": nowPlaying.genre ?? "Genre"])
        let genreLocked = MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying)
        if var items = genreLocked.items {
          items.shuffle()
          mediaPlayer.setQueue(with: MPMediaItemCollection(items: items))
        }
        genreLockedTrace?.stop()
        tappedLockLogic()
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


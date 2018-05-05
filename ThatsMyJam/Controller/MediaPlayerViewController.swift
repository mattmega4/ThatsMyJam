//
//  MediaPlayerViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import FirebasePerformance
import FirebaseAnalytics


class MediaPlayerViewController: UIViewController {
  
  @IBOutlet weak var topRightButton: UIButton!
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
  let mediaPlayer = MPMusicPlayerController.applicationQueuePlayer //applicationMusicPlayer //systemMusicPlayer
  var songTimer: Timer?
  var firstLaunch = true
  var lastPlayedItem: MPMediaItem?
  var volumeControlView = MPVolumeView()
  var counter = 0
  var aSongIsInChamber = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    clearSongInfo()
    setUpAudioPlayerAndGetSongsShuffled()
    setNavBar()
    DispatchQueue.main.async {
      self.mediaPlayer.beginGeneratingPlaybackNotifications()
      NotificationCenter.default.addObserver(self, selector: #selector(self.songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: self.mediaPlayer)
    }
    albumArtImageView.createRoundedCorners()
    songProgressSlider.addTarget(self, action: #selector(playbackSlider(_:)), for: .valueChanged)
    volumeControlView.showsVolumeSlider = true
    rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
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
    NotificationCenter.default.addObserver(self, selector: #selector(self.wasSongInterupted(_:)), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: self.mediaPlayer)
    showReview()
  }
  
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
        self.newSongs.removeAll()
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

  
  // MARK: - Unlock Everything & Play
  
  func unlockEverythingAndPlay() {
    DispatchQueue.main.async {
      MediaManager.shared.lockedSongs.removeAll()
      let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
      self.mediaPlayer.prepend(descriptor)
    }
  }
  
  // MARK: - Was Song Interupted
  
  @objc func wasSongInterupted(_ notification: Notification) {
    DispatchQueue.main.async {
      if self.mediaPlayer.playbackState == .paused {
        print("paused")
        self.isPlaying = false
        self.playPauseSongButton.isSelected = self.isPlaying
      } else if self.mediaPlayer.playbackState == .playing {
        self.isPlaying = true
        self.playPauseSongButton.isSelected = self.isPlaying
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
  
  // MARK: - Song Changed
  
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
      self.checkIfSongHasPlayedAllInLock()
      self.checkIfLocksShouldBeEnabled()
      self.tappedLockLogic()
      // re enable when apple fixes their stuff
//      if self.mediaPlayer.indexOfNowPlayingItem == 0 {
//        self.rewindSongButton.isEnabled = true
//        self.rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
//      } else if self.mediaPlayer.indexOfNowPlayingItem > 0 {
//        self.rewindSongButton.setImage(UIImage(named: "rewindIconLight.png"), for: .normal)
//
//      }
    }
  }
  
  // MARK: - Check If Song Has Played All In Lock
  
  func checkIfSongHasPlayedAllInLock() {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if self.albumIsLocked || self.artistIsLocked || self.genreIsLocked {
          MediaManager.shared.lockedSongs.append(nowPlaying)
        }
        MediaManager.shared.playedSongs.append(nowPlaying)
        if self.albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) {
          self.albumLockButtonTapped(self.albumLockIconButton)
          MediaManager.shared.lockedSongs.removeAll()
          self.unlockEverythingAndPlay()
          Analytics.logEvent("albumTriggeredUnlocked", parameters: nil)
        }
        if self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) {
          self.artistLockButtonTapped(self.artistLockIconButton)
          self.unlockEverythingAndPlay()
          Analytics.logEvent("artistTriggeredUnlocked", parameters: nil)
        }
        if self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
          self.genreLockButtonTapped(self.genreLockIconButton)
          self.unlockEverythingAndPlay()
          Analytics.logEvent("genreTriggeredUnlocked", parameters: nil)
        }
      }
    }}
  
  // MARK: - Check If Lock Should Be Enabled
  
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
  
  // MARK: - Tapped Logic
  
  func tappedLockLogic() {
    if !self.albumIsLocked && !self.artistIsLocked && !self.genreIsLocked {
      albumLockIconButton.isEnabled = true
      artistLockIconButton.isEnabled = true
      genreLockIconButton.isEnabled = true
    }
    if albumIsLocked {
      artistLockIconButton.isSelected = false
      artistIsLocked = false
      genreLockIconButton.isSelected = false
      genreIsLocked = false
    } else if artistIsLocked {
      albumLockIconButton.isSelected = false
      albumIsLocked = false
      genreLockIconButton.isSelected = false
      genreIsLocked = false
    } else if genreIsLocked {
      albumLockIconButton.isSelected = false
      albumIsLocked = false
      artistLockIconButton.isSelected = false
      artistIsLocked = false
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
  
  // MARK: - Get Time Remaining
  
  func getTimeRemaining() -> String {
    let secondsRemaining = songProgressSlider.maximumValue - songProgressSlider.value
    let minutes = Int(secondsRemaining / 60)
    let seconds = String(format: "%02d", Int(secondsRemaining - Float(60  * minutes)))
    return "\(minutes):\(seconds)"
  }
  
  // MARK: - Get Time Elapsed
  
  func getTimeElapsed() -> String {
    let secondsElapsed = songProgressSlider.value
    let minutes = Int(secondsElapsed / 60)
    let seconds = String(format: "%02d", Int(secondsElapsed - Float(60  * minutes)))
    let localizedMinutes = NSLocalizedString("\(minutes)", comment: "minutes")
    let localizedSeconds = NSLocalizedString("\(seconds)", comment: "seconds")
    return "\(localizedMinutes):\(localizedSeconds)"
  }
  
  // MARK: - Update Current Playback Time
  func updateCurrentPlaybackTime() {
    let elapsedTime = mediaPlayer.currentPlaybackTime
    songProgressSlider.value = Float(elapsedTime)
    songProgressView.progress = Float(elapsedTime / Double(songProgressSlider.maximumValue))
    songTimePlayedLabel.text = getTimeElapsed()
    songTimeRemainingLabel.text = getTimeRemaining()
  }
  
  
  // MARK: - IB Actions
  
  @IBAction func topRightButtonTapped(_ sender: UIButton) {
    if let prefVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.settingsViewControllerStoryboardID) as? SettingsViewController {
      let prefNavigation = UINavigationController(rootViewController: prefVC)
      self.present(prefNavigation, animated: true, completion: nil)
    }
  }
  
  // MARK: - Song Control Button Actions
  
  @IBAction func rewindSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        self.mediaPlayer.skipToBeginning()
        // uncomment when apple fixes stuff
//        let secondsElapsed = self.songProgressSlider.value
//        let minutes = Int(secondsElapsed / 60)
//        let seconds = Int(secondsElapsed - Float(60  * minutes))
//        if self.mediaPlayer.indexOfNowPlayingItem == 0 {
//          self.mediaPlayer.skipToBeginning()
//        } else {
//          if seconds < 5 {
//            self.mediaPlayer.skipToPreviousItem()
//          } else {
//            self.mediaPlayer.skipToBeginning()
//          }
//        }
      }
    })
    getCurrentlyPlayedInfo()
  }
  
  @IBAction func forwardSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        guard let nowPlaying = self.mediaPlayer.nowPlayingItem else {
          return
        }
        if self.albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) || self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) || self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
          self.unlockEverythingAndPlay()
        } else {
          self.mediaPlayer.prepareToPlay()
          self.mediaPlayer.skipToNextItem()
        }

        self.getCurrentlyPlayedInfo()
      }
    })
  }
  
  @IBAction func playPauseSongButtonTapped(_ sender: UIButton) {
    isPlaying = !isPlaying
    sender.isSelected = isPlaying
    if self.isPlaying {
      DispatchQueue.main.async {
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.play()
      }
    } else {
      DispatchQueue.main.async {
        self.mediaPlayer.pause()
      }
    }
    
    getCurrentlyPlayedInfo()
    if isPlaying {
      self.songTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
        DispatchQueue.main.async {
          self.updateCurrentPlaybackTime()
          self.getCurrentlyPlayedInfo()
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
          let unlockAlbumTrace = Performance.startTrace(name: "albumUnlockedTrace")
          Analytics.logEvent("albumTapUnlocked", parameters: nil)
          let unlockAlbum = MediaManager.shared.removeAlbumLockFor(item: nowPlaying)
          if var items = unlockAlbum.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
          }
          self.tappedLockLogic()
          unlockAlbumTrace?.stop()
        } else {
          sender.isSelected = true
          self.albumIsLocked = true
          self.artistIsLocked = false
          self.genreIsLocked = false
          let lockAlbumTrace = Performance.startTrace(name: "albumLockedTrace")
          Analytics.logEvent("albumTapLocked", parameters: ["album": nowPlaying.albumTitle ?? "Album Title"])
          let lockAlbum = MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying)
          if var items = lockAlbum.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
          lockAlbumTrace?.stop()
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
          let unlockArtistTrace = Performance.startTrace(name: "artistUnlockedTrace")
          Analytics.logEvent("artistTapUnlocked", parameters: nil)
          self.tappedLockLogic()
          let unlockArtist = MediaManager.shared.removeArtistLockFor(item: nowPlaying)
          if var items = unlockArtist.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
          }
          self.tappedLockLogic()
          unlockArtistTrace?.stop()
        } else {
          sender.isSelected = true
          self.artistIsLocked = true
          self.albumIsLocked = false
          self.genreIsLocked = false
          let unlockArtistTrace = Performance.startTrace(name: "artistLockedTrace")
          Analytics.logEvent("artistTapLocked", parameters: ["artist": nowPlaying.artist ?? "Artist"])
          
          let lockArtist = MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying)
          if var items = lockArtist.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
          self.tappedLockLogic()
          unlockArtistTrace?.stop()
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
          let unlockGenreTrace = Performance.startTrace(name: "genreUnlockedTrace")
          Analytics.logEvent("genreTapUnlocked", parameters: nil)
          let unlockGenre = MediaManager.shared.removeGenreLockFor(item: nowPlaying)
          if var items = unlockGenre.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
          }
          self.tappedLockLogic()
          unlockGenreTrace?.stop()
        } else {
          sender.isSelected = true
          self.genreIsLocked = true
          self.artistIsLocked = false
          self.albumIsLocked = false
          let lockGenreTrace = Performance.startTrace(name: "genreLockedTrace")
          Analytics.logEvent("genreTapLocked", parameters: ["genre": nowPlaying.genre ?? "Genre"])
          let lockGenre = MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying)
          if var items = lockGenre.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
          self.tappedLockLogic()
          lockGenreTrace?.stop()
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


//
//  MediaPlayerViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

#if swift(>=4.2)
import UIKit.UIGeometry
extension UIEdgeInsets {
  public static let zero = UIEdgeInsets()
}
#endif


import UIKit
import MediaPlayer
import AVFoundation
import FirebasePerformance
import FirebaseAnalytics
import Crashlytics
import ChameleonFramework


class MediaPlayerViewController: UIViewController {
  
  @IBOutlet weak var topRightButton: UIButton!
  @IBOutlet weak var albumArtImageView: UIImageView!
  @IBOutlet weak var songProgressView: UIProgressView!
  @IBOutlet weak var songProgressSlider: UISlider!
  @IBOutlet weak var songTimePlayedLabel: UILabel!
  @IBOutlet weak var songTimeRemainingLabel: UILabel!
  @IBOutlet weak var songNameLabel: UILabel!
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
  let mediaPlayer = MPMusicPlayerController.systemMusicPlayer
  var songTimer: Timer?
  var firstLaunch = true
  var lastPlayedItem: MPMediaItem?
  var volumeControlView = MPVolumeView()
  var counter = 0
  var aSongIsInChamber = false
  
  var concatenationLogic = AlbumArtistConcatenation()
  
  let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
  let remoCommandCenter = MPRemoteCommandCenter.shared()
  var audioSession = AVAudioSession.sharedInstance()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    clearSongInfo()
    setUpAudioPlayerAndGetSongsShuffled()
    albumArtImageView.roundedCorners()
    songProgressSlider.addTarget(self, action: #selector(playbackSlider(_:)), for: .valueChanged)
    volumeControlView.showsVolumeSlider = true
    var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    NotificationCenter.default.addObserver(self, selector: #selector(self.wasSongInteruptedNotification(_:)), name: nil, object: self.mediaPlayer)
  }
  
  func setupAudioSession() {
    var canBecomeFirstResponder: Bool { return true }
    self.becomeFirstResponder()
    do {
      
      try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default, options: [.allowAirPlay, .mixWithOthers, .defaultToSpeaker])
      try AVAudioSession.sharedInstance().setActive(true)
      
    } catch {
      print("Error setting the AVAudioSession:", error.localizedDescription)
    }
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
    setupAudioSession()
    //    setUpAudioPlayerAndGetSongsShuffled()
    setNavBar()
    showReview()
    
    wasSongInterupted()
    DispatchQueue.main.async {
      self.mediaPlayer.beginGeneratingPlaybackNotifications()
      NotificationCenter.default.addObserver(self, selector: #selector(self.songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: self.mediaPlayer)
    }
    
    if #available(iOS 13.0, *) {
      print("using ios 13 and above (1st time)")
    } else {
      print("NOT using ios 13 or above (1st time)")
      rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
    }
    
  }
  
  
  
  
  // MARK: - Initial Audio Player setup Logic
  
  func setUpAudioPlayerAndGetSongsShuffled() {
    DispatchQueue.main.async {
      self.mediaPlayer.stop()
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
      }
    }
  }
  
  // MARK: - Now Playing Info Center 
  
  func nowPlayingInfoCenterLogic() {
    //    UIApplication.shared.beginReceivingRemoteControlEvents()
    //    self.becomeFirstResponder()
    
    if let songInfo = self.mediaPlayer.nowPlayingItem {
      nowPlayingInfoCenter.nowPlayingInfo = [
        MPMediaItemPropertyTitle: songInfo.title ?? "",
        MPMediaItemPropertyArtist: songInfo.artist ?? "",
        MPMediaItemPropertyArtwork : songInfo.artwork?.image(at: CGSize(width: 400, height: 400)) ?? #imageLiteral(resourceName: "emptyArtworkImage")]
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
  
  func wasSongInterupted() {
    DispatchQueue.main.async {
      if self.mediaPlayer.playbackState == .paused {
        print("paused")
        self.isPlaying = false
        self.playPauseSongButton.isSelected = self.isPlaying
        self.playPauseSongButton.setImage(UIImage(named: "playIconLight.png"), for: .normal)
      } else if self.mediaPlayer.playbackState == .playing {
        self.isPlaying = true
        self.playPauseSongButton.isSelected = self.isPlaying
      }
    }
  }
  
  @objc func wasSongInteruptedNotification(_ notification: Notification) {
    wasSongInterupted()
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
      
      if #available(iOS 13.0, *) {
        print("using ios 13 and above (2nd time)")
        if self.mediaPlayer.indexOfNowPlayingItem == 0 {
          self.rewindSongButton.isEnabled = true
          self.rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
        } else if self.mediaPlayer.indexOfNowPlayingItem > 0 {
          self.rewindSongButton.setImage(UIImage(named: "rewindIconLight.png"), for: .normal)
        }
      } else {
        print("NOT using ios 13 or above (2nd time)")
      }
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
        }
        if self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) {
          self.artistLockButtonTapped(self.artistLockIconButton)
          self.unlockEverythingAndPlay()
        }
        if self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
          self.genreLockButtonTapped(self.genreLockIconButton)
          self.unlockEverythingAndPlay()
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
      self.songAlbumLabel.text = ""
    }
  }
  
  // MARK: - Get Song Information
  
  func getCurrentlyPlayedInfo() {
    DispatchQueue.main.async {
      if let songInfo = self.mediaPlayer.nowPlayingItem {
        let attributedSongName = self.concatenationLogic.convertSongInfoFromStringToNSAttributedString(text: songInfo.title ?? "", textColor: .white)
        let attributedSpace = self.concatenationLogic.convertSongInfoFromStringToNSAttributedString(text: "    ", textColor: .clear)
        let firstLineCombination = NSMutableAttributedString()
        firstLineCombination.append(attributedSongName)
        firstLineCombination.append(attributedSpace)
        
        self.songNameLabel.text = songInfo.title ?? "No Entered Song Title"
        
        let attributedAlbumName = self.concatenationLogic.convertSongInfoFromStringToNSAttributedString(text: songInfo.albumTitle ?? "Unknown Album", textColor: .white)
        let attributedDash = self.concatenationLogic.convertSongInfoFromStringToNSAttributedString(text: "  -  ", textColor: .white)
        let attributedArtistName = self.concatenationLogic.convertSongInfoFromStringToNSAttributedString(text: songInfo.artist ?? "Unknown Artist", textColor: .red)
        
        
        let secondLineCombination = NSMutableAttributedString()
        secondLineCombination.append(attributedAlbumName)
        secondLineCombination.append(attributedDash)
        secondLineCombination.append(attributedArtistName)
        secondLineCombination.append(attributedSpace)
        self.songAlbumLabel.attributedText = secondLineCombination
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
  
  // MARK: - Playback Slider
  
  @objc func playbackSlider(_ slider: UISlider) {
    DispatchQueue.main.async {
      if slider == self.songProgressSlider {
        self.mediaPlayer.currentPlaybackTime = Double(slider.value)
      }
    }
  }
  
  // MARK: - IB Actions
  
  @IBAction func topRightButtonTapped(_ sender: UIButton) {
    if let prefVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.settingsViewControllerStoryboardID) as? SettingsViewController {
      let prefNavigation = UINavigationController(rootViewController: prefVC)
      prefNavigation.modalPresentationStyle = .fullScreen
      self.present(prefNavigation, animated: true, completion: nil)
      
      
    }
  }
  
  // MARK: - Song Control Button Actions
  
  @IBAction func rewindSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        if #available(iOS 13.0, *) {
          print("using ios 13 and above (3rd time)")
          let secondsElapsed = self.songProgressSlider.value
          let minutes = Int(secondsElapsed / 60)
          let seconds = Int(secondsElapsed - Float(60  * minutes))
          if self.mediaPlayer.indexOfNowPlayingItem == 0 {
            self.rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
            self.mediaPlayer.skipToBeginning()
          } else {
            self.rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
            self.mediaPlayer.skipToBeginning()
            if seconds < 5 {
              self.rewindSongButton.setImage(UIImage(named: "rewindIconLight.png"), for: .normal)
              self.mediaPlayer.skipToPreviousItem()
            } else {
              self.rewindSongButton.setImage(UIImage(named: "restartSongLight.png"), for: .normal)
              self.mediaPlayer.skipToBeginning()
            }
          }
        } else {
          print("NOT using ios 13 or above (3rd time)")
          self.mediaPlayer.skipToBeginning()
        }
      }
    })
    getCurrentlyPlayedInfo()
  }
  
  @IBAction func forwardSongButtonTapped(_ sender: UIButton) {
    self.forwardSongButton.isEnabled = false
    
    
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        guard let nowPlaying = self.mediaPlayer.nowPlayingItem else {
          return
        }
        if self.albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) || self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) || self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
          self.unlockEverythingAndPlay()
        } else {
          self.mediaPlayer.skipToNextItem()
        }
        self.getCurrentlyPlayedInfo()
      }
      self.delay(seconds: 0.50) {
        self.forwardSongButton.isEnabled = true
      }
      
    })
    
  }
  
  @IBAction func playPauseSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        self.isPlaying = !self.isPlaying
        if self.isPlaying {
          self.playPauseSongButton.setImage(UIImage(named: "pauseIconLight"), for: .normal)
          self.mediaPlayer.prepareToPlay()
          self.mediaPlayer.play()
        } else {
          self.playPauseSongButton.setImage(UIImage(named: "playIconLight"), for: .normal)
          self.mediaPlayer.pause()
        }
        self.getCurrentlyPlayedInfo()
        if self.isPlaying {
          self.songTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.updateCurrentPlaybackTime()
            self.getCurrentlyPlayedInfo()
          })
          self.getCurrentlyPlayedInfo()
        } else {
          self.songTimer?.invalidate()
        }
      }
    })
  }
  
  
  // MARK: - Smart Shuffle Button Actions
  
  @IBAction func albumLockButtonTapped(_ sender: UIButton) {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if sender.isSelected {
          sender.isSelected = false
          self.albumIsLocked = false
          let unlockAlbum = MediaManager.shared.removeAlbumLockFor(item: nowPlaying)
          if var items = unlockAlbum.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
            
          }
          //          self.forwardSongButton.isEnabled = false
          //          self.mediaPlayer.prepareToPlay { (error) in
          //            self.unlockEverythingAndPlay()
          //            self.getCurrentlyPlayedInfo()
          //            self.forwardSongButton.isEnabled = true
          //          }
          self.tappedLockLogic()
        } else {
          sender.isSelected = true
          self.albumIsLocked = true
          self.artistIsLocked = false
          self.genreIsLocked = false
          let lockAlbum = MediaManager.shared.getSongsWithCurrentAlbumFor(item: nowPlaying)
          if var items = lockAlbum.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
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
          //          self.forwardSongButton.isEnabled = false
          //          self.mediaPlayer.prepareToPlay { (error) in
          //            self.unlockEverythingAndPlay()
          //            self.getCurrentlyPlayedInfo()
          //            self.forwardSongButton.isEnabled = true
          //          }
          
          self.tappedLockLogic()
        } else {
          sender.isSelected = true
          self.artistIsLocked = true
          self.albumIsLocked = false
          self.genreIsLocked = false
          let lockArtist = MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying)
          if var items = lockArtist.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
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
          let unlockGenre = MediaManager.shared.removeGenreLockFor(item: nowPlaying)
          if var items = unlockGenre.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
          }
          //          self.forwardSongButton.isEnabled = false
          //          self.mediaPlayer.prepareToPlay { (error) in
          //            self.unlockEverythingAndPlay()
          //            self.getCurrentlyPlayedInfo()
          //            self.forwardSongButton.isEnabled = true
          //          }
          self.tappedLockLogic()
        } else {
          sender.isSelected = true
          self.genreIsLocked = true
          self.artistIsLocked = false
          self.albumIsLocked = false
          let lockGenre = MediaManager.shared.getSongsWithCurrentGenreFor(item: nowPlaying)
          if var items = lockGenre.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
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


//
//  TimeViewController.swift
//  Bird
//
//  Created by Bai on 13/11/16.
//  Copyright © 2016 Bai. All rights reserved.
//

import UIKit
import AVFoundation

class TimeViewController: UIViewController {

    @IBOutlet var timeBackground: UIView!
    @IBOutlet weak var stopWatchButton: UIButton!
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet var resetLabel: UILabel!
    @IBOutlet weak var t1Button: UIButton!
    @IBOutlet weak var t2Button: UIButton!
    @IBOutlet weak var t3Button: UIButton!

    var sound = AnnounceModel()
    let userDefault = UserDefaultsModel()
    let status = TimeStatusModel()
    var btimer: Timer?
    var selectedButton: UIButton?
    var screenLock = ScreenLock()
    var t1settings = UserDefaults(suiteName: "t1")
    var t2settings = UserDefaults(suiteName: "t2")
    var t3settings = UserDefaults(suiteName: "t3")

    var screenLockisOn: Bool = true {
        didSet {
            UIApplication.shared.isIdleTimerDisabled = screenLockisOn
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonLabels()

        self.navigationController?.navigationBar.isTranslucent = true

        //Remove line between Navigationbar and View
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        //Add gesture to MainLabel
        let tapLabel: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(resetTime))
        tapLabel.delegate = self
        mainLabel.isUserInteractionEnabled = true
        mainLabel.addGestureRecognizer(tapLabel)

        //Add gesture to UINavigationBar title
        let tapTitle: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(resetTime))
        tapTitle.delegate = self
        self.navigationItem.titleView = resetLabel
        self.navigationItem.titleView?.isUserInteractionEnabled = true
        self.navigationItem.titleView?.addGestureRecognizer(tapTitle)

        //Default MainLabel
        display.font = display.font.withSize(500)
        display.text = ""
        display.minimumScaleFactor = 0.01
        display.adjustsFontSizeToFitWidth = true
        display.sizeToFit()

        //Update display when defaults change
        NotificationCenter.default.addObserver(self, selector: #selector(TimeViewController.setButtonLabels), name: UserDefaults.didChangeNotification, object: nil)
        restoreStatus()
    }

    func restoreStatus() {
        let textStop = NSLocalizedString("Stop", comment: "")
        if status.targetTime != -1 {
            switch status.timerTag {
            case 1:
                selectedButton = t1Button
            case 2:
                selectedButton = t2Button
            case 3:
                selectedButton = t3Button
            default:
                print("timer buttons tag invalid ")
            }
            selectedButton?.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            btimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(TimeViewController.change), userInfo: nil, repeats: true)
        } else if status.totalTime != 0 {
            if status.stopWatchIsOn {
                stopWatchButton.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                btimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimeViewController.change), userInfo: nil, repeats: true)
                timeBackground.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
                stopWatchButton.setTitle(textStop, for: UIControl.State.normal)
            } else {
                timeBackground.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
                let displayTime = status.totalTime
                covertTimeInterval(interval: TimeInterval(displayTime))
            }
        } else if status.stopWatchIsOn {
            stopWatchButton.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            btimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimeViewController.change), userInfo: nil, repeats: true)
            timeBackground.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            stopWatchButton.setTitle(textStop, for: UIControl.State.normal)
        }
        //reset mode
        return
    }

    @IBAction func pressTimersButton(_ sender: UIButton) {
        reset()
        resetSelectedButtonBackground()
        selectedButton = sender
        btimer?.invalidate()
        btimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(TimeViewController.change), userInfo: nil, repeats: true)

        timeBackground.backgroundColor = UIColor(red: 30 / 255, green: 30 / 255, blue: 30 / 255, alpha: 1)

        status.timerTag = sender.tag
        switch sender.tag {
        case 1:
            status.targetTime = (t1settings?.integer(forKey: "time"))!
        case 2:
            status.targetTime = (t2settings?.integer(forKey: "time"))!
        case 3:
            status.targetTime = (t3settings?.integer(forKey: "time"))!
        default:
            print("timer buttons tag invalid ")
        }
        sender.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        status.startTime = Date()
        covertTimeInterval(interval: Double(status.targetTime))
    }

    @IBAction func pressStopWatchButton(_ sender: UIButton) {
        //reset timer when user press this button when timer is running
        if status.targetTime != -1 {
            reset()
        }
        status.targetTime = -1
        btimer?.invalidate()
        resetSelectedButtonBackground()
        if !status.stopWatchIsOn {
            sender.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            status.stopWatchIsOn = true
            status.startTime = Date()
            btimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimeViewController.change), userInfo: nil, repeats: true)
            timeBackground.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            let textStop = NSLocalizedString("Stop", comment: "")
            sender.setTitle(textStop, for: UIControl.State.normal)
        } else {
            status.stopWatchIsOn = false
            let textStart = NSLocalizedString("Start", comment: "")
            sender.setTitle(textStart, for: UIControl.State.normal)
            sender.backgroundColor = #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
            status.totalTime += Date().timeIntervalSince(status.startTime)
        }
    }

    @objc func setButtonLabels () {
        //refresh locks from userDefault
        screenLock = ScreenLock()

        //refresh annoucners from userDefault
        sound = AnnounceModel()

        t1Button.setTitle(t1settings?.integer(forKey: "time").covertTotalToTimer(), for: .normal)
        t2Button.setTitle(t2settings?.integer(forKey: "time").covertTotalToTimer(), for: .normal)
        t3Button.setTitle(t3settings?.integer(forKey: "time").covertTotalToTimer(), for: .normal)
    }

    func covertTimeInterval(interval: TimeInterval) {
        display.font = display.font.withSize(500)
        display.minimumScaleFactor = 0.01
        display.adjustsFontSizeToFitWidth = true

        let absInterval = abs(Int(interval))
        let seconds = absInterval % 60
        let minutes = (absInterval / 60) % 60
        let hours = (absInterval / 3600)

        if status.targetTime == -1 {

            //format mainLabel for Stopwatch mode
            screenLockisOn = screenLock.mainLock ? screenLock.stopwatchLock : false

            let msec = interval.truncatingRemainder(dividingBy: 1)

            display.text = hours == 0 ? String(format: "%.2d", minutes) + ":" + String(format: "%.2d", seconds) + "." + String(format: "%.2d", Int(msec * 100)) : String(hours) + ":" + String(format: "%.2d", minutes) + ":" + String(format: "%.2d", seconds) + "." + String(format: "%.2d", Int(msec * 100))
        }

        //fomat mainLabel for timer mode
        screenLockisOn = screenLock.mainLock ? screenLock.timerLocks[status.timerTag - 1] : false

        if hours != 0 {
            display.text = String(hours) + ":" + String(format: "%.2d", minutes) + ":" + String(format: "%.2d", seconds)
        } else if minutes != 0 {
            display.text = String(minutes) + ":" + String(format: "%.2d", seconds)
        } else {
            display.text = String(seconds)
            display.font = display.font.withSize(display.font.pointSize * 0.55)
        }

        if !status.stopWatchIsOn, status.totalTime == 0 {
            sound.playSound(displayTime: Int(interval))
        }
    }

    @objc func change() {

        if status.targetTime == -1 {
            let displayTime = Date().timeIntervalSince(status.startTime) + status.totalTime
            covertTimeInterval(interval: TimeInterval(displayTime))
        } else {
            display.textColor = UIColor.white
            let intervalTime = status.startTime.timeIntervalSinceNow
            let displayTime = Int(intervalTime) + status.targetTime
            covertTimeInterval(interval: TimeInterval(displayTime))

            if displayTime < 1 {
                timeBackground.backgroundColor = UIColor(red: 39 / 255, green: 174 / 255, blue: 96 / 255, alpha: 1)
                selectedButton?.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                selectedButton?.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControl.State.normal)
            }
        }
    }

    //return selected button background to default
    func resetSelectedButtonBackground() {
        selectedButton?.backgroundColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
        //selectedButton?.layer.borderWidth = 0.0
        let textStart = NSLocalizedString("Start", comment: "")
        stopWatchButton.setTitle(textStart, for: UIControl.State.normal)
        stopWatchButton.backgroundColor = #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
        selectedButton?.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: UIControl.State.normal)
    }

}

extension TimeViewController: UIGestureRecognizerDelegate {
    @objc func resetTime(sender: UITapGestureRecognizer) {
        reset()
        display.text = ""
        timeBackground.backgroundColor = UIColor(red: 30 / 255, green: 30 / 255, blue: 30 / 255, alpha: 1)
        resetSelectedButtonBackground()

        screenLockisOn = false
    }

    func reset() {
        status.stopWatchIsOn = false
        status.totalTime = 0
        status.targetTime = -1
        btimer?.invalidate()
        sound = AnnounceModel()
    }
}

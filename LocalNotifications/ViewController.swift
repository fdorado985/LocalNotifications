//
//  ViewController.swift
//  LocalNotifications
//
//  Created by Juan Francisco Dorado Torres on 29/09/19.
//  Copyright © 2019 Juan Francisco Dorado Torres. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

  // MARK: - Enum
  @objc enum NotificationReminder: Int {
    case fiveSeconds = 0
    case oneDay
    case oneWeek
  }

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(registerLocal))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Schedule", style: .plain, target: self, action: #selector(scheduleLocal))
  }

  // MARK: - Methods

  @objc func registerLocal() {
    let center = UNUserNotificationCenter.current() // the main center to work with notifications
    // ask for the authorization to send or not local notifications
    center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
      if granted {
        print("Yay!")
      } else {
        print("D'oh")
      }
    }
  }

  @objc func scheduleLocal(reminder: NotificationReminder = .fiveSeconds) {
    registerCategories() // it is the safest place

    let center = UNUserNotificationCenter.current() // the main center to work with notifications
    // center.removeAllPendingNotificationRequests() // this removes all pending notifications

    // this is the content you are going to send to your notification
    let content = UNMutableNotificationContent()
    content.title = "Late wake up call" // the main title
    content.body = "The early bird catches the worm, but the second mouse gets the cheese." // the main text
    content.categoryIdentifier = "alarm" // this are the custom actions
    content.userInfo = ["customData" : "fizzbuzz"] // this helps to attach custom data to the notification. e.g. an internal ID
    content.sound = UNNotificationSound.default // you can create a custom UNNotificationSound object and attach it to the sound property, or just use the default one

    // get the date components to schedule the time you want your notification
    var dateComponents = DateComponents()
    dateComponents.hour = 10 // give the hour
    dateComponents.minute = 30 // give the minutes
    //let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true) // trigger the notification to your calendar

    let trigger: UNTimeIntervalNotificationTrigger

    // faster test
    switch reminder.rawValue {
    case 0:
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    case 1:
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
    case 2:
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
    default:
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    }

    // create your notification request - the notification needs an unique identifier
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    // add it to your center
    center.add(request)
  }

  func registerCategories() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    let show = UNNotificationAction(identifier: "show", title: "Tell me more...", options: .foreground)
    let reminder = UNNotificationAction(identifier: "reminder", title: "Remind me later", options: .foreground)
    let category = UNNotificationCategory(identifier: "alarm", actions: [show, reminder], intentIdentifiers: [])

    center.setNotificationCategories([category])
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension ViewController: UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // pull out the buried userInfo dictionary
    let userInfo = response.notification.request.content.userInfo

    if let customData = userInfo["customData"] as? String {
      print("Custom data received: \(customData)")

      let alert: UIAlertController

      switch response.actionIdentifier {
      case UNNotificationDefaultActionIdentifier:
        // the user swiped to unlock
        print("Default identifier")
        alert = UIAlertController(title: "Default", message: "You have opened the app using the default option", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
      case "show":
        // the user tapped our "show more info..." button
        print("Show more information...")
        alert = UIAlertController(title: "Custom", message: "You have opened the app using the 'Show me more information' button", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
      case "reminder":
        // the user tapped our "show more info..." button
        print("Remind me later...")
        alert = UIAlertController(title: "Reminder", message: "When do you want to be reminded?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "1 day", style: .default, handler: { [weak self] (action) in
          self?.scheduleLocal(reminder: .oneDay)
        }))
        alert.addAction(UIAlertAction(title: "1 week", style: .default, handler: { [weak self] (action) in
          self?.scheduleLocal(reminder: .oneWeek)
        }))
      default:
        alert = UIAlertController(title: "No ID 🤔", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        break
      }

      present(alert, animated: true)
    }

    // you must call the completion handler when you're done
    completionHandler()
  }
}


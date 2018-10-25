//
//  ViewController.swift
//  DLXTestDriver-OSX
//
//  Created by Mike Mayer on 10/21/18.
//  Copyright © 2018 VMWishes. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
  @IBOutlet weak var dataSetPopup: NSPopUpButton!
  @IBOutlet weak var startButton: NSButton!
  @IBOutlet weak var cancelButton: NSButton!
  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var solutionCountLabel: NSTextField!
  @IBOutlet var loggingTextView: NSTextView!
  
  var isRunning = false
  var dlx : DLX?
  
  let dataSets : Dictionary<String,[[Int]]> = [
    "demo 1" : [[1,4,7],[1,4],[4,5,7],[3,5,6],[2,3,6,7],[7,2]],
    "empty" : [[Int]](),
    "uncovered" : [[Int](), [Int](), [Int]()]
  ]
  
  var solutionCount = 0
  
  var curDataSetTitle : String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dataSetPopup.removeAllItems()
    dataSetPopup.addItems(withTitles: Array(dataSets.keys))
    
    resetFields()
    handleDataSet(dataSetPopup)
    updateAll()
    
    NotificationCenter.default.addObserver(forName:.DLXSolutionFound,     object:nil, queue:OperationQueue.main, using:handleNotification)
    NotificationCenter.default.addObserver(forName:.DLXAlgorithmCanceled, object:nil, queue:OperationQueue.main, using:handleNotification)
    NotificationCenter.default.addObserver(forName:.DLXAlgorithmComplete, object:nil, queue:OperationQueue.main, using:handleNotification)
  }
  
  func resetFields()
  {
    solutionCountLabel.stringValue = ""
    statusLabel.stringValue = ""
    
    solutionCount = 0
    
    if let ts = loggingTextView.textStorage {
      ts.replaceCharacters(in: NSMakeRange(0, ts.length), with: "")
    }
  }
  
  func updateAll()
  {
    if isRunning {
      cancelButton.isEnabled = true
      startButton.isEnabled = false
      dataSetPopup.isEnabled = false
    }
    else
    {
      cancelButton.isEnabled = false
      startButton.isEnabled = (dlx != nil && dlx!.isComplete==false )
      dataSetPopup.isEnabled = true
    }
    
    dataSetPopup.isEnabled = ( isRunning == false )
  }
  
  @IBAction func handleStart(_ sender: NSButton)
  {
    guard dlx != nil else {
      logError("start button active when dlx is nil")
      return
    }
    guard dlx!.isComplete == false else {
      logError("start button active when dlx solution is complete")
      return
    }
    
    isRunning = true
    resetFields()
    updateAll()
    
    dlx!.solve()
  }
  
  @IBAction func handleCancel(_ sender: NSButton)
  {
    guard dlx != nil else {
      logError("cancel button active when dlx is nil")
      return
    }
    guard isRunning else {
      logError("cancel button active when algorithm isn't running")
      return
    }
    dlx!.cancel()
  }
  
  @IBAction func handleDataSet(_ sender: NSPopUpButton)
  {
    if let key = sender.selectedItem?.title {
      if key == curDataSetTitle { logError("Reselected current data set "+key); return }
      
      resetFields()
      curDataSetTitle = nil
      dlx = nil
      
      if let data = dataSets[key] {
        curDataSetTitle = key
        do {
          dlx = try DLX(data)
        }
        catch DLXError.InputEmpty {
          logException("Coverage Matrix cannot be Empty")
        }
        catch DLXError.InputNoCoverage
        {
          logException("Coverage Matrix is not covering any columns")
        }
        catch let err
        {
          logException(err.localizedDescription)
        }
      }
    }
    updateAll()
  }
  
  @objc func handleNotification(_ notification:Notification)
  {
    switch notification.name
    {
    case Notification.Name.DLXSolutionFound:
//      solutionsCountLabel.stringValue = dlx?.solutions.count.description ?? ""
      log("Solution Found")
      solutionCount += 1
      solutionCountLabel.stringValue = solutionCount.description
    case Notification.Name.DLXAlgorithmCanceled:
      statusLabel.stringValue = "Canceled"
      logInfo("DLX Algorithm was canceled",
              color:NSColor(red:0.5, green:0.0, blue:0.0, alpha: 1.0))
      isRunning = false
    case Notification.Name.DLXAlgorithmComplete:
      statusLabel.stringValue = "Completed"
      logInfo("DLX Algorithm completed")
      isRunning = false
    default:
      return
    }
    
     updateAll()
  }
  
  func logException(_ msg:String)
  {
    let attrMsg = NSAttributedString(string: "Exception Caught: " + msg + "\n", attributes:
      [
        NSAttributedString.Key.foregroundColor: NSColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0),
        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 0.0)
      ] )
    loggingTextView.textStorage?.append(attrMsg)
  }

  func logError(_ msg:String)
  {
    let attrMsg = NSAttributedString(string: "Oops: " + msg + "\n", attributes:
      [
        NSAttributedString.Key.foregroundColor: NSColor.white,
        NSAttributedString.Key.backgroundColor: NSColor(red:0.5, green:0.0, blue:0.0, alpha: 1.0),
        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 0.0)
      ] )
    loggingTextView.textStorage?.append(attrMsg)
  }
  
  func logInfo(_ msg:String, color:NSColor = NSColor.blue)
  {
    let attrMsg = NSAttributedString(string: msg + "\n", attributes:
      [
        NSAttributedString.Key.foregroundColor: color,
        NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 0.0)
      ] )
    loggingTextView.textStorage?.append(attrMsg)
  }
  
  func log(_ msg:String)
  {
    let attrMsg = NSAttributedString(string: msg + "\n", attributes:
      [
        NSAttributedString.Key.foregroundColor: NSColor.black,
        NSAttributedString.Key.font: NSFont.systemFont(ofSize: 0.0)
      ] )
    loggingTextView.textStorage?.append(attrMsg)
  }
}

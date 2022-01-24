//
//  ViewController.swift
//  Translate
//
//  Created by 李阳 on 2022/1/24.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var segmentControl: NSSegmentedControl!
    
    @IBOutlet weak var tag1: NSTextField!
    @IBOutlet var textView1: NSTextView!
    
    @IBOutlet weak var tag2: NSTextField!
    @IBOutlet var textView2: NSTextView!
    
    @IBOutlet weak var tag3: NSTextField!
    @IBOutlet var textView3: NSTextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupBody()
    }

    @IBAction func runButtonDidClick(_ sender: NSButton) {
        
        if segmentControl.selectedSegment == 0 {
            let sample = textView1.string.trim()
            let answer = textView2.string.trim()
            let res = Translate.strings(from: answer, refer: sample)
            textView3.string = res
            
            guard !res.isEmpty else { return }
            let pboard = NSPasteboard.general
            pboard.declareTypes([.string], owner: nil)
            pboard.setString(res, forType: .string)
        } else {
            let sample = textView1.string.trim()
            let res = Translate.excel(from: sample)
            textView2.string = res.key
            textView3.string = res.value
        }
    }
    @IBAction func segmentControlDidClick(_ sender: NSSegmentedControl) {
        resetUI()
    }
}

private extension ViewController {
    func setupBody() {
        segmentControl.selectedSegment = 0
        [tag1, tag2, tag3].forEach {
            $0?.isEditable = false
        }
        
        textView1.becomeFirstResponder()
        tag1.stringValue = "请输入模版翻译"
        resetUI()
    }
    func resetUI() {
        if segmentControl.selectedSegment == 0 {
            tag2.stringValue = "请输入Excel中的翻译"
            tag3.stringValue = "结果"
        } else {
            tag2.stringValue = "Keys"
            tag3.stringValue = "Values"
        }
    }
}

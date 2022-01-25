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
    
    @IBOutlet weak var column3Container: NSView!
    @IBOutlet weak var tag3: NSTextField!
    @IBOutlet var textView3: NSTextView!
    
    private var lastSelectedIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupBody()
    }

    @IBAction func pasteboardButtonDidClick(_ sender: NSButton) {
        let pboard = NSPasteboard.general
        print(pboard.string(forType: .string) ?? "empty")
        guard let string = pboard.string(forType: .string)?.trim(),
              !string.isEmpty else { return }
        perform(string)
    }
    @IBAction func runButtonDidClick(_ sender: NSButton) {
        let index = segmentControl.selectedSegment
        if index == 0 {
            perform(textView2.string.trim())
        } else {
            perform(textView1.string.trim())
        }
    }
    @IBAction func segmentControlDidClick(_ sender: NSSegmentedControl) {
        let index = segmentControl.selectedSegment
        guard lastSelectedIndex != index else { return }
        lastSelectedIndex = index
        resetUI()
    }
}

private extension ViewController {
    func perform(_ string: String) {
        let index = segmentControl.selectedSegment
        if index == 0 {
            let sample = textView1.string.trim()
            let res = Translate.strings(from: string, refer: sample)
            textView3.string = res
            
            guard !res.isEmpty else { return }
            let pboard = NSPasteboard.general
            pboard.declareTypes([.string], owner: nil)
            pboard.setString(res, forType: .string)
        } else if index == 1 {
            let res = Translate.excel(from: string)
            textView2.string = res.key
            textView3.string = res.value
            
            let pboard = NSPasteboard.general
            pboard.declareTypes([.string], owner: nil)
            pboard.setString(res.value, forType: .string)
            pboard.setString(res.key, forType: .string)
        } else {
            let res = Translate.validFormat(string) ?? "Success"
            textView2.string = res
        }
    }
}

private extension ViewController {
    func setupBody() {
        segmentControl.selectedSegment = lastSelectedIndex
        [tag1, tag2, tag3].forEach {
            $0?.isEditable = false
        }
        
        textView1.becomeFirstResponder()
        tag1.stringValue = "请输入翻译样本"
        
        resetUI()
    }
    func resetUI() {
        let index = segmentControl.selectedSegment
        
        if index == 2 {
            column3Container.isHidden = true
        } else {
            column3Container.isHidden = false
        }
        textView2.string = ""
        textView3.string = ""
        if index == 0 {
            tag2.stringValue = "请输入Excel中的翻译"
            tag3.stringValue = "结果"
        } else if index == 1 {
            tag2.stringValue = "Keys"
            tag3.stringValue = "Values"
        } else {
            tag2.stringValue = "结果"
        }
    }
}

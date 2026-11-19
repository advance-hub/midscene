import UIKit
final class Editor: UIView, UIKeyInput {
  var text = "first line\nsecond line"
  var outsideClicks = 0
  var selection = false
  override var canBecomeFirstResponder: Bool { true }
  var hasText: Bool { !text.isEmpty }
  func insertText(_ string: String) {
    text = (selection ? "" : text) + string
    selection = false
    record()
  }
  func deleteBackward() {
    if selection { text = "" } else if hasText { text.removeLast() }
    selection = false
    record()
  }
  override func draw(_ layer: CGRect) {
    (text as NSString).draw(in: bounds.insetBy(dx: 8, dy: 5),withAttributes:[.font:UIFont.systemFont(ofSize:20),.foregroundColor: selection ? UIColor.blue : UIColor.black])
  }
  func record(){
    setNeedsDisplay()
    let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
    try! JSONSerialization.data(withJSONObject:["value":text,"selected":selection,"outsideClicks":outsideClicks]).write(to:dir.appendingPathComponent("field.json"),options:.atomic)
  }
}
final class Controller:UIViewController{
  let editor=Editor()
  let toolbar=UIToolbar()
  override func viewDidLoad(){
    super.viewDidLoad()
    view.backgroundColor = .white
    editor.frame=CGRect(x:20,y:155,width:300,height:100)
    editor.backgroundColor = .systemGray5
    let decoy = ProcessInfo.processInfo.arguments.contains("--decoy")
    editor.isAccessibilityElement = !decoy
    editor.accessibilityLabel = "Nickname editor"
    if decoy {
      let other = UIToolbar(frame:CGRect(x:18,y:386,width:340,height:44))
      other.items=[UIBarButtonItem(title:"Select All",style:.plain,target:self,action:#selector(outside)),UIBarButtonItem(title:"Copy",style:.plain,target:self,action:#selector(outside))]
      view.addSubview(other)
    }
    let heading=UILabel(frame:CGRect(x:20,y:62,width:355,height:32))
    heading.text = decoy ? "Nickname + separate toolbar" : "Accessible nickname editor"
    heading.font=UIFont.boldSystemFont(ofSize:20)
    view.addSubview(heading)
    view.addSubview(editor)
    let native = UITextField(frame:CGRect(x:20,y:295,width:300,height:46))
    native.borderStyle = .roundedRect
    native.addTarget(self,action:#selector(nativeChanged(_:)),for:.editingChanged)
    view.addSubview(native)
    let tap=UITapGestureRecognizer(target:self,action:#selector(focus))
    let hold=UILongPressGestureRecognizer(target:self,action:#selector(menu(_:)))
    tap.require(toFail:hold)
    editor.addGestureRecognizer(tap)
    editor.addGestureRecognizer(hold)
    toolbar.frame=CGRect(x:35,y:100,width:210,height:45)
    toolbar.items=[UIBarButtonItem(title:"全选",style:.plain,target:self,action:#selector(selectText)),UIBarButtonItem(title:"复制",style:.plain,target:self,action:#selector(copyText))]
    toolbar.isHidden=true
    view.addSubview(toolbar)
    editor.record()
  }
  @objc func nativeChanged(_ sender:UITextField){
    let dir=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
    try! JSONSerialization.data(withJSONObject:["value":sender.text ?? ""]).write(to:dir.appendingPathComponent("native.json"),options:.atomic)
  }
  @objc func outside(){editor.outsideClicks += 1;editor.record()}
  @objc func focus(){ toolbar.isHidden=true; editor.selection=false; editor.becomeFirstResponder(); editor.record() }
  @objc func menu(_ sender:UILongPressGestureRecognizer){if sender.state == .began{editor.becomeFirstResponder();toolbar.isHidden=false}}
  @objc func selectText(){editor.selection=true; toolbar.isHidden=true; editor.record()}
  @objc func copyText(){if editor.selection {UIPasteboard.general.string=editor.text}; toolbar.isHidden=true}
}
class App:UIResponder,UIApplicationDelegate {
 var window:UIWindow?
 func application(_ app:UIApplication,didFinishLaunchingWithOptions opts:[UIApplication.LaunchOptionsKey:Any]?) -> Bool{
 window=UIWindow(frame:UIScreen.main.bounds);window?.rootViewController=Controller();window?.makeKeyAndVisible();return true
 }
}
UIApplicationMain(CommandLine.argc,CommandLine.unsafeArgv,nil,NSStringFromClass(App.self))

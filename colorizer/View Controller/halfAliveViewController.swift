//
//  ViewController.swift
//  colorizer
//
//  Created by Nandan on 20/01/20.
//  Copyright © 2020 Nandan. All rights reserved.
//

/// Half Alive Viewcontroller - Here the user can choose any picture, or take a picture at any given time , and drag a given marker on the picture to get the color information of the pixel at which the marker is kept. the marker initially was a label, but now is an image that is properly draggable. The Information of the color can be derived as a RGB or HSB string which can be shared on the buffer page


var discoveredColor : UIColor?
var truth = UserDefaults().bool(forKey: "SwitchStateRGB")
var cameFromHalfAlive = true
var dominantColor :UIColor = .white


//MARK: - Import and Extensions
import UIKit
import SwiftyGif
import Firebase
import AudioToolbox
//MARK: - Classes and Variables related to the halfAliveViewController
class ViewController: UIViewController , UIImagePickerControllerDelegate , UINavigationControllerDelegate , UIScrollViewDelegate {
let logoAnimationView = LogoAnimationView()
@IBOutlet weak var Scroll: UIScrollView!
@IBOutlet weak var myImageView: UIImageView!
@IBOutlet weak var importerButton: UIButton!
@IBOutlet weak var cameraUseButton: UIButton!
@IBOutlet weak var Lab: UILabel! // Hex value of color displayed here
@IBOutlet weak var liveButton: UIButton!
@IBOutlet weak var sliderButton: UIButton!
@IBOutlet weak var settingsButton: UIButton!

// An unwind segue that comes back to this viewcontroller
@IBAction func unwindToHalfAlive(segue: UIStoryboardSegue) {}



class cv {
var ranOnce = false
var zoomer : CGFloat = 1.0
}
let uni = cv()


let values = UILabel() // Displays the values of the RGB components
let crossHair =  UIImageView() // crosshair that is draggable
let extractorButton = UIButton() // pressing the button will open a view which allows user to explore the color
let extractorButtonShell = CAShapeLayer() // Circular shape which is the "shell " for the buffer button
let nameOfColor = UILabel() // Displays the Cataloged name of the color

/// Describes the attributes and making the Extractor Button Visible
func addCircularButton(){
// circular shaped button which will give user op
extractorButton.frame = CGRect(x: self.view.bounds.maxX / 2 -  35 , y: (self.view.bounds.maxY * 0.85) - 35, width: 70, height: 70)
extractorButton.backgroundColor = .clear
extractorButton.layer.masksToBounds = true
extractorButton.layer.cornerRadius = 40
self.view.addSubview(extractorButton)
extractorButton.addTarget(self, action: #selector(ViewController.goToResultBuffer(_:)), for: .touchUpInside)
extractorButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ViewController.goToTable(_:))))



//circular part of the extractor button
let linePath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 70, height: 70))
extractorButtonShell.frame = CGRect(x: self.view.bounds.maxX / 2  - 35 , y: (self.view.bounds.maxY * 0.85) - 35, width: 50, height: 50)
extractorButtonShell.lineWidth = 3
extractorButtonShell.strokeColor = UIColor.label.cgColor
extractorButtonShell.path = linePath.cgPath
extractorButtonShell.zPosition = CGFloat(Float.greatestFiniteMagnitude)
self.view.layer.insertSublayer(extractorButtonShell, at: 1)
}

/// Function to deal with UI before the Loading Screen Is finished with loading
func preSetup() {
sliderButton.isHidden = true
importerButton.isHidden = true
cameraUseButton.isHidden = true
liveButton.isHidden = true
settingsButton.isHidden = true
Lab.isHidden = true
extractorButtonShell.isHidden = true

view.addSubview(logoAnimationView)
logoAnimationView.pinEdgesToSuperView()
logoAnimationView.logoGifImageView.delegate = self
}


//MARK: - SetupUI
func setupUI(){
sliderButton.isHidden = false
importerButton.isHidden = false
cameraUseButton.isHidden = false
liveButton.isHidden = false
settingsButton.isHidden = false

// parameters for the scroll view on which the image is displayed on
Scroll.delegate = self
Scroll.minimumZoomScale = 1.0
Scroll.maximumZoomScale = 100.0

//parameters of the imageview on which the image is added
myImageView.image = #imageLiteral(resourceName: "Wheel")
myImageView.backgroundColor = .clear
myImageView.isOpaque = true

// setting the image of the Draggable crosshair then displaying it
crossHair.image = #imageLiteral(resourceName: "crosshair")
addCrosshair()

// parameters for the Hex value label
Lab.frame = CGRect(x: Int(self.view.frame.maxX /  2 ) - 75, y: 21, width: 135, height: 21)
Lab.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)

// label for name of the colour that will be detected
nameOfColor.frame = CGRect(x:(self.view.bounds.maxX / 2 ) - 150  , y: self.view.bounds.maxY * 0.85 - 60 , width: 300 , height: 20)
nameOfColor.textColor = .label
nameOfColor.textAlignment = .center
nameOfColor.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
nameOfColor.text = discoveredColor?.name
nameOfColor.backgroundColor = .clear
self.view.addSubview(nameOfColor)

}


//MARK: - Override
override func viewDidLoad() {
preSetup()
super.viewDidLoad()
// Runs the Functions in it after a specified amount of time so that the loading screen can properly be displayed
DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
if (UserDefaults.standard.value(forKey: "isFirstLaunch") as? Bool) != nil {
    print("this is not the first launch")
} else {
    print("this is the first launch")

    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    let vc : settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "Settings") as! settingsViewController
    self.present(vc, animated: true, completion: nil)
}
self.setupUI()
self.addCircularButton()
self.crossHair.shake()
}

}

override func viewDidAppear(_ animated: Bool) {
super.viewDidAppear(animated)
if Auth.auth().currentUser != nil {
let string = Auth.auth().currentUser?.email ?? "Nil"
print("\(string)")
LoggedIn = true
}
logoAnimationView.logoGifImageView.startAnimatingGif()
self.crossHair.shake()
}


/// Prepares Data to be sent accross the Viewcontrollers
/// - Parameter segue: Where the user is going towards.(can be buffer menu or slider menu)
/// - Parameter sender: Self ( half alive viewcontroller itself here)
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
if let sliderViewController = segue.destination as? sliderViewController
{
sliderViewController.tempColor = discoveredColor
}
else
{
if let dataBufferPage = segue.destination as? dataBufferPage
{
dataBufferPage.tempColor = discoveredColor
}
else
{
return
}
}
}


/// Click on this to go to the Buffer view which will show you colors and save them later
/// - Parameter sender: Circular button declared earlier
@objc func goToResultBuffer(_ sender:UIButton) {
performSegue(withIdentifier: "halfAliveToBuffer", sender: nil)
}
@objc func goToTable(_ sender:UILongPressGestureRecognizer){
performSegue(withIdentifier: "FromHalf", sender: nil)
AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
}
 
/// Adds a draggable label which cointains the marker . We use the cross emojticon here for  marking
//UPDATE : made the CrossHair PNG based so we could get cooler ones
func addCrosshair() {
crossHair.frame =   CGRect(x: self.view.bounds.width/2-20, y:self.view.bounds.height/2-20, width: 100, height: 100)
if uni.ranOnce == false {
uni.ranOnce = true
crossHair.backgroundColor = .clear
self.view.addSubview(crossHair)
crossHair.isUserInteractionEnabled = true
let gesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.colorFinderFunction(_:)))
crossHair.addGestureRecognizer(gesture)

}

}

//MARK: - Button Actions
@IBAction func galleryImporter(_ sender: Any) {
let image = UIImagePickerController()
image.delegate = self
image.sourceType = UIImagePickerController.SourceType.photoLibrary
image.allowsEditing = true
self.present(image , animated: true)
addCrosshair()
Scroll.zoomScale = 1
myImageView.contentMode = .scaleAspectFit


}

@IBAction func CameraUse(_ sender: Any) {

let image = UIImagePickerController()
image.delegate = self
image.sourceType = UIImagePickerController.SourceType.camera
image.allowsEditing = true
self.present(image , animated: true)
addCrosshair()
uni.zoomer = 1
}

@IBAction func goToSliderFunction(_ sender: Any) {
cameFromHalfAlive = true
}

func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
myImageView.image = image
uni.zoomer = 1
dominantColor = image.makePretty(image: image)

}
else{}
self.dismiss(animated: true, completion: nil)
}



/// returns the View once the user has piched or dragged on the VIew
/// - Parameter Scroll: Scroll is the view which allows the gesture implementation on UIVIew
func viewForZooming(in Scroll : UIScrollView) -> UIView? {
uni.zoomer = max(Scroll.contentSize.height / Scroll.frame.height, Scroll.contentSize.width / Scroll.frame.width)
   return self.myImageView
}

/// This function will help find the color of the specified point which is marked using the given pointer
/// - Parameter gesture: drag the pointer to a point inside the image and obtain the pixel color of the point.
@objc func colorFinderFunction(_ gesture : UIPanGestureRecognizer) {
Lab.isHidden = false
extractorButtonShell.isHidden = false
let orignalCenter = CGPoint(x: self.myImageView.bounds.width/2, y: self.myImageView.bounds.height/2)
let translation = gesture.translation(in: self.myImageView)
let crosshairGesture = gesture.view!


if uni.zoomer == 0 { uni.zoomer = 1}
crosshairGesture.center = CGPoint(x: crosshairGesture.center.x + ( translation.x *  uni.zoomer), y: crosshairGesture.center.y + ( translation.y *  uni.zoomer ))
gesture.setTranslation(CGPoint.zero, in: self.myImageView)




if crosshairGesture.center.x >= myImageView.bounds.maxX || crosshairGesture.center.x <= ( myImageView.bounds.minX + 25 ) || crosshairGesture.center.y >= myImageView.bounds.maxY  || crosshairGesture.center.y <= myImageView.bounds.minY || extractorButton.frame.contains(crosshairGesture.center) || values.frame.contains(crosshairGesture.center) {
crosshairGesture.center = orignalCenter
}


let zh =  (Scroll.contentSize.width / Scroll.frame.width) //
let zw =  (Scroll.contentSize.width / Scroll.frame.width)// tells zoom scale of height and width respectively
var oh = (Scroll.contentOffset.y +  crosshairGesture.center.y  - 25 ) / zh //
var ow = (Scroll.contentOffset.x +  crosshairGesture.center.x - 25 ) / zw //   the coordinates of the point when zoomed in
if zh == 0 || zw == 0 {
oh = Scroll.contentOffset.y +  crosshairGesture.center.y - 25
ow = Scroll.contentOffset.x +  crosshairGesture.center.x - 25
}

///  Sets the values of a label to its specific RGB values
/// - Parameter color: The color extracted in the image function is sent here so that the user can acess its data on top right corner

func valueDisplayer(_ color : UIColor) {
// Start of the RGB ShowCaser
let vc = LangViewController()
let val = vc.defaultLang
values.backgroundColor = .init(white: 1, alpha: 0.3)
values.frame = CGRect(x: myImageView.bounds.width - 90, y: myImageView.bounds.height / 20, width: 100, height: 60)
values.layer.cornerRadius = 10
values.layer.masksToBounds = true
values.numberOfLines = 3
values.lineBreakMode = .byWordWrapping
values.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 15)
values.textAlignment = .left

if truth {
// if the setting is taken for rgb values
let r = Int(color.cgColor.components![0] * 255)
let g = Int(color.cgColor.components![1] * 255)
let b = Int(color.cgColor.components![2] * 255)
if val == truth {
let stringValue = " \("RedKey".localisableString(loc: "en"))   : \(r) \r \("GreenKey".localisableString(loc: "en")) : \(g)\r \("BlueKey".localisableString(loc: "en"))  : \(b)"
let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: stringValue)
attributedString.setColor(color: UIColor.red, forText: " \("RedKey".localisableString(loc: "en"))   : \(r) \r")
attributedString.setColor(color: UIColor.green, forText:  " \("GreenKey".localisableString(loc: "en")) : \(g)\r")
attributedString.setColor(color: UIColor.systemBlue, forText: " \("BlueKey".localisableString(loc: "en"))  : \(b)")
values.attributedText = attributedString
}
else{
let stringValue = " \("RedKey".localisableString(loc: "ja"))   : \(r) \r \("GreenKey".localisableString(loc: "ja")) : \(g)\r \("BlueKey".localisableString(loc: "ja"))  : \(b)"
let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: stringValue)
attributedString.setColor(color: UIColor.red, forText: " \("RedKey".localisableString(loc: "ja"))   : \(r) \r")
attributedString.setColor(color: UIColor.green, forText:  " \("GreenKey".localisableString(loc: "ja")) : \(g)\r")
attributedString.setColor(color: UIColor.systemBlue, forText: " \("BlueKey".localisableString(loc: "ja"))  : \(b)")
values.attributedText = attributedString
}
}

else
{ // if the setting is taken for HSB values
let hs = discoveredColor?.hsba
let h = Double((hs?.hue)!)
let b = Double((hs?.brightness)!)
let s = Double((hs?.saturation)!)
if val == true{
let stringValue = " \("HueKey".localisableString(loc: "en"))   : \((360 * h).rounded()) \r \("Sat".localisableString(loc: "en")) : \((1000 * s).rounded()/10)\r \("Brt".localisableString(loc: "en"))  : \((1000 * b).rounded()/10)"
let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: stringValue)
attributedString.setColor(color: UIColor.systemTeal, forText: " \("HueKey".localisableString(loc: "en"))   : \((360 * h).rounded()) \r")
attributedString.setColor(color: UIColor.systemYellow, forText: " \("Sat".localisableString(loc: "en")) : \((1000 * s).rounded()/10)\r")
attributedString.setColor(color: UIColor.systemIndigo, forText: " \("Brt".localisableString(loc: "en"))  : \((1000 * b).rounded()/10)")
values.attributedText = attributedString
}
else{
let stringValue = " \("HueKey".localisableString(loc: "ja"))   : \((360 * h).rounded()) \r \("SaturationKey".localisableString(loc: "ja")) : \((1000 * s).rounded()/10)\r \("BrightnessKey".localisableString(loc: "ja"))  : \((1000 * b).rounded()/10)"
let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: stringValue)
attributedString.setColor(color: UIColor.systemTeal, forText: " \("HueKey".localisableString(loc: "ja"))   : \((360 * h).rounded()) \r")
attributedString.setColor(color: UIColor.systemYellow, forText: " \("SaturationKey".localisableString(loc: "ja")) : \((1000 * s).rounded()/10)\r")
attributedString.setColor(color: UIColor.systemIndigo, forText: " \("BrightnessKey".localisableString(loc: "ja"))  : \((1000 * b).rounded()/10)")
values.attributedText = attributedString
}
}


self.view.addSubview(values)
//end of RGB Showcaser
}

///Sets the image point for the  pixel function and displays the color accordingly
func img(){
let image = myImageView.image
let finalPoint =  CGPoint(x: ow  , y: oh  )
discoveredColor = image?.pixel(point: finalPoint, sourceView: myImageView)
dataBaseColor = discoveredColor ?? UIColor.black
valueDisplayer(discoveredColor ?? UIColor.black)
extractorButtonShell.fillColor =  discoveredColor?.withAlphaComponent(0.75).cgColor
nameOfColor.text = discoveredColor?.name
Lab.text = discoveredColor?.hexString

}
img()
}



}


// all the extensions we used here : credits go to the users at stackoverflow, hackingwithswift and github
extension ViewController: SwiftyGifDelegate {
func gifDidStop(sender: UIImageView) {
logoAnimationView.isHidden = true
}
}
extension NSMutableAttributedString {

func setColor(color: UIColor, forText stringValue: String) {
let range: NSRange = self.mutableString.range(of: stringValue, options: .caseInsensitive)
self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
}

}
extension UIView {
// extension to make the crosshair shake a bit to "stimulate the user."
func shake(completion: (() -> Void)? = nil) {

let speed = 0.75
let time = ( 1 * speed - 0.15)
let timeFactor = CGFloat(time / 4)
let animationDelays = [timeFactor, timeFactor * 2, timeFactor * 3]

let shakeAnimator = UIViewPropertyAnimator(duration: time, dampingRatio: 0.3)
// left, right, left, center
shakeAnimator.addAnimations({
self.transform = CGAffineTransform(translationX: 20, y: 0)
})
shakeAnimator.addAnimations({
self.transform = CGAffineTransform(translationX: -20, y: 0)
}, delayFactor: animationDelays[0])
shakeAnimator.addAnimations({
self.transform = CGAffineTransform(translationX: 20, y: 0)
}, delayFactor: animationDelays[1])
shakeAnimator.addAnimations({
self.transform = CGAffineTransform(translationX: 0, y: 0)
}, delayFactor: animationDelays[2])
shakeAnimator.startAnimation()

shakeAnimator.addCompletion { _ in
completion?()
}

shakeAnimator.startAnimation()
}
}
extension UIImage {

/// Gives color of the pixel in context by taking the bitmap information of the image
/// - Parameter point: Coordinates of the point wrt to the source view
/// - Parameter sourceView: view in which the image is displayed
func pixel(point: CGPoint, sourceView: UIView ) -> UIColor {
let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

context!.translateBy(x: -point.x, y: -point.y)

sourceView.layer.render(in: context!)
let color: UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                             green: CGFloat(pixel[1])/255.0,
                             blue: CGFloat(pixel[2])/255.0,
                             alpha: CGFloat(pixel[3])/255.0)
pixel.deallocate()
return color
}

}


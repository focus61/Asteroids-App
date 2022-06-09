//  RegistrationViewController.swift
//  Peshkariki
//  Created by Gamid on 17.01.2020.
//  Copyright © 2020 Peshkariki. All rights reserved.

import UIKit
import ReCaptcha

//MARK: - Registration View Controller
class RegistrationViewController: UIViewController  {
    
    // MARK: =  Variables
    private var userType = 2
    private var userAvatar: Data?
    private var city = "Выберите город"
    private var cities = [String]()
    private var recaptcha: ReCaptcha!
    private var locale: Locale?
    private var endpoint = ReCaptcha.Endpoint.default
    private struct Constants {
        static let webViewTag = 123
        static let testLabelTag = 321
    }
    
    // MARK: = IBOutlets
    @IBOutlet weak var phoneNumberTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var registrationButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var cityButton: UIButton!
    @IBOutlet weak var courierTypeLabel: UILabel!
    @IBOutlet weak var clientTypeLabel: UILabel!
    
    // MARK: = ViewDidLoad Function
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNumberTF.placeholder = "+7(256)325-63-22"
        addTapGestureToHideKeyboard()
        setupButtons()
        phoneNumberTF.delegate = self
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        setupReCaptcha()
    }
    private func textLimit(existingText: String?, newText: String, limit: Int) -> Bool {
        let text = existingText ?? ""
        let isAtLimit = text.count + newText.count <= limit
        return isAtLimit
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return self.textLimit(existingText: textField.text, newText: string, limit: 12)
    }
    

    //MARK: = ViewWillAppear Function
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cityButton.setTitle(city, for: .normal)
    }
    
    // MARK: = Image Tapped Function
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        showActionSheet()
    }
    
    // MARK: = UserTypeChanged Function (For styling depends on client/currier)
    @IBAction func userTypeChanged(_ sender: UISwitch) {
        if sender.isOn {
            clientTypeLabel.textColor = .red
            courierTypeLabel.textColor = .black
            userType = 2
        } else {
            clientTypeLabel.textColor = .black
            courierTypeLabel.textColor = .red
            userType = 1
        }
    }
    // MARK: = Setup ReCaptcha Function
    private func setupReCaptcha() {
        // swiftlint:disable:next force_try
        recaptcha = try! ReCaptcha(endpoint: endpoint, locale: locale)
        recaptcha.configureWebView { [weak self] webview in
            guard let self = self else { return }
            webview.tag = Constants.webViewTag
            webview.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(webview)
            webview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40).isActive = true
            webview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40).isActive = true
            webview.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
            webview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
        }
    }
    
    
    @IBAction func registrationButtonToched() {
        setupReCaptcha()
        recaptcha.didFinishLoading {
            print("did finish loading")
        }
        recaptcha?.validate(on: view) { [weak self] (result: ReCaptchaResult) in
            if let cell = self?.view.viewWithTag(Constants.webViewTag) {
                cell.removeFromSuperview()
            }
        }
        
        let userPhoneNumber = phoneNumberTF.text ?? ""
        let password = passwordTF.text ?? ""
        
        let city = cityButton.title(for: .normal) ?? ""
        
        
        if city.isEmpty || city == "Выберите город" {
            let alert = Utils.setAlertController(with: "Выберите город")
            present(alert, animated: true)
            return
        }
        if userPhoneNumber.isEmpty {
            let alert = Utils.setAlertController(with: "Введите номер телефона")
            present(alert, animated: true)
            return
        }
        if password.isEmpty {
            let alert = Utils.setAlertController(with: "Введите пароль")
            present(alert, animated: true)
            return
        }
        
        
        let userCity = Utils.getCitiesKey(of: city)
        
        let newUser = NewAccount(phoneNumber: userPhoneNumber, password: password, userType: userType, userCity: userCity, regCheckLic: 1)
        NetWorkService.shared.toRegister(newUser: newUser) { [weak self] (isSucced) in
            guard let self = self else { return }
            if isSucced {
                self.performSegue(withIdentifier: "verificationSegue", sender: nil)
            } else {
                let alert = Utils.setAlertController(with: NetWorkService.shared.getMessage())
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func loginButtonTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func acceptButtonTouched() {
        if acceptButton.imageView?.tintColor == UIColor.red {
            setupAcceptButton(imageName: "circleicon", tintColor: UIColor.black)
            registrationButton.isEnabled = false
            registrationButton.backgroundColor = .gray
        } else {
            setupAcceptButton(imageName: "circledone", tintColor: UIColor.red)
            registrationButton.isEnabled = true
            registrationButton.backgroundColor = .red
        }
    }
    
    
    @IBAction func termsOfUseButtonTouched() {
        registrationButton.isEnabled = true
        if let url = URL(string: "https://peshkariki.ru/soglashenie") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func cityChooseTouched() {
        
        NetWorkService.shared.getCities() { [weak self] (isSucced, cities) in
            guard let self = self else { return }
            if isSucced {
                guard let cities = cities else { print("Error with cities"); return }
                self.cities = cities
                self.performSegue(withIdentifier: "cityPickerSegue", sender: nil)
            } else {
                let alert = Utils.setAlertController(with: NetWorkService.shared.getMessage())
                self.present(alert, animated: true)
            }
        }
    }
    
    
    @IBAction func unwindSegueToRegistrationVC(_ segue: UIStoryboardSegue) {
        guard let cityPickerVC = segue.source as? CityPickerViewController else { return }
        city = cityPickerVC.city
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cityPickerVC = segue.destination as? CityPickerViewController {
            cityPickerVC.cities = self.cities
            cityPickerVC.segueSource = "RegistrationVC"
        }
    }
    
    // MARK: = Setup Buttons Function
    private func setupButtons() {
        registrationButton.isEnabled = false
        registrationButton.backgroundColor = .lightGray
        registrationButton.layer.cornerRadius = 10
        registrationButton.layer.masksToBounds = true
        cityButton.layer.cornerRadius = 5
        setupAcceptButton(imageName: "circleicon", tintColor: UIColor.gray)
    }
    
    private func setupAcceptButton(imageName: String, tintColor: UIColor) {
        let normalImage = UIImage(named: imageName)
        acceptButton.setImage(normalImage, for: .normal)
        acceptButton.imageView?.tintColor = tintColor
    }
    
    private func showActionSheet() {
        let cameraIcon = #imageLiteral(resourceName: "camera")
        let photoIcon = #imageLiteral(resourceName: "photo")
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let camera = UIAlertAction(title: "Камера", style: .default) { _ in
            self.choosImagePicker(source: .camera)
        }
        camera.setValue(cameraIcon, forKey: "image")
        camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        
        let photo = UIAlertAction(title: "Фото", style: .default) { _ in
            self.choosImagePicker(source: .photoLibrary)
        }
        photo.setValue(photoIcon, forKey: "image")
        photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(camera)
        actionSheet.addAction(photo)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true)
    }
    
}

extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func choosImagePicker(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
}


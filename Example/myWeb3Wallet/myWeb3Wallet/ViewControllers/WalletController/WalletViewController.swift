//
//  WalletViewController.swift
//  myWeb3Wallet
//
//  Created by Ravi Ranjan on 22/10/21.
//

import UIKit
import web3swift
class WalletViewController: UIViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var importWalletButton: UIButton!
    @IBOutlet weak var createWalletButton: UIButton!
    var _walletAddress: String {
        set{
            self.continueButton.isHidden = false
            self.walletAddressLabel.text = newValue
        }
        get {
            return self._walletAddress
        }
    }
    var _mnemonics: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createWalletButton.layer.cornerRadius = 5.0
        self.importWalletButton.layer.cornerRadius = 5.0
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func onClickCreateWallet(_ sender: UIButton) {
#if DEBUG
        print("Clicked on Create Wallet Option")
#endif
        self.createMnemonics()
        
    }
    @IBAction func onClickImportWalletButton(_ sender: UIButton) {
        print("Clicked on import Wallet Option")
        self.showImportALert()
    }
    
    @IBAction func onClickContinueButton(_ sender: UIButton) {
        print("Clicked on COntinue button")
        guard let dashboardScreen = self.storyboard?.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController else {
            #if DEBUG
            printContent("Unable to get Wallet controller")
            #endif
            return
        }
        self.navigationController?.pushViewController(dashboardScreen, animated: true)
    }
    fileprivate func showImportALert(){
        let alert = UIAlertController(title: "MyWeb3Wallet", message: "", preferredStyle: .alert)
        alert.addTextField { textfied in
            textfied.placeholder = "Enter mnemonics/private Key"
        }
        let mnemonicsAction = UIAlertAction(title: "Mnemonics", style: .default) { _ in
            print("Clicked on Mnemonics Option")
            guard let mnemonics = alert.textFields?[0].text else { return }
            print(mnemonics)
            self.nimonicTest(nimonic: mnemonics)
        }
        let privateKeyAction = UIAlertAction(title: "Private Key", style: .default) { _ in
            print("Clicked on Private Key Wallet Option")
            guard let privateKey = alert.textFields?[0].text else { return }
            print(privateKey)
            self.importWalletWith(privateKey: privateKey)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(mnemonicsAction)
        alert.addAction(privateKeyAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func nimonicTest(nimonic: String) {
        print("importedNimonic: \(nimonic)")
        let tempWalletAddress = try? BIP32Keystore(mnemonics: nimonic , prefixPath: "m/44'/77777'/0'/0")
        print(tempWalletAddress?.addresses?.first?.address as Any)
        guard let walletAddress = tempWalletAddress?.addresses?.first else {
            self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
            return
        }
        self._walletAddress = walletAddress.address
        guard let privateKey = try? tempWalletAddress?.UNSAFE_getPrivateKeyData(password: "web3swift", account: walletAddress) else {
            print("음?")
            return
        }
        print("다시 생성한 개인키: \(privateKey.toHexString())")
    }
    
    func importWalletWith(privateKey: String){
        let formattedKey = privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dataKey = Data.fromHex(formattedKey) else {
            self.showAlertMessage(title: "Error", message: "Please enter a valid Private key ", actionName: "Ok")
            return
        }
        do {
            let keystore =  try EthereumKeystoreV3(privateKey: dataKey)
            if let myWeb3KeyStore = keystore {
                let manager = KeystoreManager([myWeb3KeyStore])
                let address = keystore?.addresses?.first
#if DEBUG
                print("Address :::>>>>> ", address as Any)
                print("Address :::>>>>> ", manager.addresses as Any)
#endif
                let walletAddress = manager.addresses?.first?.address
                self.walletAddressLabel.text = walletAddress ?? "0x"
                
                print(walletAddress as Any)
            } else {
                print("error")
            }
        } catch {
#if DEBUG
            print("error creating keyStrore")
            print("Private key error.")
#endif
            let alert = UIAlertController(title: "Error", message: "Please enter correct Private key", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .destructive)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
        
        
        
    }
    func importWalletWith(mnemonics: String) {
        let walletAddress = try? BIP32Keystore(mnemonics: mnemonics , prefixPath: "m/44'/77777'/0'/0")
        print(walletAddress?.addresses as Any)
        self.walletAddressLabel.text = "\(walletAddress?.addresses?.first?.address ?? "0x")"
        
    }
    
    
}
extension WalletViewController {
    
    fileprivate func createMnemonics(){
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let web3KeystoreManager = KeystoreManager.managerForPath(userDir + "/keystore") // 키스토어 매니저 생성
        do {
            if (web3KeystoreManager?.addresses?.count ?? 0 >= 0) { // 처음에는 0이 뜰것
                let tempMnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english) // 니모닉 만들기
                guard let tMnemonics = tempMnemonics else {
                    self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                self._mnemonics = tMnemonics
                print(_mnemonics)
                let tempWalletAddress = try? BIP32Keystore(mnemonics: self._mnemonics , prefixPath: "m/44'/77777'/0'/0") // 아까 만든 니모닉으로 시드, 키스토어 어드레스를 만든다. 패스워드는 디폴트로 하면 안에 하드코딩 되어있음. 이부분에서 시간이 좀 걸리는듯.
                // 결국 니모닉데이터 + 니모닉패스워드로 Seed를 만든다. 패스워드는 그냥 패스워드와 니모닉패스워드 두개가 있음
                // 내부적으로 Seed를 이용해 HDNode를 생성. HDNode안에는 개인키와 공개키 키쌍을 생성한다
                print(tempWalletAddress?.addresses?.first?.address as Any)
                guard let walletAddress = tempWalletAddress?.addresses?.first else {
                    self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                self._walletAddress = walletAddress.address
                let privateKey = try tempWalletAddress?.UNSAFE_getPrivateKeyData(password: "web3swift", account: walletAddress)
#if DEBUG
                print(privateKey as Any, "Is the private key")
#endif
                let keyData = try? JSONEncoder().encode(tempWalletAddress?.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keyData, attributes: nil)
            }
        } catch {
            
        }
        
    }
}
extension UIViewController {
    func showAlertMessage(title: String = "MyWeb3Wallet", message: String = "Message is empty", actionName: String = "OK") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: actionName, style: .destructive)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
    
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

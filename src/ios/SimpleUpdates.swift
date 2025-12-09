import Foundation
import UIKit

@objc(SimpleUpdates)
class SimpleUpdates: CDVPlugin {
    
    private var appStoreId: String = ""
    
    @objc(checkAndUpdate:)
    func checkAndUpdate(command: CDVInvokedUrlCommand) {
        
        // Get App Store ID from config.xml preference
        if let storedId = self.commandDelegate.settings["app_store_id"] as? String {
            appStoreId = storedId
        } else if let storedId = self.commandDelegate.settings["APP_STORE_ID"] as? String {
            appStoreId = storedId
        }
        
        // Fallback: try to get from arguments
        if appStoreId.isEmpty, command.arguments.count > 0,
           let argId = command.arguments[0] as? String, !argId.isEmpty {
            appStoreId = argId
        }
        
        guard !appStoreId.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "APP_STORE_ID not configured")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        let urlString = "https://itunes.apple.com/lookup?id=\(appStoreId)&country=il"
        
        guard let url = URL(string: urlString) else {
            let result = CDVPluginResult(status: .error, messageAs: "Invalid URL")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                let result = CDVPluginResult(status: .error, messageAs: "CHECK_FAILED: \(error.localizedDescription)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let storeVersion = results.first?["version"] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "CHECK_FAILED: Invalid response")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            
            if Self.isVersion(currentVersion, olderThan: storeVersion) {
                DispatchQueue.main.async {
                    self.showMandatoryUpdateScreen(storeVersion: storeVersion)
                    let result = CDVPluginResult(status: .ok, messageAs: "UPDATE_SHOWN")
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            } else {
                let result = CDVPluginResult(status: .ok, messageAs: "NO_UPDATE")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
            
        }.resume()
    }
    
    // Full screen mandatory update block
    private func showMandatoryUpdateScreen(storeVersion: String) {
        
        guard let rootVC = self.viewController else { return }
        
        // Remove existing overlay if present
        if let existingOverlay = rootVC.view.viewWithTag(999999) {
            existingOverlay.removeFromSuperview()
        }
        
        let overlay = UIView(frame: rootVC.view.bounds)
        overlay.backgroundColor = UIColor.white
        overlay.tag = 999999  // unique tag to avoid duplication
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Icon container
        let iconLabel = UILabel()
        iconLabel.text = "⬆️"
        iconLabel.font = UIFont.systemFont(ofSize: 60)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Message label
        let label = UILabel()
        label.text = "נדרש עדכון לגרסה החדשה (\(storeVersion)) כדי להמשיך להשתמש באפליקציה."
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Update button
        let button = UIButton(type: .system)
        button.setTitle("עדכן עכשיו", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(openAppStore), for: .touchUpInside)
        
        overlay.addSubview(iconLabel)
        overlay.addSubview(label)
        overlay.addSubview(button)
        rootVC.view.addSubview(overlay)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -100),
            
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -30),
            
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            button.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openAppStore() {
        guard !appStoreId.isEmpty else { return }
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreId)") {
            UIApplication.shared.open(url)
        }
    }
    
    // Compare versions
    static func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        let a = v1.split(separator: ".").compactMap { Int($0) }
        let b = v2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x < y { return true }
            if x > y { return false }
        }
        return false
    }
}


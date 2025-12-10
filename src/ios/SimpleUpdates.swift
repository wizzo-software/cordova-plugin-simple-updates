import Foundation
import UIKit

@objc(SimpleUpdates)
class SimpleUpdates: CDVPlugin {
    
    private var appStoreId: String = ""
    private var customMessage: String? = nil
    private var customButtonText: String? = nil
    
    @objc(checkAndUpdate:)
    func checkAndUpdate(command: CDVInvokedUrlCommand) {
        
        // Reset custom properties for each call
        customMessage = nil
        customButtonText = nil
        appStoreId = ""
        
        // Get optional arguments
        // index 0: appStoreId (required)
        // index 1: fakeVersion (optional, for testing)
        // index 2: message (optional)
        // index 3: buttonText (optional)
        
        var fakeVersion: String? = nil
        
        // Get appStoreId from arguments (index 0)
        if command.arguments.count > 0 {
            if let argId = command.arguments[0] as? String, !argId.isEmpty {
                appStoreId = argId
                print("📱 DEBUG: Using App Store ID: \(argId)")
            }
        }
        
        // Get fake version (index 1)
        if command.arguments.count > 1 {
            // Handle both String and NSNull
            if let fake = command.arguments[1] as? String, !fake.isEmpty {
                fakeVersion = fake
                print("🧪 DEBUG: Using fake version: \(fake)")
            }
        }
        
        // Get custom message (index 2)
        if command.arguments.count > 2 {
            if let msg = command.arguments[2] as? String, !msg.isEmpty {
                customMessage = msg
                print("💬 DEBUG: Using custom message: \(msg)")
            }
        }
        
        // Get custom button text (index 3)
        if command.arguments.count > 3 {
            if let btnText = command.arguments[3] as? String, !btnText.isEmpty {
                customButtonText = btnText
                print("🔘 DEBUG: Using custom button text: \(btnText)")
            }
        }
        
        // If APP_STORE_ID not configured, just return NO_UPDATE (don't error - allows Android-only usage)
        guard !appStoreId.isEmpty else {
            let result = CDVPluginResult(status: .ok, messageAs: "NO_UPDATE")
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
            
            // Use fake version if provided (for testing), otherwise use real version
            let currentVersion = fakeVersion ?? (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")
            print("🔍 DEBUG: Current version: '\(currentVersion)', Store version: '\(storeVersion)'")
            print("🔍 DEBUG: fakeVersion was: \(fakeVersion ?? "nil")")
            print("🔍 DEBUG: Comparing versions...")
            
            let needsUpdate = Self.isVersion(currentVersion, olderThan: storeVersion)
            print("🔍 DEBUG: Needs update: \(needsUpdate)")
            
            if needsUpdate {
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
        
        // App Icon
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 20
        iconView.layer.masksToBounds = true
        
        // Load app icon from bundle
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            iconView.image = UIImage(named: lastIcon)
            print("✅ Using app icon: \(lastIcon)")
        } else {
            // Fallback: Try common icon names
            if let appIcon = UIImage(named: "AppIcon") {
                iconView.image = appIcon
                print("✅ Using AppIcon from assets")
            } else if let appIcon = UIImage(named: "Icon-60@3x") {
                iconView.image = appIcon
                print("✅ Using Icon-60@3x")
            } else {
                print("⚠️ Could not load app icon, using placeholder")
                // Create a simple placeholder
                let size = CGSize(width: 120, height: 120)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                UIColor.systemBlue.setFill()
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 20).fill()
                iconView.image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
        // Message label
        let label = UILabel()
        let defaultMessage = "A new version (\(storeVersion)) is required to continue using the app."
        label.text = customMessage?.replacingOccurrences(of: "{version}", with: storeVersion) ?? defaultMessage
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Update button
        let button = UIButton(type: .system)
        button.setTitle(customButtonText ?? "Update Now", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(openAppStore), for: .touchUpInside)
        
        overlay.addSubview(iconView)
        overlay.addSubview(label)
        overlay.addSubview(button)
        rootVC.view.addSubview(overlay)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -100),
            iconView.widthAnchor.constraint(equalToConstant: 120),
            iconView.heightAnchor.constraint(equalToConstant: 120),
            
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 30),
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


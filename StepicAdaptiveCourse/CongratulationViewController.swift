//
//  CongratulationViewController.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 20.07.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

class CongratulationViewController: UIViewController {

    enum CongratulationType {
        var congratulationText: String {
            switch self {
            case .level(let level):
                return String(format: NSLocalizedString("NewLevelCongratulationText", comment: ""), "\(level)")
            }
        }
        var shareText: String {
            switch self {
            case .level(let level):
                return String(format: NSLocalizedString("NewLevelCongratulationShareText", comment: ""), "\(level)", "\(CongratulationViewController.shareAppName)")
            }
        }
        var analyticsKey: String {
            switch self {
            case .level(_):
                return AnalyticsEvents.Adaptive.Achievement.level
            }
        }
        var analyticsParameters: [String: Any]? {
            switch self {
            case .level(let level):
                return ["level": level]
            }
        }
        
        case level(level: Int)
    }
    
    private static let shareAppName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Stepik"
    
    var continueHandler: (() -> ())?
    
    var congratulationType: CongratulationType!
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    
    @IBAction func onShareButtonClick(_ sender: Any) {
        guard let url = URL(string: "https://itunes.apple.com/app/id\(StepicApplicationsInfo.appId)") else {
            return
        }
        
        AnalyticsReporter.reportEvent(AnalyticsEvents.Adaptive.Achievement.shareClicked)
        let activityVC = UIActivityViewController(activityItems: [congratulationType.shareText, url], applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityType.airDrop]
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }
    
    @IBAction func onContinueButtonClick(_ sender: Any) {
        dismiss(animated: true, completion: { [weak self] in
            self?.continueHandler?()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorize()

        AnalyticsReporter.reportEvent(congratulationType.analyticsKey, parameters: congratulationType.analyticsParameters)
        
        localize()
        textLabel.text = congratulationType.congratulationText
    }

    fileprivate func localize() {
        shareButton.setTitle(NSLocalizedString("ShareAchievement", comment: ""), for: .normal)
        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
    }

    fileprivate func colorize() {
        continueButton.tintColor = StepicApplicationsInfo.adaptiveMainColor
        shareButton.tintColor = StepicApplicationsInfo.adaptiveMainColor
    }
}

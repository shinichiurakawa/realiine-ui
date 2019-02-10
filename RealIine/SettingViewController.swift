//
//  SettingViewController.swift
//  RealIine
//
//  Created by 浦川 真一 on 2018/12/15.
//  Copyright © 2018 Swift-Beginners. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    let settingArray : [Int] = [1,2,3,4,5]
    
    let settingKey = "user_id"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userSettingPicker.delegate = self
        userSettingPicker.dataSource = self
        
        // UserDefaultの選択を合わせる
        let settings = UserDefaults.standard
        let userId = settings.integer(forKey: settingKey)
        
        for row in 0..<settingArray.count {
            if settingArray[row] == userId {
                userSettingPicker.selectRow(row, inComponent: 0, animated: true)
            }
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBOutlet weak var userSettingPicker: UIPickerView!
    
    @IBAction func decisionButtonAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return settingArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return String(settingArray[row])
    }
    
    func pickerView(_pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) {
        let settings = UserDefaults.standard
        settings.setValue(settingArray[row], forKey: settingKey)
        settings.synchronize()
    }
}

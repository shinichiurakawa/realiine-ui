//
//  ViewController.swift
//  RealIine
//
//  Created by 浦川 真一 on 2018/12/15.
//  Copyright © 2018 Swift-Beginners. All rights reserved.
//

import UIKit
import AWSS3

class ViewController: UIViewController, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var timer : Timer?
    
    var count = 0
    
    let settingKey = "user_id"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Table ViewのdataSourceを設定
        tableView.dataSource = self
        
        let settings = UserDefaults.standard
        settings.register(defaults: [settingKey: 1])
    }
    
    @IBOutlet weak var userIdLabel: UILabel!
    
    @IBOutlet weak var timeCountLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // 自撮り
    @IBAction func selfyButtonAction(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("カメラは利用できます")
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        } else {
            print("カメラは利用できません")
        }
    }
    
    private func generateImageUrl(_ uploadImage: UIImage) -> URL {
        let imageURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingFormat("upload.jpg"))
        if let jpegData = uploadImage.jpegData(compressionQuality:0.003) {
            try! jpegData.write(to: imageURL, options: [.atomicWrite])
        }
        return imageURL
    }
    
    // Upload image to s3
    func uploadImageToS3(_ uiImage: UIImage) {
        print("uploading...")
        let settings = UserDefaults.standard
        let userId = settings.integer(forKey: settingKey)
        
        let transferManager = AWSS3TransferManager.default()
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = "hd15-01-dev"
        //uploadRequest?.key = String("dev/"+startMode!+"_"+primaryKey!+".jpg")
        uploadRequest?.key = String("dev/selfy-\(userId).jpg")
        uploadRequest?.key = String("dev/selfy-3.jpg")
        uploadRequest?.contentType = "image/jpeg"
        uploadRequest?.acl = .publicRead
        uploadRequest?.body = generateImageUrl(uiImage)
        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread()) { (task: AWSTask) -> Any? in
            if task.error != nil {
                print("----------------------------------")
                print(task.error!)
                print("----------------------------------")
            }
            return nil
        }
        print("uploaded...")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let uploadImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage  else {return}
        // start
        uploadImageToS3(uploadImage)
        // end
        dismiss(animated: true, completion: nil)
    }
    
    // 更新ボタン
    @IBAction func updateButtonAction(_ sender: Any) {
        if let nowTimer = timer {
            if nowTimer.isValid == true {
                return
            }
        }
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(self.timerInterrupt(_:)),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    // USER選択
    @IBAction func settingButtonAction(_ sender: Any) {
        // timer実行中はタイマー停止する
        if let nowTimer = timer {
            if nowTimer.isValid == true {
                nowTimer.invalidate()
            }
        }
        // 画面遷移を行う
        performSegue(withIdentifier: "goSetting", sender: nil)
    }
    
    // 停止ボタン
    @IBAction func stopButtonAction(_ sender: Any) {
        if let nowTimer = timer {
            if nowTimer.isValid == true {
                nowTimer.invalidate()
            }
        }
    }
    
    func displayUpdate() -> Int {
        let settings = UserDefaults.standard
        let userId = settings.integer(forKey: settingKey)
        userIdLabel.text = "USER ID : \(userId)"
        searchPerson(userId: userId)
        self.tableView.reloadData()
        return userId
    }
    
    // 経過時間の処理
    @objc func timerInterrupt(_ timer: Timer) {
        count += 1
        timeCountLabel.text = "\(count)秒実行中"
        
        // awsからリストを取得する
        // Table Viewの更新
        displayUpdate()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        count = 0
        _ = displayUpdate()
    }
 
    struct ItemJson : Codable {
        // appId
        let appId: String?
        let appKey: String?
        let id: Int?
        let actionIine: Int?
        let fashionIine: Int?
        let latitude: Double?
        let longitude: Double?
    }
    
    var searchResultList : [(appId: String, appKey: String, id: Int, actionIine: Int, fashionIine: Int, latitude: Double, longitude: Double)] = []
    
    struct ResultJson: Codable {
        let item: [ItemJson]?
    }
    
    
    func searchPerson(userId : Int) {
        let urlString = "xxx-your_api-xxx"
        let request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // set the request-body(JSON)
        let encoder: JSONEncoder = JSONEncoder()
    
        let itemJson = ItemJson(appId: "xxx-your-appid-xxx", appKey: "xxx-your-app-key-xxx", id: userId, actionIine: 0, fashionIine: 0, latitude: 35.7301927, longitude: 139.7071345)

        
        do {
            let enc_json = try encoder.encode(itemJson)
            print(enc_json)
            request.httpBody = enc_json
                //try request.httpBody = encoder.encode(itemJson)
                let task:URLSessionDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data,response,error) -> Void in
                    let decoder = JSONDecoder()
                    do {
                        let json = try decoder.decode(ResultJson.self, from: data!)
                        //print(json)
                        if let items = json.item {
                            // 検出した人リストを初期化
                            self.searchResultList.removeAll()
                            for item in items {
                                if let appId = item.appId, let appKey = item.appKey, let id = item.id, let actionIine = item.actionIine, let fashionIine = item.fashionIine, let latitude = item.latitude, let longitude = item.longitude {
                                    let searchResult = (appId,appKey,id,actionIine,fashionIine,latitude,longitude)
                                    self.searchResultList.append(searchResult)
                                }
                            }
                            // Table Viewを更新する
                            self.tableView.reloadData()
                            
                            if let searchResultDbg = self.searchResultList.first {
                                print("--------")
                                print("searchResultList[0] = \(searchResultDbg)")
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                })
            task.resume()
        } catch {
            print(error.localizedDescription)
        }
        



        
    }
    
    // Cellの総数を返すdatasourceメソッド、必ず記述
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultList.count
    }
    
    // Celに値を設定するdatasourceメソッド、必ず記述する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   
        let cell = tableView.dequeueReusableCell(withIdentifier: "personCell", for: indexPath)
        cell.textLabel?.text = " 行動：\(searchResultList[indexPath.row].actionIine)   装い：\(searchResultList[indexPath.row].fashionIine)"
        // 画像を取得
        
        
        let image_url = "your-s3-uri-\(searchResultList[indexPath.row].id).jpg"
        print(image_url)
        let url = URL(string: image_url)
        let session = URLSession(configuration: .default)
        let download = session.dataTask(with: url!) { (data, response, error) in
            if (response as? HTTPURLResponse) != nil {
                if let imageData = data {
                    cell.imageView?.image = UIImage(data: imageData)
                }
            }
        }
        download.resume()
/*
        if let imageData = try? Data(contentsOf: URL(string: image)) {
            cell.imageView?.image = UIImage(data: imageData)
        }
  */
        
        
        return cell
    }
    
}


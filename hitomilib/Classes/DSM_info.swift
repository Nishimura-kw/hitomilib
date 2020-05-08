//
//  DSM_info.swift
//  hitomiApp
//
//  Created by 西村祐大 on 2020/04/07.
//  Copyright © 2020 西村祐大. All rights reserved.
//  調整中です。

import Foundation

public class DSM_info :NSObject{
    
    static let sharedDataSingleton = DSM_info()
    
    /// DSM ステータス
    public var volumeLv:Int = 0                         // 音量 レベル
    public var sensitivityLv:Int = 0                    // 居眠り運転の検出感度レベル レベル
    public var att_check_on_off:Bool = false            // わき見運転検出 ON/OFF
    public var speed_check_on_off:Bool = false          // 車速連動機能 ON/OFF
    public var ver:String = ""                          // バージョン
    
    /// 顔データ
    public var drowsy_check:Bool = false
    public var attention_check:Bool = false
    public var face_area_x_potion:Int = 0
    public var face_area_y_potion:Int = 0
    public var face_area_widht:Int = 0
    public var face_area_height:Int = 0
    public var face_direction_left_right:String = ""
    public var face_direction_up_down:String = ""
    
    let UIID_GATT_SERVICES = ["4880C12C-FDCB-4077-8920-A450D7F9B907"]
    let UIID_GATT_CHARACTERISTIC = ["FEC26EC4-6D71-4442-9F81-55BC21D658D6"]
    let UIID_CHARACTERISTIC_TRANSFER_DATA = "FEC26EC4-6D71-4442-9F81-55BC21D658D6"
    
    /**
    * @brief DSM_infoへ値を保存する関数
    * @return DSM_info セットするクラス
    */
    public class func setObject() -> DSM_info{
        return DSM_info.sharedDataSingleton
    }
    
    /**
    * @brief 命令を送信する関数
    * @param[in] SendMessage 送信する命令
    * @param[in] blehelper 送信を実行するサービス
    * @details 命令を送信して、送信した内容をログファイルへ書き込む関数「writeLog(String)」へ 渡す関数
    */
    public func sendData(SendMessage: [Int], blehelper: BluetoothLeService) {
        var byteArray:[UInt8] = []
        for data in SendMessage {
            let ivBytes = UInt8(data)
            byteArray+=[ivBytes]
        }
        
        let dataToSend = Data(byteArray)
        
        print("送信Byte数：\(dataToSend)")
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy/MM/dd Hms", options: 0, locale: Locale(identifier: "ja_JP"))
        let rialTime = dateFormatter.string(from: date)
        WriteLog().writeLogFile(writeData:" \(rialTime) [tx]：\(dataToSend.withUnsafeBytes {[UInt8](UnsafeBufferPointer(start: $0, count: dataToSend.count))})\n")
        
        print("送信したもの：\(dataToSend.withUnsafeBytes {[UInt8](UnsafeBufferPointer(start: $0, count: dataToSend.count))})")
        try? blehelper.write(data: dataToSend, characteristicsUUID: UIID_CHARACTERISTIC_TRANSFER_DATA)
    }
    
    /**
     * @brief 音量を送信する際に実行する関数
     * @param[in] volume 音量
     * @param[in] blehelper 送信を実行するサービス
     */
    func vol_selected(vol:Int,blehelper: BluetoothLeService) {
        print("現在の音量は \(vol) ")
        sendData(SendMessage: [60,vol,0,0,0,0,0,0],blehelper: blehelper)
    }
    
    /**
     * @brief 検出感度を送信する際に実行する関数
     * @param[in] sensitivity 検出感度
     * @param[in] blehelper 送信を実行するサービス
     */
    func sens_selected(sens:Int,blehelper: BluetoothLeService) {
        print("現在の検出感度は \(sens) ")
        sendData(SendMessage: [61,sens,0,0,0,0,0,0],blehelper: blehelper)
    }
    
    /**
     * @brief わき見検出機能ON/OFFを送信する際に実行する関数
     * @param[in] state スイッチの状態
     * @param[in] blehelper 送信を実行するサービス
     */
    func att_switch_state_chenge(att_switch_state :Bool,blehelper: BluetoothLeService) {
        var speed_check:Int = 0
        if speed_check_on_off {
            speed_check = 1
        }else{
            speed_check = 0
        }
        
        if(att_switch_state){
            sendData(SendMessage: [62,1,speed_check,0,0,0,0,0], blehelper: blehelper)
        }else{
            sendData(SendMessage: [62,0,speed_check,0,0,0,0,0], blehelper: blehelper)
        }
    }
    
    /**
     * @brief 車速機能スイッチの状態が変更された時に実行される関数
     * @param[in] state スイッチの状態
     * @param[in] blehelper 送信を実行するサービス
     * @details 車速機能スイッチの状態が変更された時、変更されたスイッチの状態を送信している。
     */
    func vsi_sw_state_change(vsi_sw_state :Bool,blehelper: BluetoothLeService) {
        var att_check:Int = 0
        if att_check_on_off {
            att_check = 1
        }else{
            att_check = 0
        }
        if vsi_sw_state{
            sendData(SendMessage: [62,att_check,1,0,0,0,0,0], blehelper: blehelper)
        }else{
            sendData(SendMessage: [62,att_check,0,0,0,0,0,0], blehelper: blehelper)
        }
    }
}

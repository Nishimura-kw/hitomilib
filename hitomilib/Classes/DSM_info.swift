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
    
    /**
    * @brief DSM_infoへ値を保存する関数
    * @return DSM_info セットするクラス
    */
    public class func setObject() -> DSM_info{
        return DSM_info.sharedDataSingleton
    }
}

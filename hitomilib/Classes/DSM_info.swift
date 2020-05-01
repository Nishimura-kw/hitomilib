//
//  DSM_info.swift
//  hitomiApp
//
//  Created by 西村祐大 on 2020/04/07.
//  Copyright © 2020 西村祐大. All rights reserved.
//  調整中です。

import Foundation

private func _releaseSingleton() {
  DSM_info._sharedDataSingleton = nil
}

class DSM_info :NSObject{
    
    fileprivate static var _sharedDataSingleton: DSM_info? = nil

    public static var sharedDataSingleton: DSM_info {
      if _sharedDataSingleton == nil {
        _sharedDataSingleton = DSM_info()
        atexit({ _releaseSingleton = nil })
      }
      return _sharedDataSingleton!
    }
    
    /// DSM ステータス
    var volumeLv:Int = 0                         // 音量 レベル
    var sensitivityLv:Int = 0                    // 居眠り運転の検出感度レベル レベル
    var att_check_on_off:Bool = false            // わき見運転検出 ON/OFF
    var speed_check_on_off:Bool = false          // 車速連動機能 ON/OFF
    var ver:String = ""                          // バージョン
    
    /// 顔データ
    var drowsy_check:Bool = false
    var attention_check:Bool = false
    var face_area_x_potion:Int = 0
    var face_area_y_potion:Int = 0
    var face_area_widht:Int = 0
    var face_area_height:Int = 0
    var face_direction_left_right:String = ""
    var face_direction_up_down:String = ""
    
    /**
    * @brief DSM_infoへ値を保存する関数
    * @return DSM_info セットするクラス
    */
    class func setObject() -> DSM_info{
        return DSM_info.sharedDataSingleton
    }
}

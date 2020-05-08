//
//  WriteLog.swift
//  hitomiApp
//
//  Created by 西村祐大 on 2020/05/08.
//  Copyright © 2020 西村祐大. All rights reserved.
//

import Foundation
public class WriteLog :NSObject{
    let saveFileName = "hitomi_Log.txt"
    /**
    * @brief ログファイルへ書き込む関数
    * @param[in] writeData 書き込み内容
    * @details アプリのドキュメントフォルダの「SAVEDATA」フォルダ(なければぞ自動生成される)の saveFileName(hitomi_Log.txt)へ書き込む
    */
    func writeLogFile(writeData:String){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePath = documentsPath + "/SAVEDATA/" + saveFileName
        print("\(filePath)")
        let file = FileHandle(forWritingAtPath: filePath)!
        let contentData = writeData.data(using: .utf8)!
        file.seekToEndOfFile()
        file.write(contentData)
        file.closeFile()
    }
    
}

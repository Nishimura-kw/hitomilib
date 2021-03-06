//
//  WriteLog.swift
//  hitomiApp
//
//  Created by 西村祐大 on 2020/05/08.
//  Copyright © 2020 西村祐大. All rights reserved.
//

import Foundation

@objcMembers public class WriteLog :NSObject{
    let saveFileName = "hitomi_Log.txt"
    let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    /**
     * @brief ログファイルのフォルダを作成する関数
     */
    public func folderSetup(){
        let logsPath = documentsPath.appendingPathComponent("SAVEDATA")
        let saveFilePath = documentsPath.appendingPathComponent("SAVEDATA/\(saveFileName)")
        
        do {
            try FileManager.default.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        
        if( FileManager.default.fileExists( atPath: saveFilePath!.path ) ) {
        } else {
            FileManager.default.createFile(atPath: saveFilePath!.path, contents: nil, attributes: nil)
        }
    }
    
    /**
     * @brief ログファイルへ書き込む関数
     * @param[in] writeData 書き込み内容
     * @details アプリのドキュメントフォルダの「SAVEDATA」フォルダ(なければぞ自動生成される)の saveFileName(hitomi_Log.txt)へ書き込む
     */
    public func writeLogFile(_ writeData:String){
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

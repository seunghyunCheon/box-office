//
//  BoxOfficeItem.swift
//  BoxOffice
//
//  Created by vetto, brody on 23/03/27.
//

import UIKit

struct BoxOfficeItem: Identifiable {
    let id = UUID()
    let code: String
    let rank: String
    let rankIncrement: String
    let rankOldAndNew: String
    let title: String
    let audienceCount: String
    let audienceAccumulationCount: String
    
    init(code: String,
         rank: String,
         rankIncrement: String,
         rankOldAndNew: String,
         title: String,
         audienceCount: String,
         audienceAccumulationCount: String
    ) {
        self.code = code
        self.rank = rank
        self.rankIncrement = rankIncrement
        self.rankOldAndNew = rankOldAndNew
        self.title = title
        self.audienceCount = audienceCount
        self.audienceAccumulationCount = audienceAccumulationCount
    }
}

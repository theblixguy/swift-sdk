//
// Copyright 2022, Optimizely, Inc. and contributors 
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

class DefaultAudienceSegmentsHandler: OPTAudienceSegmentsHandler {
    
    // configurable size + timeout
    static var cacheMaxSize = 1000
    static var cacheTimeoutInSecs = 10*60
    
    static let reservedUserIdKey = "$opt_user_id"
        
    var zaiusMgr = ZaiusApiManager()
    var cache = SegmentsCache()
    let logger = OPTLoggerFactory.getLogger()

    func fetchQualifiedSegments(apiKey: String,
                                userKey: String?,
                                userValue: String,
                                segmentsToCheck: [String]? = nil,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        
        let userKey = userKey ?? DefaultAudienceSegmentsHandler.reservedUserIdKey

        zaiusMgr.fetch(apiKey: apiKey,
                       userKey: userKey,
                       userValue: userValue,
                       segmentsToCheck: segmentsToCheck) { segments, err in
            completionHandler(segments, err)
        }
    }
    
}

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

class AudienceSegmentsHandler: OPTAudienceSegmentsHandler {
    var zaiusMgr = ZaiusApiManager()
    var segmentsCache: LRUCache<String, [String]>
    let logger = OPTLoggerFactory.getLogger()
    
    // cache size and timeout can be customized by injecting a subclass
    
    init(cacheSize: Int, cacheTimeoutInSecs: Int) {
        segmentsCache = LRUCache<String, [String]>(size: cacheSize, timeoutInSecs: cacheTimeoutInSecs)
    }
    
    func fetchQualifiedSegments(apiKey: String,
                                apiHost: String,
                                userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]? = nil,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        let cacheKey = makeCacheKey(userKey, userValue)

        let ignoreCache = options.contains(.ignoreCache)
        let resetCache = options.contains(.resetCache)
        
        if resetCache {
            segmentsCache.reset()
        }
        
        if !ignoreCache {
            if let segments = segmentsCache.lookup(key: cacheKey) {
                completionHandler(segments, nil)
                return
            }
        }
        
        zaiusMgr.fetch(apiKey: apiKey,
                       apiHost: apiHost,
                       userKey: userKey,
                       userValue: userValue,
                       segmentsToCheck: segmentsToCheck) { segments, err in
            if err == nil, let segments = segments {
                if !ignoreCache {
                    self.segmentsCache.save(key: cacheKey, value: segments)
                }
            }
            
            completionHandler(segments, err)
        }
    }
    
}

// MARK: - VUID

extension AudienceSegmentsHandler {
    public func register(apiKey: String,
                         apiHost: String,
                         userKey: String,
                         userValue: String,
                         completion: ((Bool) -> Void)? = nil) {
        let vuid = self.vuidManager.newVuid

        let identifiers = [
            "vuid": vuid
        ]

        odpEvent(identifiers: identifiers, kind: "experimentation:client_initialized") { success in
            if success {
                print("[ODP] vuid registered (\(vuid)) successfully")
                self.vuidManager.updateRegisteredVUID(vuid)
            }
            completion?(success)
        }
    }
    
    public func identify(apiKey: String,
                         apiHost: String,
                         userId: String, completion: ((Bool) -> Void)? = nil) {
        guard let vuid = vuidManager.vuid else {
            print("invalid vuid for identify")
            return
        }
        
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        odpEvent(identifiers: identifiers, kind: "experimentation:identified") { success in
            if success {
                print("[ODP] add idenfier (\(userId)) successfully")
                self.vuidManager.updateRegisteredUsers(userId: userId)
            }
            completion?(success)
        }
    }
    

}

// MARK: - Utils

extension AudienceSegmentsHandler {
    
    func makeCacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}

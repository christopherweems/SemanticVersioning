//
//  NSBundle+Version.swift
//  SemanticVersioning
//
//  Created by Alexander Ney on 29/03/2015.
//  Copyright (c) 2015 Alexander Ney. All rights reserved.
//

#if canImport(Darwin)

import Foundation

extension Bundle {
    public var version: Version? {

        if let bundleVersion = self.infoDictionary?[kCFBundleVersionKey as String] as? String {
            return try? Version(bundleVersion)
        } else {
            return nil
        }
    }
}

#endif

//
//  LocalImageCache.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import UIKit

final class LocalImageCache {
    static let shared = LocalImageCache()
    private var cache = NSCache<NSString, UIImage>()

    private init() {}

    func setImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }

    func getImage(for urlString: String) -> UIImage? {
        return cache.object(forKey: urlString as NSString)
    }
}

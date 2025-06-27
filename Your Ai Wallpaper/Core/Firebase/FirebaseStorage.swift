//
//  FirebaseStorage.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 07.06.2025.
//

import Foundation
import FirebaseStorage

/// An enumeration to represent potential errors that can occur when interacting with Firebase Storage.
enum StorageError: Error {
    /// Indicates that no items were found in the specified storage path.
    case noItemsFound
    /// Encapsulates an underlying error from the Firebase Storage SDK.
    case underlying(Error)
}

/// A class responsible for managing interactions with Firebase Storage.
final class StorageManager {

    /// A shared singleton instance of the `StorageManager`.
    static let shared = StorageManager()

    /// The default Firebase Storage reference.
    private let storage = Storage.storage().reference()

    /// A private initializer to enforce the singleton pattern.
    private init() {}

    /// Fetches the download URLs for all items within a specified folder in Firebase Storage.
    ///
    /// This function recursively fetches all items in a given folder and its subfolders.
    ///
    /// - Parameters:
    ///   - folderPath: The path to the folder in Firebase Storage.
    ///   - completion: A closure that is called upon completion. It returns a `Result` containing an array of `URL` objects or a `StorageError`.
    public func fetchAllImageURLs(from folderPath: String, completion: @escaping (Result<[URL], StorageError>) -> Void) {
        let folderRef = storage.child(folderPath)

        folderRef.listAll { (result, error) in
            if let error = error {
                completion(.failure(.underlying(error)))
                return
            }

            guard let result = result else {
                completion(.failure(.noItemsFound))
                return
            }

            let dispatchGroup = DispatchGroup()
            var urls = [URL]()
            var fetchError: Error?

            for item in result.items {
                dispatchGroup.enter()
                item.downloadURL { (url, error) in
                    if let error = error {
                        fetchError = error
                    } else if let url = url {
                        urls.append(url)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                if let error = fetchError {
                    completion(.failure(.underlying(error)))
                } else {
                    completion(.success(urls))
                }
            }
        }
    }
}

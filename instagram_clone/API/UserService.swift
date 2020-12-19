//
//  UserService.swift
//  instagram_clone
//
//  Created by Projects on 11/29/20.
//

import UIKit
import Firebase
import FirebaseAuth

typealias FirestoreCompletion = (Error?) -> Void

struct UserService {
    
    static func fetchUser(withUid uid: String, completion: @escaping(User) -> Void){
        COLLECTION_USERS.document(uid).getDocument { snapshot, error in
            print("DEBUG: Snapshot is \(snapshot?.data())")
  
            guard let data = snapshot?.data() else { return }
            let user = User(dictionary: data)
            completion(user)
        }
    }
    
    static func fetchUsers(completion: @escaping([User]) -> Void) {
        
        COLLECTION_USERS.getDocuments{ (snapshot, error) in
            
// Method 1
            //var users = [User]()
//            snapshot?.documents.forEach { document in
//                print("DEBUG: \(document.data())")
//                let user = User(dictionary: documet.data())
//                users.append(user)
//
//            }
//            completion(users)
            
// Method 2
            guard let snapshot = snapshot else { return }
            // map : authomatically create array of Users. $0 is placeholder for each document
            
            let users = snapshot.documents.map({ User(dictionary: $0.data())})
            completion(users)
        }
    }
    
    static func follow(uid: String, completion: @escaping(FirestoreCompletion)) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).setData([ : ]) { (error) in
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).setData([ : ], completion: completion)
        }
    }
    
    
    static func unfollow(uid: String, completion: @escaping(FirestoreCompletion)) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).delete {error in
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).delete(completion: completion)
        }
    }
    
    
    static func checkIfUserIsFollowed(uid: String, completion: @escaping(Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).getDocument { (snapshot, error) in
            guard let isFollowed = snapshot?.exists else { return }
            completion(isFollowed)
        }
    }
    
    static func fetchUserStats(uid: String, completion: @escaping(UserStats) -> Void) {
        COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments { (snapshot, _) in
            let followers = snapshot?.documents.count ?? 0
            
            COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments { (snapshot, _) in
                let following = snapshot?.documents.count ?? 0
                
                COLLECTION_POST.whereField("ownerUid", isEqualTo: uid).getDocuments { (snapshot, _) in
                    let posts = snapshot?.documents.count ?? 0
                    completion(UserStats(followers: followers, following: following, posts: posts))
                }
                
                
            }
        }
    }
}

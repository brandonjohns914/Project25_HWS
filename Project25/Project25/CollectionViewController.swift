//
//  CollectionViewController.swift
//  Project25
//
//  Created by Brandon Johns on 5/25/23.
//

import UIKit
import MultipeerConnectivity

class CollectionViewController: UICollectionViewController,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate
{
    var images = [UIImage]()
    var peerID = MCPeerID(displayName: UIDevice.current.name)                                                                    //identifies the unique users
    var mcSession: MCSession?                                                               //manages conneciton sessions
    var mcAdvertiserAssistant: MCAdvertiserAssistant?                                       // creating a session and that exists and handling invites
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action:  #selector(importPicture))  //right navigationbarbutton
        
        
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }//viewDidLoad
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return images.count                                                                                                         //number of cells
    }//numberOfSections
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)                             //"ImageView" = reuseable ID in storyboard
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView                                                                   // 1000 = the tag defined in storyboard
        {
            imageView.image = images[indexPath.item]                                                                                //view is the selected image
        }
        
        return cell
    }//collectionView
    
    @objc func importPicture()
    {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }//importPicture
    
    
    @objc func showConnectionPrompt()
    {
        let alert_controller = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        alert_controller.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))                        //start hosting image session
        alert_controller.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))                         //joing hosting session
        alert_controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))                                                        // dismiss alert
        present(alert_controller, animated: true)
    }//showConnectionPrompt
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        // 1
        guard let mcSession = mcSession else { return }
        
        // 2
        if mcSession.connectedPeers.count > 0                                                               //one peer connected
        {
            // 3
            if let imageData = image.pngData()                                                              //convert image
            {
                // 4
                do
                {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)       // try send data to peers
                }//do
                catch
                {
                    // 5
                    let alert_controller = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    alert_controller.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert_controller, animated: true)
                }//catch
            }//imageData
        }//connections
    }//imagePickerController
    
    func startHosting(action: UIAlertAction)
    {
        guard let mcSession = mcSession else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }//startHosting
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }//joinSession
    
    
    //must provide dont need code inside
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    //must provide dont need code inside
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    //must provide dont need code inside
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController)
    {
        dismiss(animated: true)
    }//didFinish
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController)
    {
        dismiss(animated: true)
    }//wasCancelled
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
            
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
            
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
    {   //pushes work to main thread
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data)
            {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }//image
        }//dispatchQueue
    }//didRecieve
    
}//collectionViewController

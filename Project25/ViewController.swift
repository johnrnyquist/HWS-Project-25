//
//  ViewController.swift
//  Project25
//
//  Created by John Nyquist on 5/13/19.
//  Copyright © 2019 Nyquist Art + Logic LLC. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController:   UICollectionViewController,
                        UINavigationControllerDelegate,
                        UIImagePickerControllerDelegate,
                        MCSessionDelegate,
                        MCBrowserViewControllerDelegate {

    //MARK:- ViewController class
    var images = [UIImage]()

    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?

    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker,
                animated: true)
    }
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others",
                                   message: nil,
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session",
                                   style: .default,
                                   handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session",
                                   style: .default,
                                   handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel",
                                   style: .cancel))
        present(ac,
                animated: true)
    }


    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25",
                                                      discoveryInfo: nil,
                                                      session: mcSession)
        mcAdvertiserAssistant?.start()
    }

    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25",
                                                session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser,
                animated: true)
    }

    //MARK:- UIViewController class
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Selfie Share"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                           target: self,
                                                           action: #selector(showConnectionPrompt))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera,
                                                            target: self,
                                                            action: #selector(importPicture))

        mcSession = MCSession(peer: peerID,
                              securityIdentity: nil,
                              encryptionPreference: .required)
        mcSession?.delegate = self
    }

    
    //MARK:- MCSessionDelegate protocol
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
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

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image,
                                    at: 0)
                self?.collectionView.reloadData()
            }
        }
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
    }


    //MARK:- MCBrowserViewControllerDelegate protocol
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }


    //MARK:- UICollectionViewDataSource protocol
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // Get the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView",
                                                      for: indexPath)

        // Get the imageView in the cell with the tag 1000, is this recursive?
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return images.count
    }


    //MARK:- UIImagePickerControllerDelegate protocol
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }

        dismiss(animated: true)

        images.insert(image,
                      at: 0)
        collectionView.reloadData()

        // 1 Check if we have an active session we can use.
        guard let mcSession = mcSession else { return }

        // 2 Check if there are any peers to send to.
        if mcSession.connectedPeers.count > 0 {
            // 3 Convert the new image to a Data object.
            if let imageData = image.pngData() {
                // 4 Send it to all peers, ensuring it gets delivered.
                do {
                    try mcSession.send(imageData,
                                       toPeers: mcSession.connectedPeers,
                                       with: .reliable)
                } catch {
                    // 5 Show an error message if there's a problem.
                    let ac = UIAlertController(title: "Send error",
                                               message: error.localizedDescription,
                                               preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK",
                                               style: .default))
                    present(ac,
                            animated: true)
                }
            }
        }
    }
}


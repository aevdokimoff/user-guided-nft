# Mobile Augmented Reality based User Guidance as a tool for Natural Feature Tracking Stabilization

This is the demo app for the paper on topic "Mobile Augmented Reality based User Guidance as a tool for Natural Feature Tracking Stabilization" (XR WEEK 2022 Conference, GI VR/AR Workshop 2022, [link](https://www.researchgate.net/publication/364647722_Mobile_Augmented_Reality_based_User_Guidance_as_a_Tool_for_Natural_Feature_Tracking_Stabilization)) developed to evaluate and demonstrate the proposed clustering-based approach for visualizing the quality of the environment for Natural Feature Tracking. The application was developed using Apple ARKit, and tested on an iPhone X running iOS 14.4.

## Abstract
Modern handheld Augmented Reality approaches based on the usage of the standard RGB cameras of smartphones and inertial measurement units make it possible to visualize virtual objects in the real-world 3D space with an acceptable accuracy for customer scenarios. However, a robust and reliable tracking, suitable for industrial scenarios is not always given since many optical circumstances effect the visual tracking quality. Especially, if the environment is homogeneous and provides not enough features for natural feature tracking (NFT), the user needs to either focus on areas with enough features or change the environment by adding supporting textures to it. Since users might not have enough insights about the internal algorithms to know, which environments are insufficient for tracking, the users need visual feedback from the system. However, in current NFT implementations such a feedback is missing. This work proposes a clustering-based approach for visualizing the quality of the environment for NFT. Then, the work introduces visual assistance functionali- ties for adjusting the tracked environment in order to stabilize natural feature tracking. The solution provides an approach on how customer-technology can be used in scenarios where the tracking accuracy requirements are more stringent.

## Usage
To run the "NFT Guide" app, clone this repository and perform the following steps:

* Run `pod install` from the `code/UserGuidedNFT` folder. You may need to install [Cocoa Pods](https://guides.cocoapods.org/using/getting-started.html).
* Open `UserGuidedNFT.xcworkspace` using Xcode 12.3 or above
* Build and run the `UserGuidedNFT` scheme on an iOS device running iOS 14.4 and above. 

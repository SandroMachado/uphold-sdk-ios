import PromiseKit
import SafariServices
import Security
import UIKit
import UpholdSdk

/// Login view controller.
class LoginViewController: UIViewController, SFSafariViewControllerDelegate {

    /// Uphold sandbox OAuth configuration.
    let CLIENT_ID: String = "8fc252a3afa269f43512e201d10ee6b98c50fc59"
    let CLIENT_SECRET: String = "8418a4046e7576e64864d880767a00470955211a"

    /// Uphold client variables.
    var client: UpholdClient?
    var state: String?

    /// View controller variables.
    @IBOutlet weak var loginButton: UIButton!
    var authorizationViewController: AuthorizationViewController?

    /**
      Starts the authorization flow.

      - parameter sender: The pressed login button.
    */
    @IBAction func didTapLoginButton(sender: AnyObject) {
        self.client = UpholdClient()
        self.loginButton.enabled = false
        let scopes: [String] = ["cards:read", "user:read", "transactions:transfer:others"]
        self.state = String(format: "oauth2:%@", NSUUID().UUIDString)

        guard let client = self.client, state = self.state else {
            self.handleError()

            return
        }

        self.authorizationViewController = client.beginAuthorization(self, clientId: self.CLIENT_ID, scopes: scopes, state: state)

        guard let authorizationViewController = self.authorizationViewController else {
            return
        }

        authorizationViewController.delegate = self
    }

    /**
      Handles authorization response and proceeds to the UserViewController.

      - parameter url: Authorization URL.
    */
    func completeAuthorization(url: NSURL) {
        let userViewController = UserViewController()

        guard let authorizationViewController = self.authorizationViewController, client = self.client, state = self.state else {
            return self.handleError()
        }

        client.completeAuthorization(authorizationViewController, clientId: self.CLIENT_ID, clientSecret: self.CLIENT_SECRET, grantType: "authorization_code", state: state, uri: url).then { (response: AuthenticationResponse) -> () in
            userViewController.bearerToken = response.accessToken

            self.presentViewController(userViewController, animated: true, completion: nil)
        }.error { (error: ErrorType) -> Void in
            self.handleError()
        }
    }

    /**
      Handles login errors.
    */
    func handleError() {
        let alertController = UIAlertController(title: String(NSLocalizedString("login-view-controller.alert-title-login-error", comment: "Login Error.")), message: String(NSLocalizedString("global.unknown-error", comment: "Something went wrong.")), preferredStyle: .Alert)
        self.loginButton.enabled = true

        alertController.addAction(UIAlertAction(title: String(NSLocalizedString("global.dismiss", comment: "Dismiss.")), style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion:nil)
    }

    /**
      Called when the user taps the done button to dismiss the Safari view.

      - parameter controller: The view controller.
    */
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        self.loginButton.enabled = true
    }

}

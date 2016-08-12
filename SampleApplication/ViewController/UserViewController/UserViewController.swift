import PromiseKit
import UIKit
import UpholdSdk

/// Logged in user view controller.
class UserViewController: UIViewController {

    @IBOutlet weak var authenticatedLabel: UILabel!

    var bearerToken: String?
    var user: User?

    /**
      Presents the user's first name and the total number of cards.
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let bearerToken = self.bearerToken else {
            self.handleError()

            return
        }

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        self.authenticatedLabel.text = String(NSLocalizedString("user-view-controller.fetching-data", comment: "Fetching data."))

        /// Instantiate UpholdClient with the bearer token.
        let client = UpholdClient(bearerToken: bearerToken)

        client.getUser().always { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }.then { (user: User) -> Promise<[Card]> in
            self.user = user

            return user.getCards()
        }.then { (cards: [Card]) -> Promise<Transaction> in
            guard let user = self.user, firstName = user.firstName else {
                return Promise<Transaction>(error: UnexpectedResponseError(message: "The user should not be nil."))
            }

            self.authenticatedLabel.text = String(format: NSLocalizedString("user-view-controller.presenting-data", comment: "Presenting data."), firstName, cards.count)

            for card in cards {
                if card.currency! == "BTC" {
                    let transactionDenominationRequest = TransactionDenominationRequest(amount: "1.0", currency: "EUR")
                    let transactionTransferRequest = TransactionTransferRequest(denomination: transactionDenominationRequest, destination: "foo@bar.com")

                    return card.createTransaction(true, transactionRequest: transactionTransferRequest)
                }
            }

            return Promise<Transaction>(error: UnexpectedResponseError(message: "The user should have a card with the BTC currency"))
        }.then({ (transaction: Transaction) -> () in
            print(transaction.id)
        }).error { (error: ErrorType) -> Void in
            self.handleError()
        }
    }

    /**
      Handles login errors.
    */
    func handleError() {
        let alertController = UIAlertController(title: String(NSLocalizedString("user-view-controller.alert-title-fetching-error", comment: "Fetching error.")), message: String(NSLocalizedString("global.unknown-error", comment: "Something went wrong.")), preferredStyle: .Alert)

        alertController.addAction(UIAlertAction(title: String(NSLocalizedString("global.dismiss", comment: "Dismiss.")), style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion:nil)
    }

}

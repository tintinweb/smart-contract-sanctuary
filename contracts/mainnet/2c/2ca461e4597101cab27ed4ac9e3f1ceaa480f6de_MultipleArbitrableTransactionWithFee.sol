/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.4.24;

 /**
 *  @authors: [@clesaege]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */


/** @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, IArbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}


/** @title IArbitrable
 *  @author Enrique Piqueras - <[email protected]>
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}


contract MultipleArbitrableTransactionWithFee is IArbitrable {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    uint8 constant AMOUNT_OF_CHOICES = 2;
    uint8 constant SENDER_WINS = 1;
    uint8 constant RECEIVER_WINS = 2;

    enum Party {Sender, Receiver}
    enum Status {NoDispute, WaitingSender, WaitingReceiver, DisputeCreated, Resolved}

    struct Transaction {
        address sender;
        address receiver;
        uint amount;
        uint timeoutPayment; // Time in seconds after which the transaction can be automatically executed if not disputed.
        uint disputeId; // If dispute exists, the ID of the dispute.
        uint senderFee; // Total arbitration fees paid by the sender.
        uint receiverFee; // Total arbitration fees paid by the receiver.
        uint lastInteraction; // Last interaction for the dispute procedure.
        Status status;
    }

    address public feeRecipient; // Address which receives a share of receiver payment.
    uint public feeRecipientBasisPoint; // The share of fee to be received by the feeRecipient, down to 2 decimal places as 550 = 5.5%.
    Transaction[] public transactions;
    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    Arbitrator public arbitrator; // Address of the arbitrator contract.
    uint public feeTimeout; // Time in seconds a party can take to pay arbitration fees before being considered unresponding and lose the dispute.


    mapping (uint => uint) public disputeIDtoTransactionID; // One-to-one relationship between the dispute and the transaction.

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Payment(uint indexed _transactionID, uint _amount, address _party);

    /** @dev To be emitted when a fee is received by the feeRecipient.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     */
    event FeeRecipientPayment(uint indexed _transactionID, uint _amount);

    /** @dev To be emitted when a feeRecipient is changed.
     *  @param _oldFeeRecipient Previous feeRecipient.
     *  @param _newFeeRecipient Current feeRecipient.
     */
    event FeeRecipientChanged(address indexed _oldFeeRecipient, address indexed _newFeeRecipient);

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _transactionID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint indexed _transactionID, Party _party);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Emitted when a transaction is created.
     *  @param _transactionID The index of the transaction.
     *  @param _sender The address of the sender.
     *  @param _receiver The address of the receiver.
     *  @param _amount The initial amount in the transaction.
     */
    event TransactionCreated(uint _transactionID, address indexed _sender, address indexed _receiver, uint _amount);

    // **************************** //
    // *    Arbitrable functions  * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev Constructor.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeRecipient Address which receives a share of receiver payment.
     *  @param _feeRecipientBasisPoint The share of fee to be received by the feeRecipient, down to 2 decimal places as 550 = 5.5%.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    constructor (
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        address _feeRecipient,
        uint _feeRecipientBasisPoint,
        uint _feeTimeout
    ) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        feeRecipient = _feeRecipient;
        // Basis point being set higher than 10000 will result in underflow, but it's the responsibility of the deployer of the contract.
        feeRecipientBasisPoint = _feeRecipientBasisPoint;
        feeTimeout = _feeTimeout;
    }

    /** @dev Create a transaction.
     *  @param _timeoutPayment Time after which a party can automatically execute the arbitrable transaction.
     *  @param _receiver The recipient of the transaction.
     *  @param _metaEvidence Link to the meta-evidence.
     *  @return transactionID The index of the transaction.
     */
    function createTransaction(
        uint _timeoutPayment,
        address _receiver,
        string _metaEvidence
    ) public payable returns (uint transactionID) {
        transactions.push(Transaction({
            sender: msg.sender,
            receiver: _receiver,
            amount: msg.value,
            timeoutPayment: _timeoutPayment,
            disputeId: 0,
            senderFee: 0,
            receiverFee: 0,
            lastInteraction: now,
            status: Status.NoDispute
        }));
        emit MetaEvidence(transactions.length - 1, _metaEvidence);
        emit TransactionCreated(transactions.length - 1, msg.sender, _receiver, msg.value);

        return transactions.length - 1;
    }

    /** @dev Calculate the amount to be paid in wei according to feeRecipientBasisPoint for a particular amount.
     *  @param _amount Amount to pay in wei.
     */
    function calculateFeeRecipientAmount(uint _amount) internal view returns(uint feeAmount){
        feeAmount = (_amount * feeRecipientBasisPoint) / 10000;
    }

    /** @dev Change Fee Recipient.
     *  @param _newFeeRecipient Address of the new Fee Recipient.
     */
    function changeFeeRecipient(address _newFeeRecipient) public {
        require(msg.sender == feeRecipient, "The caller must be the current Fee Recipient");
        feeRecipient = _newFeeRecipient;

        emit FeeRecipientChanged(msg.sender, _newFeeRecipient);
    }

    /** @dev Pay receiver. To be called if the good or service is provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amount Amount to pay in wei.
     */
    function pay(uint _transactionID, uint _amount) public {
        Transaction storage transaction = transactions[_transactionID];
        require(transaction.sender == msg.sender, "The caller must be the sender.");
        require(transaction.status == Status.NoDispute, "The transaction shouldn't be disputed.");
        require(_amount <= transaction.amount, "The amount paid has to be less than or equal to the transaction.");

        transaction.amount -= _amount;

        uint feeAmount = calculateFeeRecipientAmount(_amount);
        feeRecipient.send(feeAmount);
        transaction.receiver.send(_amount - feeAmount);

        emit Payment(_transactionID, _amount, msg.sender);
        emit FeeRecipientPayment(_transactionID, feeAmount);
    }

    /** @dev Reimburse sender. To be called if the good or service can't be fully provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amountReimbursed Amount to reimburse in wei.
     */
    function reimburse(uint _transactionID, uint _amountReimbursed) public {
        Transaction storage transaction = transactions[_transactionID];
        require(transaction.receiver == msg.sender, "The caller must be the receiver.");
        require(transaction.status == Status.NoDispute, "The transaction shouldn't be disputed.");
        require(_amountReimbursed <= transaction.amount, "The amount reimbursed has to be less or equal than the transaction.");

        transaction.sender.transfer(_amountReimbursed);
        transaction.amount -= _amountReimbursed;
        emit Payment(_transactionID, _amountReimbursed, msg.sender);
    }

    /** @dev Transfer the transaction's amount to the receiver if the timeout has passed.
     *  @param _transactionID The index of the transaction.
     */
    function executeTransaction(uint _transactionID) public {
        Transaction storage transaction = transactions[_transactionID];
        require(now - transaction.lastInteraction >= transaction.timeoutPayment, "The timeout has not passed yet.");
        require(transaction.status == Status.NoDispute, "The transaction shouldn't be disputed.");

        uint amount = transaction.amount;
        transaction.amount = 0;
        uint feeAmount = calculateFeeRecipientAmount(amount);
        feeRecipient.send(feeAmount);
        transaction.receiver.send(amount - feeAmount);

        emit FeeRecipientPayment(_transactionID, feeAmount);

        transaction.status = Status.Resolved;
    }

    /** @dev Reimburse sender if receiver fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutBySender(uint _transactionID) public {
        Transaction storage transaction = transactions[_transactionID];
        require(transaction.status == Status.WaitingReceiver, "The transaction is not waiting on the receiver.");
        require(now - transaction.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");        

        if (transaction.receiverFee != 0) {
            transaction.receiver.send(transaction.receiverFee);
            transaction.receiverFee = 0;
        }
        executeRuling(_transactionID, SENDER_WINS);
    }

    /** @dev Pay receiver if sender fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutByReceiver(uint _transactionID) public {
        Transaction storage transaction = transactions[_transactionID];
        require(transaction.status == Status.WaitingSender, "The transaction is not waiting on the sender.");
        require(now - transaction.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

        if (transaction.senderFee != 0) {
            transaction.sender.send(transaction.senderFee);
            transaction.senderFee = 0;
        }
        executeRuling(_transactionID, RECEIVER_WINS);
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the sender. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeBySender(uint _transactionID) public payable {
        Transaction storage transaction = transactions[_transactionID];
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(transaction.status < Status.DisputeCreated, "Dispute has already been created or because the transaction has been executed.");
        require(msg.sender == transaction.sender, "The caller must be the sender.");

        transaction.senderFee += msg.value;
        // Require that the total pay at least the arbitration cost.
        require(transaction.senderFee >= arbitrationCost, "The sender fee must cover arbitration costs.");

        transaction.lastInteraction = now;

        // The receiver still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction.receiverFee < arbitrationCost) {
            transaction.status = Status.WaitingReceiver;
            emit HasToPayFee(_transactionID, Party.Receiver);
        } else { // The receiver has also paid the fee. We create the dispute.
            raiseDispute(_transactionID, arbitrationCost);
        }
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the receiver. UNTRUSTED.
     *  Note that this function mirrors payArbitrationFeeBySender.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeByReceiver(uint _transactionID) public payable {
        Transaction storage transaction = transactions[_transactionID];
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(transaction.status < Status.DisputeCreated, "Dispute has already been created or because the transaction has been executed.");
        require(msg.sender == transaction.receiver, "The caller must be the receiver.");

        transaction.receiverFee += msg.value;
        // Require that the total paid to be at least the arbitration cost.
        require(transaction.receiverFee >= arbitrationCost, "The receiver fee must cover arbitration costs.");

        transaction.lastInteraction = now;
        // The sender still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction.senderFee < arbitrationCost) {
            transaction.status = Status.WaitingSender;
            emit HasToPayFee(_transactionID, Party.Sender);
        } else { // The sender has also paid the fee. We create the dispute.
            raiseDispute(_transactionID, arbitrationCost);
        }
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _transactionID The index of the transaction.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function raiseDispute(uint _transactionID, uint _arbitrationCost) internal {
        Transaction storage transaction = transactions[_transactionID];
        transaction.status = Status.DisputeCreated;
        transaction.disputeId = arbitrator.createDispute.value(_arbitrationCost)(AMOUNT_OF_CHOICES, arbitratorExtraData);
        disputeIDtoTransactionID[transaction.disputeId] = _transactionID;
        emit Dispute(arbitrator, transaction.disputeId, _transactionID, _transactionID);

        // Refund sender if it overpaid.
        if (transaction.senderFee > _arbitrationCost) {
            uint extraFeeSender = transaction.senderFee - _arbitrationCost;
            transaction.senderFee = _arbitrationCost;
            transaction.sender.send(extraFeeSender);
        }

        // Refund receiver if it overpaid.
        if (transaction.receiverFee > _arbitrationCost) {
            uint extraFeeReceiver = transaction.receiverFee - _arbitrationCost;
            transaction.receiverFee = _arbitrationCost;
            transaction.receiver.send(extraFeeReceiver);
        }
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _transactionID The index of the transaction.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(uint _transactionID, string _evidence) public {
        Transaction storage transaction = transactions[_transactionID];
        require(
            msg.sender == transaction.sender || msg.sender == transaction.receiver,
            "The caller must be the sender or the receiver."
        );
        require(
            transaction.status < Status.Resolved,
            "Must not send evidence if the dispute is resolved."
        );

        emit Evidence(arbitrator, _transactionID, msg.sender, _evidence);
    }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _transactionID The index of the transaction.
     */
    function appeal(uint _transactionID) public payable {
        Transaction storage transaction = transactions[_transactionID];

        arbitrator.appeal.value(msg.value)(transaction.disputeId, arbitratorExtraData);
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public {
        uint transactionID = disputeIDtoTransactionID[_disputeID];
        Transaction storage transaction = transactions[transactionID];
        require(msg.sender == address(arbitrator), "The caller must be the arbitrator.");
        require(transaction.status == Status.DisputeCreated, "The dispute has already been resolved.");

        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(transactionID, _ruling);
    }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _transactionID The index of the transaction.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the receiver. 2 : Pay the sender.
     */
    function executeRuling(uint _transactionID, uint _ruling) internal {
        Transaction storage transaction = transactions[_transactionID];
        require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling.");

        uint amount = transaction.amount;
        uint senderArbitrationFee = transaction.senderFee;
        uint receiverArbitrationFee = transaction.receiverFee;

        transaction.amount = 0;
        transaction.senderFee = 0;
        transaction.receiverFee = 0;

        uint feeAmount;

        // Give the arbitration fee back.
        // Note that we use send to prevent a party from blocking the execution.
        if (_ruling == SENDER_WINS) {
            transaction.sender.send(senderArbitrationFee + amount);
        } else if (_ruling == RECEIVER_WINS) {
            feeAmount = calculateFeeRecipientAmount(amount);

            feeRecipient.send(feeAmount);
            transaction.receiver.send(receiverArbitrationFee + amount - feeAmount);

            emit FeeRecipientPayment(_transactionID, feeAmount);
        } else {
            uint split_arbitration = senderArbitrationFee / 2;
            uint split_amount = amount / 2;
            feeAmount = calculateFeeRecipientAmount(split_amount);

            transaction.sender.send(split_arbitration + split_amount);
            feeRecipient.send(feeAmount);
            transaction.receiver.send(split_arbitration + split_amount - feeAmount);

            emit FeeRecipientPayment(_transactionID, feeAmount);
        }

        transaction.status = Status.Resolved;
    }

    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter to know the count of transactions.
     *  @return countTransactions The count of transactions.
     */
    function getCountTransactions() public view returns (uint countTransactions) {
        return transactions.length;
    }

    /** @dev Get IDs for transactions where the specified address is the receiver and/or the sender.
     *  This function must be used by the UI and not by other smart contracts.
     *  Note that the complexity is O(t), where t is amount of arbitrable transactions.
     *  @param _address The specified address.
     *  @return transactionIDs The transaction IDs.
     */
    function getTransactionIDsByAddress(address _address) public view returns (uint[] transactionIDs) {
        uint count = 0;
        for (uint i = 0; i < transactions.length; i++) {
            if (transactions[i].sender == _address || transactions[i].receiver == _address)
                count++;
        }

        transactionIDs = new uint[](count);

        count = 0;

        for (uint j = 0; j < transactions.length; j++) {
            if (transactions[j].sender == _address || transactions[j].receiver == _address)
                transactionIDs[count++] = j;
        }
    }
}
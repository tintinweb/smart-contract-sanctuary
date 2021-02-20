/**
 * @authors: [@nkirshang]

 * ERC 792 implementation of a gift card exchange. ( ERC 792: https://github.com/ethereum/EIPs/issues/792 )
 * For the idea, see: https://whimsical.com/crypto-gift-card-exchange-VQTH2F7wE8HMvw3DzcSgRi
 * Neither the code, nor the concept is production ready.

 * SPDX-License-Identifier: MIT
**/

import "./IArbitrable.sol";
import "./IArbitrator.sol";
import "./IEvidence.sol";

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract Market is IArbitrable, IEvidence {

    //========== Contract variables ============

    address public owner;
    IArbitrator public arbitrator;

    uint arbitrationFeeDepositPeriod = 1 minutes; // For production, change to: 1 days.
    uint reclaimPeriod = 1 minutes; // For production, change to: 1 days.
    uint numOfRulingOptions = 2;


    enum Party {None, Buyer ,Seller}
    enum Status {None, Pending, Disputed, Appealed, Resolved}
    enum DisputeStatus {None, WaitingSeller, WaitingBuyer, Processing, Resolved}
    enum RulingOptions {RefusedToArbitrate, BuyerWins, SellerWins}

    /// @dev Transaction level events 
    event TransactionStateUpdate(uint indexed _transactionID, Transaction _transaction);
    event TransactionResolved(uint indexed _transactionID, Transaction _transaction);

    /// @dev Dispute level events (not defined in inherited interfaces)
    event DisputeStateUpdate(uint indexed _disputeID, uint indexed _transactionID, Arbitration _arbitration);

    /// @dev Fee Payment notifications 
    event HasToPayArbitrationFee(uint indexed transactionID, Party party);
    event HasToPayAppealFee(uint indexed transactionID, Party party);
    

    struct Transaction {
        uint price;
        bool forSale;

        address payable seller;
        address payable buyer;
        bytes32 cardInfo_URI_hash;

        Status status;
        uint init;

        uint disputeID;
    }

    struct Arbitration {
        
        uint transactionID;
        DisputeStatus status;
        uint feeDepositDeadline;

        uint buyerArbitrationFee;
        uint sellerArbitrationFee;
        uint arbitrationFee;

        uint appealRound;

        uint buyerAppealFee;
        uint sellerAppealFee;
        uint appealFee;
        
        Party ruling;
    }

    /// @dev Stores transaction hashses. For a given tx, Transaction ID = (index at tx_hashes) + 1.
    bytes32[] public tx_hashes;

    mapping(uint => Arbitration) public disputeID_to_arbitration;

    constructor(address _arbitrator) {
        arbitrator = IArbitrator(_arbitrator);
        owner = msg.sender;
    }

    modifier onlyValidTransaction(uint _transactionID, Transaction memory _transaction) {
        require(
            tx_hashes[_transactionID - 1] == hashTransactionState(_transaction), 
            "Transaction doesn't match stored hash."
            );
        _;
    }

    
    //========== Contract functions ============

    /**
     * @dev List a gift card.
     * @param _cardInfo The keccak 256 hash of URI where gift card info is stored.
     * @param _price The price of the gift card.
     */
    function listNewCard(bytes32 _cardInfo, uint _price) external {

        Transaction memory transaction = Transaction({
            price: _price,
            forSale: true,

            seller: msg.sender,
            buyer: address(0x0),
            cardInfo_URI_hash: _cardInfo,

            status: Status.None,

            init: 0,

            disputeID: 0 
        });

        bytes32 tx_hash = hashTransactionState(transaction);
        tx_hashes.push(tx_hash);
        uint transactionID = tx_hashes.length;

        emit TransactionStateUpdate(transactionID, transaction);
    }

    /**
     * @dev Buy a gift card.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     * @param _metaevidence Link to the meta-evidence; in compliance with ERC 1497 evidence standard.
     */
    function buyCard(
        uint _transactionID,
        Transaction memory _transaction,
        string calldata _metaevidence
    ) external payable onlyValidTransaction(_transactionID, _transaction) {

        require(_transaction.status == Status.None, "Can't purchase an item already engaged in sale.");
        require(_transaction.forSale, "Cannot purchase item not for sale.");
        require(msg.value == _transaction.price, "Must send exactly the item price.");


        _transaction.status = Status.Pending;
        _transaction.forSale = false;
        _transaction.buyer = msg.sender;
        _transaction.init = block.timestamp;

        tx_hashes[_transactionID - 1] =hashTransactionState(_transaction);

        emit TransactionStateUpdate(_transactionID, _transaction);
        emit MetaEvidence(_transactionID, _metaevidence);
    }

    /**
     * @dev Let seller withraw the price paid by buyer.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     */
    function withdrawPriceBySeller(
        uint _transactionID,
        Transaction memory _transaction
        ) external onlyValidTransaction(_transactionID, _transaction) {

        require(msg.sender == _transaction.seller, "Only the seller can call a seller-withdraw function.");
        require(block.timestamp - _transaction.init > reclaimPeriod, "Cannot withdraw price while reclaim period is not over.");
        require(_transaction.status == Status.Pending, "Can only withdraw price if the transaction is in the pending state.");

        _transaction.status = Status.Resolved;

        uint amount = _transaction.price;
        msg.sender.call{value: amount};

        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);
        emit TransactionResolved(_transactionID, _transaction);
    }

    /**
     * @dev Let buyer withraw the price paid for the gift card.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     */
    function withdrawPriceByBuyer(
        uint _transactionID,
        Transaction memory _transaction
        ) external onlyValidTransaction(_transactionID, _transaction) {
        
        Arbitration storage arbitration = disputeID_to_arbitration[_transaction.disputeID];

        require(msg.sender == _transaction.buyer, "Only the buyer can call a buyer-withdraw function.");
        require(
            _transaction.status >= Status.Disputed,
            "This function is called only when the seller's payment of the arbitration fee times out."
        );
        require(block.timestamp > arbitration.feeDepositDeadline, "The seller still has time to deposit an arbitration fee.");

        if(arbitration.appealRound != 0) {
            (uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(_transaction.disputeID);
            require(
                block.timestamp >= appealPeriodStart && block.timestamp > appealPeriodEnd, 
                "Seller still has time to fund an appeal."
            );
        }
        arbitration.status = DisputeStatus.Resolved;

        uint refundAmount = _transaction.price;
        refundAmount += (arbitration.buyerArbitrationFee + arbitration.buyerAppealFee);
        msg.sender.call{value: refundAmount};

        emit TransactionResolved(_transactionID, _transaction);
    }       
  

    /**
     * @dev Let buyer dispute the transaction by paying arbitration fees.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     */
    function reclaimDisputeByBuyer(
        uint _transactionID,
        Transaction memory _transaction
        ) external payable onlyValidTransaction(_transactionID, _transaction) {

        require(msg.sender == _transaction.buyer, "Only the buyer of the card can raise a reclaim dispute.");
        require(block.timestamp - _transaction.init < reclaimPeriod, "Cannot reclaim price after the reclaim window is closed.");
        require(_transaction.status == Status.Pending, "Can raise a reclaim dispute pending state.");

        uint arbitrationCost = arbitrator.arbitrationCost(""); // What is passed in for extraData?
        require(msg.value >= arbitrationCost, "Must deposit the right arbitration fee to reclaim paid price.");

        Arbitration memory arbitration = Arbitration({
            transactionID: _transactionID,
            status: DisputeStatus.WaitingSeller,
            feeDepositDeadline: block.timestamp + arbitrationFeeDepositPeriod,

            buyerArbitrationFee: msg.value,
            sellerArbitrationFee: 0,
            arbitrationFee: msg.value,

            appealRound: 0,

            buyerAppealFee: 0,
            sellerAppealFee: 0,
            appealFee: 0,
            
            ruling: Party.None
        });

        _transaction.status = Status.Disputed;
        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);

        uint noDisputeID = 0;

        emit TransactionStateUpdate(_transactionID, _transaction);
        emit DisputeStateUpdate(noDisputeID, _transactionID, arbitration);
        emit HasToPayArbitrationFee(_transactionID, Party.Seller);
    }

    /**
     * @dev Let seller pay arbitration fees in case of a dispute.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _metaevidenceID Equal to the transaction ID; in compliance with ERC 1497 evidence standard.
     * @param _transaction  The transaction state.
     * @param _arbitration The arbitration state.
     */
    function payArbitrationFeeBySeller(
        uint _transactionID,
        uint _metaevidenceID,
        Transaction memory _transaction,
        Arbitration memory _arbitration
        ) public payable onlyValidTransaction(_transactionID, _transaction) {

        uint arbitrationCost = arbitrator.arbitrationCost("");
        require(
            msg.value >= (arbitrationCost - _arbitration.sellerArbitrationFee), 
            "Must have at least arbitration cost in balance to create dispute."
        );
        require(msg.sender == _transaction.seller, "Only the seller involved in the dispute can pay the seller's fee.");
        require(block.timestamp < _arbitration.feeDepositDeadline, "The arbitration fee deposit period is over.");
        require(_arbitration.status == DisputeStatus.WaitingSeller,
            "Can only pay deposit fee when its the seller's turn to respond."
        );
        
        _arbitration.arbitrationFee += msg.value;
        _arbitration.sellerArbitrationFee += msg.value;
        _arbitration.feeDepositDeadline = block.timestamp + arbitrationFeeDepositPeriod;

        if(_arbitration.buyerArbitrationFee < arbitrationCost) {
            _arbitration.status = DisputeStatus.WaitingBuyer;
            emit DisputeStateUpdate(_transaction.disputeID, _transactionID, _arbitration);
            emit HasToPayArbitrationFee(_transactionID, Party.Buyer);
        } else {
            raiseDispute(_transactionID, _metaevidenceID, arbitrationCost, _transaction, _arbitration);
        }
    }

    /**
     * @dev Let buyer pay arbitration fees in case of a dispute.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _metaevidenceID Equal to the transaction ID; in compliance with ERC 1497 evidence standard.
     * @param _transaction  The transaction state.
     * @param _arbitration The arbitration state.
     */
    function payArbitrationFeeByBuyer(
        uint _transactionID,
        uint _metaevidenceID,
        Transaction memory _transaction,
        Arbitration memory _arbitration
        ) public payable onlyValidTransaction(_transactionID, _transaction) {

        uint arbitrationCost = arbitrator.arbitrationCost("");
        require(
            msg.value >= (arbitrationCost - _arbitration.sellerArbitrationFee), 
            "Must have at least arbitration cost in balance to create dispute."
        );
        require(block.timestamp < _arbitration.feeDepositDeadline, "The arbitration fee deposit period is over.");
        require(msg.sender == _transaction.buyer, "Only the buyer involved in the dispute can pay the buyer's fee.");
        require(_arbitration.status == DisputeStatus.WaitingBuyer,
            "Can only pay deposit fee when its the buyer's turn to respond."
        );
        
        _arbitration.arbitrationFee += msg.value;
        _arbitration.buyerArbitrationFee += msg.value;
        _arbitration.feeDepositDeadline = block.timestamp + arbitrationFeeDepositPeriod;

        if(_arbitration.sellerArbitrationFee < arbitrationCost) {
            _arbitration.status = DisputeStatus.WaitingSeller;
            emit DisputeStateUpdate(_transaction.disputeID, _transactionID, _arbitration);
            emit HasToPayArbitrationFee(_transactionID, Party.Seller);
        } else {
            raiseDispute(_transactionID, _metaevidenceID, arbitrationCost, _transaction, _arbitration);
        }
    }


    /**
     * @dev Call Arbitratble contract to create dispute.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _arbitrationCost Arbitration fee set by the Arbitrator contract.
     * @param _metaEvidenceID Equal to the transaction ID; in compliance with ERC 1497 evidence standard.
     * @param _transaction  The transaction state.
     * @param _arbitration The arbitration state.
     */
    function raiseDispute(
        uint _transactionID,
        uint _metaEvidenceID,
        uint _arbitrationCost,
        Transaction memory _transaction,
        Arbitration memory _arbitration
        ) internal {

        _transaction.status = Status.Disputed;
        _transaction.disputeID = arbitrator.createDispute{value: _arbitrationCost}(numOfRulingOptions, "");
        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);

        _arbitration.status = DisputeStatus.Processing;
        disputeID_to_arbitration[_transaction.disputeID] = _arbitration;

        // Seller | Buyer fee reimbursements.

        if(_arbitration.sellerArbitrationFee > _arbitrationCost) {
            uint extraFee = _arbitration.sellerArbitrationFee - _arbitrationCost;
            _arbitration.sellerArbitrationFee = _arbitrationCost;
            _transaction.seller.call{value: extraFee};
        }

        if(_arbitration.buyerArbitrationFee > _arbitrationCost) {
            uint extraFee = _arbitration.buyerArbitrationFee - _arbitrationCost;
            _arbitration.buyerArbitrationFee = _arbitrationCost;
            _transaction.buyer.call{value: extraFee};
        }

        emit TransactionStateUpdate(_transactionID, _transaction);
        emit Dispute(arbitrator, _transaction.disputeID, _metaEvidenceID, _transactionID);
    }

    /**
     * @dev Let seller pay appeal fees in case of a dispute.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     * @param _arbitration The arbitration state.
     */
    function payAppealFeeBySeller(
        uint _transactionID,
        Transaction memory _transaction,
        Arbitration memory _arbitration
    ) public payable onlyValidTransaction(_transactionID, _transaction) {

        require(_transaction.status >= Status.Disputed, "There is no dispute to appeal.");

        (uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(_transaction.disputeID);
        require(
            block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, 
            "Funding must be made within the appeal period."
        );

        uint256 appealCost = arbitrator.appealCost(_transaction.disputeID, "");
        require(msg.value >= appealCost - _arbitration.sellerAppealFee, "Not paying sufficient appeal fee.");

        _arbitration.sellerAppealFee += msg.value;
        _arbitration.appealFee += msg.value;

        if(_arbitration.buyerAppealFee < appealCost) {
            _arbitration.status = DisputeStatus.WaitingBuyer;
            emit DisputeStateUpdate( _transaction.disputeID, _transactionID, _arbitration);
            emit HasToPayAppealFee(_transactionID, Party.Buyer);
        } else {
            _arbitration.appealRound++;
            appealTransaction(_transactionID, appealCost, _transaction);
        }
    }

    /**
     * @dev Let buyer pay appeal fees in case of a dispute.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     * @param _arbitration The arbitration state.
     */
    function payAppealFeeByBuyer(   
        uint _transactionID,
        Transaction memory _transaction,
        Arbitration memory _arbitration
    ) public payable onlyValidTransaction(_transactionID, _transaction) {

        require(_transaction.status >= Status.Disputed, "There is no dispute to appeal.");

        (uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(_transaction.disputeID);
        require(
            block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, 
            "Funding must be made within the appeal period."
        );

        uint256 appealCost = arbitrator.appealCost(_transaction.disputeID, "");
        require(msg.value >= appealCost - _arbitration.buyerAppealFee, "Not paying sufficient appeal fee.");

        _arbitration.buyerAppealFee += msg.value;
        _arbitration.appealFee += msg.value;

        if(_arbitration.sellerAppealFee < appealCost) {
            _arbitration.status = DisputeStatus.WaitingSeller;
            emit DisputeStateUpdate( _transaction.disputeID, _transactionID, _arbitration);
            emit HasToPayAppealFee(_transactionID, Party.Seller);
        } else {
            _arbitration.appealRound++;
            appealTransaction(_transactionID, appealCost, _transaction);
        }
    }

    /**
     * @dev Call Arbitrator contract to appeal a ruling.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card.
     * @param _transaction  The transaction state.
     * @param _appealCost Appeal fees set by the Arbitrator contract.
     */
    function appealTransaction(
        uint _transactionID,
        uint _appealCost,
        Transaction memory _transaction
        ) internal {

        _transaction.status = Status.Appealed;
        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);
        
        Arbitration storage arbitration = disputeID_to_arbitration[_transaction.disputeID];

        arbitration.appealRound++;
        arbitrator.appeal{value: _appealCost}(_transaction.disputeID, "");
        arbitration.status = DisputeStatus.Processing;

        // Seller | Buyer fee reimbursements.

        if(arbitration.sellerAppealFee > _appealCost) {
            uint extraFee = arbitration.sellerAppealFee - _appealCost;
            arbitration.sellerAppealFee = _appealCost;
            _transaction.seller.call{value: extraFee};
        }

        if(arbitration.buyerAppealFee > _appealCost) {
            uint extraFee = arbitration.buyerAppealFee - _appealCost;
            arbitration.buyerAppealFee = _appealCost;
            _transaction.buyer.call{value: extraFee};
        }

        emit TransactionStateUpdate(_transactionID, _transaction);
        emit DisputeStateUpdate( _transaction.disputeID, _transactionID, arbitration);
    }

    /**
     * @dev Called by the Arbitrator contract; in compliance with ERC 792 Arbitrable standard.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external override {

        require(msg.sender == address(arbitrator), "Only the arbitrator can give a ruling.");

        
        Arbitration storage arbitration = disputeID_to_arbitration[_disputeID];
        require(arbitration.status == DisputeStatus.Processing, "Can give ruling only when a dispute is in process.");
        arbitration.status = DisputeStatus.Resolved;

        if(_ruling == uint(RulingOptions.BuyerWins)) {
            arbitration.ruling = Party.Buyer;
        }

        if(_ruling == uint(RulingOptions.SellerWins)) {
            arbitration.ruling = Party.Seller;
        }

        if(_ruling == uint(RulingOptions.RefusedToArbitrate)) {
            arbitration.ruling = Party.None;
        }

        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    /**
     * @dev Executes the ruling given by the Arbitrator contract.
     * @param _transactionID The unique ID of the transaction associated with a unique gift card. 
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _transaction The transaction state.
     */
    function executeRuling(
        uint _transactionID,
        uint _disputeID,
        Transaction memory _transaction
    ) external onlyValidTransaction(_transactionID, _transaction) {
        
        Arbitration storage arbitration = disputeID_to_arbitration[_disputeID]; // storage init whenever arbitration state change?
        require(arbitration.status == DisputeStatus.Resolved, "An arbitration must be resolved to execute its ruling.");

        uint refundAmount = _transaction.price;

        if(arbitration.ruling == Party.Buyer) {
            refundAmount += arbitration.buyerArbitrationFee;
            refundAmount += arbitration.buyerAppealFee;

            _transaction.buyer.transfer(refundAmount);
        }

        if(arbitration.ruling == Party.Seller) {
            refundAmount += arbitration.sellerArbitrationFee;
            refundAmount += arbitration.sellerAppealFee;

            _transaction.seller.transfer(refundAmount);
        }

        if(arbitration.ruling == Party.None) {
            refundAmount += arbitration.sellerArbitrationFee;
            refundAmount += arbitration.sellerAppealFee;

            _transaction.seller.transfer((refundAmount)/2);
            _transaction.buyer.transfer((refundAmount)/2);
        }
        
        _transaction.status = Status.Resolved;
        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);

        emit TransactionResolved(_transactionID, _transaction);
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _transactionID The index of the transaction.
     *  @param _transaction The transaction state.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submiteEvidence(
        uint _transactionID,
        Transaction memory _transaction,
        string calldata _evidence
    ) public onlyValidTransaction(_transactionID, _transaction) {

        require(
            msg.sender == _transaction.seller || msg.sender == _transaction.buyer,
            "The caller must be the seller or the buyer."
        );
        require(
            _transaction.status < Status.Resolved,
            "Must not send evidence if the dispute is resolved."
        );

        emit Evidence(arbitrator, _transactionID, msg.sender, _evidence);
    }

    /// @dev Setter functions for contract state variables.
    
    function setReclaimationPeriod(uint _newReclaimPeriod) external {
        require(msg.sender == owner, "Only the owner of the contract can change reclaim period.");
        reclaimPeriod = _newReclaimPeriod;
    }

    function setArbitrationFeeDepositPeriod(uint _newFeeDepositPeriod) external {
        require(msg.sender == owner, "Only the owner of the contract can change arbitration fee deposit period.");
        arbitrationFeeDepositPeriod = _newFeeDepositPeriod;
    }

    function setCardPrice(uint _transactionID, Transaction memory _transaction, uint _newPrice) external {
        require(msg.sender == _transaction.seller, "Only the owner of a card can set its price.");
        require(_transaction.status == Status.None, "Can't change gift card price once it has been engaged in sale.");
        _transaction.price = _newPrice;

        tx_hashes[_transactionID -1] = hashTransactionState(_transaction);

        emit TransactionStateUpdate(_transactionID, _transaction);
    }

    /// @dev Utility functions

    function hashTransactionState(Transaction memory _transaction) public pure returns (bytes32) {
        
        // Hash the whole transaction

        return keccak256(
            abi.encodePacked(
                _transaction.price,
                _transaction.forSale,

                _transaction.seller,
                _transaction.buyer,
                _transaction.cardInfo_URI_hash,

                _transaction.status,
                _transaction.init,

                _transaction.disputeID
            )
        );
    }

    function getNumOfTransactions() external view returns (uint) {
        return tx_hashes.length;
    }

    function getCardInfo(
        uint _transactionID, 
        Transaction memory _transaction
    ) external view onlyValidTransaction(_transactionID, _transaction) returns (bytes32) {
        require(msg.sender == _transaction.buyer, "Only the buyer can retrieve item info.");
        return _transaction.cardInfo_URI_hash;
    }

}
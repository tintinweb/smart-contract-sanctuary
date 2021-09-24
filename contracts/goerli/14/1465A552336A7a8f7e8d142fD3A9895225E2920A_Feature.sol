/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// File: Feature/Feature.sol

//SPDX-License-Identifier: Unlicense

/**
 *  @authors: [@n1c01a5]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint[50] private ______gap;
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
        initializer
    {
        _setDomainSeperator(name, version);
    }

    function _setDomainSeperator(string memory name, string memory version) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint) {
        uint id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}


contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        uint noncesByUser = nonces[userAddress];

        require(noncesByUser + 1 >= noncesByUser, "Must be not an overflow");

        nonces[userAddress] = noncesByUser + 1;

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

contract ChainConstants {
    string constant public ERC712_VERSION = "1";

    uint constant public ROOT_CHAIN_ID = 1;
    bytes constant public ROOT_CHAIN_ID_BYTES = hex"01";

    uint constant public CHILD_CHAIN_ID = 77;
    bytes constant public CHILD_CHAIN_ID_BYTES = hex"4D";
}


abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
    
        return sender;
    }
}


/** @title IArbitrable
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

/** @title Arbitrable
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
abstract contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes storage _arbitratorExtraData) {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public override onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) virtual internal;
}

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
abstract contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes calldata _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }

    modifier requireAppealFee(uint _disputeID, bytes calldata _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes calldata _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) public view virtual returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes calldata _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes calldata _extraData) public view virtual returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint _disputeID) public view virtual returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view virtual returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view virtual returns(uint ruling);
}

/** @title Feature
 *  Freelancing service smart contract
 */
contract Feature is Initializable, NativeMetaTransaction, ChainConstants, ContextMixin {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    // Amount of choices to solve the dispute if needed.
    uint8 constant AMOUNT_OF_CHOICES = 2;

    // Enum relative to different periods in the case of a negotiation or dispute.
    enum Status { NoDispute, WaitingFinder, WaitingOwner, DisputeCreated, Resolved }
    // The different parties of the dispute.
    enum Party { Sender, Receiver }
    // The different ruling for the dispute resolution.
    enum RulingOptions { NoRuling, SenderWins, ReceiverWins }

    struct Transaction {
        address sender;
        uint amount; // Amount of the reward in Wei.
        uint deposit; // Amount of the deposit in Wei.
        uint timeoutPayment; // Time in seconds after which the transaction can be executed if not disputed.
        uint timeoutClaim;
    }

    struct Claim {
        uint transactionID; // FIXME: Relation one-to-one with the transaction.
        address receiver; // Address of the receiver.
        uint lastInteraction; // Last interaction for the dispute procedure.
        uint senderFee; // Total fees paid by the sender.
        uint receiverFee; // Total fees paid by the receiver.
        uint disputeID; // If dispute exists, the ID of the dispute.
        Status status; // Status of the the dispute.
    }
    
    Transaction[] public transactions;
    Claim[] public claims;
    
    mapping (uint => uint) public disputeIDtoTransactionID; // One-to-one relationship between the dispute and the transaction.

    address public governor;

    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    Arbitrator public arbitrator; // Address of the arbitrator contract.
    uint public feeTimeout; // Time in seconds a party can take to pay arbitration fees before being considered unresponding and lose the dispute.

    // **************************** //
    // *          Events          * //
    // **************************** //
    
    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Payment(uint indexed _transactionID, uint _amount, address _party);
    
    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _transactionID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint indexed _transactionID, Party _party);

    // **************************** //
    // *    Contract functions    * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev Constructs the Recover contract.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    function initialize (
        Arbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        uint _feeTimeout
    ) public initializer {
        _initializeEIP712("Feature", ERC712_VERSION);

        arbitrator = Arbitrator(_arbitrator);
        arbitratorExtraData = _arbitratorExtraData;
        feeTimeout = _feeTimeout;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /** @dev Create a transaction.
     *  @param _deposit // FIXME: Deposit value.
     *  @param _timeoutPayment Time after which a party can automatically execute the arbitrable transaction.
     *  @param _timeoutClaim // FIXME: Time after which a party can automatically execute the arbitrable transaction.
     *  @param _metaEvidence Link to the meta-evidence.
     *  @return transactionID The index of the transaction.
     */
    function createTransaction(
        uint _deposit,
        uint _timeoutPayment,
        uint _timeoutClaim,
        string memory _metaEvidence
    ) public payable returns (uint transactionID) {
        transactions.push(Transaction({
            sender: _msgSender(),
            amount: msg.value, // Put the amount of the transaction to the smart vault.
            deposit: _deposit,
            timeoutPayment: _timeoutPayment,
            timeoutClaim: _timeoutClaim
        }));

        // Store the meta-evidence.
        // emit MetaEvidence(transactions.length - 1, _metaEvidence);
        
        return transactions.length - 1;
    }

    /** @dev Pay receiver. To be called if the service is provided.
     *  @param _claimID The index of the claim.
     */
    function pay(uint _claimID) public {
        Claim storage claim = claims[_claimID];
        Transaction storage transaction = transactions[claim.transactionID];

        require(transaction.timeoutClaim >= block.timestamp, "The timeout claim should be passed.");
        require(claim.status == Status.NoDispute, "The transaction shouldn't be disputed.");

        payable(claim.receiver).transfer(transaction.amount);

        emit Payment(claim.transactionID, transaction.amount, transaction.sender);
    }

    /** @dev Transfer the transaction's amount to the receiver if the timeout has passed.
     *  @param _transactionID The index of the transaction.
     */
    // function executeTransaction(uint _transactionID) public {
    //     Transaction storage transaction = transactions[_transactionID];
    //     require(block.timestamp - transaction.lastInteraction >= transaction.timeoutPayment, "The timeout has not passed yet.");
    //     require(transaction.status == Status.NoDispute, "The transaction shouldn't be disputed.");

    //     transaction.receiver.transfer(transaction.amount);
    //     transaction.amount = 0;

    //     transaction.status = Status.Resolved;
    // }

    /** @dev Reimburse sender if receiver fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    // function timeOutBySender(uint _transactionID) public {
    //     Transaction storage transaction = transactions[_transactionID];

    //     require(transaction.status == Status.WaitingReceiver, "The transaction is not waiting on the receiver.");
    //     require(now - transaction.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

    //     executeRuling(_transactionID, RulingOptions.SenderWins);
    // }

    /** @dev Pay receiver if sender fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    // function timeOutByReceiver(uint _transactionID) public {
    //     Transaction storage transaction = transactions[_transactionID];

    //     require(transaction.status == Status.WaitingSender, "The transaction is not waiting on the sender.");
    //     require(now - transaction.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

    //     executeRuling(_transactionID, RulingOptions.ReceiverWins);
    // }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the sender. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _transactionID The index of the transaction.
     */
    // function payArbitrationFeeBySender(uint _transactionID) public payable {
    //     Transaction storage transaction = transactions[_transactionID];
    //     uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

    //     require(transaction.status < Status.DisputeCreated, "Dispute has already been created or because the transaction has been executed.");
    //     require(msg.sender == transaction.sender, "The caller must be the sender.");

    //     transaction.senderFee += msg.value;
    //     // Require that the total pay at least the arbitration cost.
    //     require(transaction.senderFee >= arbitrationCost, "The sender fee must cover arbitration costs.");

    //     transaction.lastInteraction = now;

    //     // The receiver still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
    //     if (transaction.receiverFee < arbitrationCost) {
    //         transaction.status = Status.WaitingReceiver;
    //         emit HasToPayFee(_transactionID, Party.Receiver);
    //     } else { // The receiver has also paid the fee. We create the dispute.
    //         raiseDispute(_transactionID, arbitrationCost);
    //     }
    // }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the receiver. UNTRUSTED.
     *  Note that this function mirrors payArbitrationFeeBySender.
     *  @param _transactionID The index of the transaction.
     */
    // function payArbitrationFeeByReceiver(uint _transactionID) public payable {
    //     Transaction storage transaction = transactions[_transactionID];
    //     uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

    //     require(transaction.status < Status.DisputeCreated, "Dispute has already been created or because the transaction has been executed.");
    //     require(msg.sender == transaction.receiver, "The caller must be the receiver.");

    //     transaction.receiverFee += msg.value;
    //     // Require that the total paid to be at least the arbitration cost.
    //     require(transaction.receiverFee >= arbitrationCost, "The receiver fee must cover arbitration costs.");

    //     transaction.lastInteraction = now;
    //     // The sender still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
    //     if (transaction.senderFee < arbitrationCost) {
    //         transaction.status = Status.WaitingSender;
    //         emit HasToPayFee(_transactionID, Party.Sender);
    //     } else { // The sender has also paid the fee. We create the dispute.
    //         raiseDispute(_transactionID, arbitrationCost);
    //     }
    // }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _transactionID The index of the transaction.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    // function raiseDispute(uint _transactionID, uint _arbitrationCost) internal {
    //     Transaction storage transaction = transactions[_transactionID];
    //     transaction.status = Status.DisputeCreated;
    //     transaction.disputeId = arbitrator.createDispute.value(_arbitrationCost)(AMOUNT_OF_CHOICES, arbitratorExtraData);
    //     disputeIDtoTransactionID[transaction.disputeId] = _transactionID;
    //     emit Dispute(arbitrator, transaction.disputeId, _transactionID, _transactionID);

    //     // Refund sender if it overpaid.
    //     if (transaction.senderFee > _arbitrationCost) {
    //         uint extraFeeSender = transaction.senderFee - _arbitrationCost;
    //         transaction.senderFee = _arbitrationCost;
    //         transaction.sender.send(extraFeeSender);
    //     }

    //     // Refund receiver if it overpaid.
    //     if (transaction.receiverFee > _arbitrationCost) {
    //         uint extraFeeReceiver = transaction.receiverFee - _arbitrationCost;
    //         transaction.receiverFee = _arbitrationCost;
    //         transaction.receiver.send(extraFeeReceiver);
    //     }
    // }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _transactionID The index of the transaction.
     *  @param _evidence A link to an evidence using its URI.
     */
    // function submitEvidence(uint _transactionID, string memory _evidence) public {
    //     Transaction storage transaction = transactions[_transactionID];
    //     require(
    //         _msgSender() == transaction.sender || _msgSender() == transaction.receiver,
    //         "The caller must be the sender or the receiver."
    //     );
    //     require(
    //         transaction.status < Status.Resolved,
    //         "Must not send evidence if the dispute is resolved."
    //     );

    //     emit Evidence(arbitrator, _transactionID, _msgSender(), _evidence);
    // }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _transactionID The index of the transaction.
     */
    // function appeal(uint _transactionID) public payable {
    //     Transaction storage transaction = transactions[_transactionID];

    //     arbitrator.appeal.value(msg.value)(transaction.disputeId, arbitratorExtraData);
    // }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    // function rule(uint _disputeID, uint _ruling) public {
    //     uint transactionID = disputeIDtoTransactionID[_disputeID];
    //     Transaction storage transaction = transactions[transactionID];
    //     require(msg.sender == address(arbitrator), "The caller must be the arbitrator.");
    //     require(transaction.status == Status.DisputeCreated, "The dispute has already been resolved.");

    //     emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

    //     executeRuling(transactionID, _ruling);
    // }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _transactionID The index of the transaction.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the receiver. 2 : Pay the sender.
     */
    // function executeRuling(uint _transactionID, uint _ruling) internal {
    //     Transaction storage transaction = transactions[_transactionID];
    //     require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling.");

    //     // Give the arbitration fee back.
    //     // Note that we use send to prevent a party from blocking the execution.
    //     if (_ruling == RulingOptions.SenderWins) {
    //         transaction.sender.send(transaction.senderFee + transaction.amount);
    //     } else if (_ruling == RulingOptions.ReceiverWins) {
    //         transaction.receiver.send(transaction.receiverFee + transaction.amount);
    //     } else {
    //         uint split_amount = (transaction.senderFee + transaction.amount) / 2;
    //         transaction.sender.send(split_amount);
    //         transaction.receiver.send(split_amount);
    //     }

    //     transaction.amount = 0;
    //     transaction.senderFee = 0;
    //     transaction.receiverFee = 0;
    //     transaction.status = Status.Resolved;
    // }

    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter to know the count of transactions.
     *  @return countTransactions The count of transactions.
     */
    // function getCountTransactions() public view returns (uint countTransactions) {
    //     return transactions.length;
    // }

    /** @dev Get IDs for transactions where the specified address is the receiver and/or the sender.
     *  This function must be used by the UI and not by other smart contracts.
     *  Note that the complexity is O(t), where t is amount of arbitrable transactions.
     *  @param _address The specified address.
     *  @return transactionIDs The transaction IDs.
     */
    // function getTransactionIDsByAddress(address _address) public view returns (uint[] memory transactionIDs) {
    //     uint count = 0;
    //     for (uint i = 0; i < transactions.length; i++) {
    //         if (transactions[i].sender == _address || transactions[i].receiver == _address)
    //             count++;
    //     }

    //     transactionIDs = new uint[](count);

    //     count = 0;

    //     for (uint j = 0; j < transactions.length; j++) {
    //         if (transactions[j].sender == _address || transactions[j].receiver == _address)
    //             transactionIDs[count++] = j;
    //     }
    // }
}
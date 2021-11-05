//SPDX-License-Identifier: Unlicense

/**
 *  @authors: [@n1c01a5]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.7;

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
        uint256 cs;
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
        uint256 id;
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
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
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
        uint256 nonce;
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
        uint256 noncesByUser = nonces[userAddress];

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

    function getNonce(address user) public view returns (uint256 nonce) {
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

    uint256 constant public ROOT_CHAIN_ID = 1;
    bytes constant public ROOT_CHAIN_ID_BYTES = hex"01";

    uint256 constant public CHILD_CHAIN_ID = 77;
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
            uint256 index = msg.data.length;
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
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _metaEvidenceID, uint256 _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint256 indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
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
    function rule(uint256 _disputeID, uint256 _ruling) external override onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(_disputeID, _ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint256 _disputeID, uint256 _ruling) virtual internal;
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

    modifier requireAppealFee(uint256 _disputeID, bytes calldata _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) public requireArbitrationFee(_extraData) payable returns(uint256 disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) public view virtual returns(uint256 fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) public view virtual returns(uint256 fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) public view virtual returns(uint256 start, uint256 end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) public view virtual returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) public view virtual returns(uint256 ruling);
}

/** @title Feature
 *  Freelancing service smart contract
 */
contract Feature is Initializable, NativeMetaTransaction, ChainConstants, ContextMixin, IArbitrable {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    // Amount of choices to solve the dispute if needed.
    uint8 constant AMOUNT_OF_CHOICES = 2;

    // Enum relative to different periods in the case of a negotiation or dispute.
    enum Status { WaitingForChallenger, DisputeCreated, Resolved }
    // The different parties of the dispute.
    enum Party { Receiver, Challenger }
    // The different ruling for the dispute resolution.
    enum RulingOptions { NoRuling, ReceiverWins, ChallengerWins }

    struct Transaction {
        address sender;
        uint256 amount; // Amount of the reward in Wei.
        uint256 deposit; // Amount of the deposit in Wei.
        uint256 timeoutPayment; // Time in seconds after which the transaction can be executed if not disputed.
        uint256 delayClaim;
        uint256[] runningClaimIDs; // IDs of running claims.
        bool isExecuted;
    }

    struct Claim {
        uint256 transactionID; // Relation one-to-one with the transaction.
        address receiver; // Address of the receiver.
        address challenger; // Address of the challenger.
        uint256 timeoutClaim;
        uint256 lastInteraction; // Last interaction for the dispute procedure.
        uint256 receiverFee; // Total fees paid by the receiver.
        uint256 challengerFee; // Total fees paid by the challenge.
        uint256 disputeID; // If dispute exists, the ID of the dispute.
        Status status; // Status of the the dispute.
    }
    
    Transaction[] public transactions;
    Claim[] public claims;
    
    mapping (uint256 => uint) public disputeIDtoClaimID; // One-to-one relationship between the dispute and the claim.

    address public governor;

    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    Arbitrator public arbitrator; // Address of the arbitrator contract.

    // **************************** //
    // *          Events          * //
    // **************************** //
    
    /** @dev To be emitted when a party pays.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Payment(uint256 indexed _transactionID, uint256 _amount, address _party);

    /** @dev To be emitted when a sender is refunded.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Refund(uint256 indexed _transactionID, uint256 _amount, address _party);

    /** @dev To be emitted when a receiver submit a claim.
     *  @param _transactionID The index of the transaction.
     *  @param _claimID The index of the claim.
     *  @param _receiver The receiver who claims.
     */
    event ClaimSubmit(uint256 indexed _transactionID, uint256 _claimID, address _receiver);
    
    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _transactionID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint256 indexed _transactionID, Party _party);

    // **************************** //
    // *    Contract functions    * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev Constructs the Recover contract.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    function initialize (
        Arbitrator _arbitrator,
        bytes memory _arbitratorExtraData
    ) public initializer {
        _initializeEIP712("Feature", ERC712_VERSION);

        arbitrator = Arbitrator(_arbitrator);
        arbitratorExtraData = _arbitratorExtraData;
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
     *  @param _deposit // Deposit value.
     *  @param _timeoutPayment Time after which a party can automatically execute the arbitrable transaction.
     *  @param _delayClaim // Time after which the receiver can execute the transaction.
     *  @param _metaEvidence Link to the meta-evidence.
     *  @return transactionID The index of the transaction.
     */
    function createTransaction(
        uint256 _deposit,
        uint256 _timeoutPayment,
        uint256 _delayClaim,
        string memory _metaEvidence
    ) public payable returns (uint256 transactionID) {
        uint[] memory claimIDsEmpty;

        transactions.push(Transaction({
            sender: _msgSender(),
            amount: msg.value, // Put the amount of the transaction to the smart vault.
            deposit: _deposit,
            timeoutPayment: _timeoutPayment + block.timestamp,
            delayClaim: _delayClaim,
            runningClaimIDs: claimIDsEmpty,
            isExecuted: false
        }));

        // Store the meta-evidence.
        emit MetaEvidence(transactions.length - 1, _metaEvidence);
        
        return transactions.length - 1;
    }

    /** @dev Claim from receiver
     *  @param _transactionID The index of the transaction.
     *  @return claimID The index of the claim.
     */
    function claim(
        uint256 _transactionID
    ) public payable returns (uint256 claimID)  {
        return _claimFor(_transactionID, _msgSender());
    }

    /** @dev Claim from receiver
     *  @param _transactionID The index of the transaction.
     *  @param _receiver The address of the receiver.
     *  @return claimID The index of the claim.
     */
    function claimFor(
        uint256 _transactionID,
        address _receiver
    ) public payable returns (uint256 claimID)  {
        return _claimFor(_transactionID, _receiver);
    }

    /** @dev Claim from receiver
     *  @param _transactionID The index of the transaction.
     *  @param _receiver The address of the receiver.
     *  @return claimID The index of the claim.
     */
    function _claimFor(
        uint256 _transactionID,
        address _receiver
    ) internal returns (uint256 claimID)  {
        Transaction storage transaction = transactions[_transactionID];

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(msg.value >= transaction.deposit + arbitrationCost, "The challenger fee must cover the deposit and the arbitration costs.");

        claims.push(Claim({
            transactionID: _transactionID,
            receiver: _receiver,
            challenger: address(0),
            timeoutClaim: transaction.delayClaim + block.timestamp,
            lastInteraction: block.timestamp,
            receiverFee: arbitrationCost,
            challengerFee: 0,
            disputeID: 0,
            status: Status.WaitingForChallenger
        }));

        claimID = claims.length - 1;

        transaction.runningClaimIDs.push(claimID);

        emit ClaimSubmit(_transactionID, claimID, _receiver);

        return claimID;
    }

    /** @dev Pay receiver. To be called if the service is provided.
     *  @param _claimID The index of the claim.
     */
    function pay(uint256 _claimID) public {
        Claim storage claim = claims[_claimID];
        Transaction storage transaction = transactions[claim.transactionID];

        require(transaction.isExecuted == false, "The transaction should not be executed.");
        require(claim.timeoutClaim <= block.timestamp, "The timeout claim should be passed.");
        require(claim.status == Status.WaitingForChallenger, "The transaction shouldn't be disputed.");

        transaction.isExecuted = true;
        claim.status = Status.Resolved;

        payable(claim.receiver).transfer(transaction.amount + transaction.deposit + claim.receiverFee);

        emit Payment(claim.transactionID, transaction.amount, transaction.sender);
    }

    /**
     * @notice Refund the sender. To be called when the sender wants to refund a transaction.
     * @param _transactionID The index of the transaction.
     */
    function refund(uint256 _transactionID) public {
        Transaction storage transaction = transactions[_transactionID];

        require(transaction.isExecuted == false, "The transaction should not be refunded.");
        require(transaction.timeoutPayment <= block.timestamp, "The timeout payment should be passed.");
        require(transaction.runningClaimIDs.length == 0, "The transaction should not to have running claims.");

        transaction.isExecuted = true;

        payable(transaction.sender).transfer(transaction.amount);

        emit Refund(_transactionID, transaction.amount, transaction.sender);
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the sender. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _claimID The index of the claim.
     */
    function challengeClaim(uint256 _claimID) public payable {
        Claim storage claim = claims[_claimID];
        Transaction storage transaction = transactions[claim.transactionID];

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(claim.status < Status.DisputeCreated, "Dispute has already been created or because the transaction has been executed.");
        require(msg.value >= transaction.deposit + arbitrationCost, "The challenger fee must cover the deposit and the arbitration costs.");

        claim.challengerFee = arbitrationCost;
        claim.challenger = _msgSender();

        raiseDispute(_claimID, arbitrationCost);
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _claimID The index of the claim.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function raiseDispute(uint256 _claimID, uint256 _arbitrationCost) internal {
        Claim storage claim = claims[_claimID];

        claim.status = Status.DisputeCreated;
        claim.disputeID = arbitrator.createDispute{value: _arbitrationCost}(AMOUNT_OF_CHOICES, arbitratorExtraData);
        disputeIDtoClaimID[claim.disputeID] = _claimID;

        emit Dispute(arbitrator, claim.disputeID, _claimID, _claimID);

        // Refund receiver if it overpaid.
        if (claim.receiverFee > _arbitrationCost) {
            uint256 extraFeeSender = claim.receiverFee - _arbitrationCost;
            claim.receiverFee = _arbitrationCost;

            payable(claim.receiver).send(extraFeeSender);
        }

        // Refund challenger if it overpaid.
        if (claim.challengerFee > _arbitrationCost) {
            uint256 extraFeeChallenger = claim.challengerFee - _arbitrationCost;
            claim.challengerFee = _arbitrationCost;

            payable(claim.challenger).send(extraFeeChallenger);
        }
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _claimID The index of the claim.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(uint256 _claimID, string memory _evidence) public {
        Claim storage claim = claims[_claimID];

        require(
            claim.status < Status.Resolved,
            "Must not send evidence if the dispute is resolved."
        );

        emit Evidence(arbitrator, _claimID, _msgSender(), _evidence);
    }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _claimID The index of the claim.
     */
    function appeal(uint256 _claimID) public payable {
        Claim storage claim = claims[_claimID];

        arbitrator.appeal{value: msg.value}(claim.disputeID, arbitratorExtraData);
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) override external {
        uint256 claimID = disputeIDtoClaimID[_disputeID];
        Claim storage claim = claims[claimID];

        require(msg.sender == address(arbitrator), "The caller must be the arbitrator.");
        require(claim.status == Status.DisputeCreated, "The dispute has already been resolved.");

        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(claimID, _ruling);
    }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _claimID The index of the transaction.
     *  @param _ruling Ruling given by the arbitrator. 1 : Pay the receiver with the deposit of paries. 2 : Give the deposit of parties to the challenger.
     */
    function executeRuling(uint256 _claimID, uint256 _ruling) internal {
        Claim storage claim = claims[_claimID];
        Transaction storage transaction = transactions[claim.transactionID];

        require(_ruling <= AMOUNT_OF_CHOICES, "Must be a valid ruling.");

        // Give the arbitration fee back.
        // Note: we use send to prevent a party from blocking the execution.
        if (_ruling == uint(RulingOptions.ReceiverWins)) {
            payable(claim.receiver).send(transaction.deposit);

            claim.status = Status.WaitingForChallenger;
        } else if (_ruling == uint(RulingOptions.ChallengerWins)) {
            payable(claim.challenger).send(claim.challengerFee + transaction.deposit * 2);

            claim.status = Status.Resolved;
        } else {
            payable(claim.receiver).send(transaction.deposit);
            payable(claim.challenger).send(claim.challengerFee + transaction.deposit);

            claim.status = Status.WaitingForChallenger;
        }

        delete transaction.runningClaimIDs[_claimID];
    }

    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter to know the running claim IDs of a transaction.
     *  @param _transactionID The index of the transaction.
     *  @return runningClaimIDs The count of transactions.
     */
    function getRunningClaimIDsOfTransaction(uint256 _transactionID) public view returns (uint256[] memory runningClaimIDs) {
        return transactions[_transactionID].runningClaimIDs;
    }

    /** @dev Getter to know the count of transactions.
     *  @return countTransactions The count of transactions.
     */
    function getCountTransactions() public view returns (uint256 countTransactions) {
        return transactions.length;
    }

    /** @dev Get IDs for transactions where the specified address is the sender.
     *  This function must be used by the UI and not by other smart contracts.
     *  Note that the complexity is O(t), where t is amount of arbitrable transactions.
     *  @param _address The specified address.
     *  @return transactionIDs The transaction IDs.
     */
    function getTransactionIDsByAddress(address _address) public view returns (uint[] memory transactionIDs) {
        uint256 count = 0;

        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].sender == _address)
                count++;
        }

        transactionIDs = new uint[](count);

        count = 0;

        for (uint256 j = 0; j < transactions.length; j++) {
            if (transactions[j].sender == _address)
                transactionIDs[count++] = j;
        }
    }

    /** @dev Get IDs for claims where the specified address is the receiver.
     *  This function must be used by the UI and not by other smart contracts.
     *  Note that the complexity is O(t), where t is amount of arbitrable claims.
     *  @param _address The specified address.
     *  @return claimIDs The claims IDs.
     */
    function getClaimIDsByAddress(address _address) public view returns (uint[] memory claimIDs) {
        uint256 count = 0;

        for (uint256 i = 0; i < claims.length; i++) {
            if (claims[i].receiver == _address)
                count++;
        }

        claimIDs = new uint[](count);

        count = 0;

        for (uint256 j = 0; j < claims.length; j++) {
            if (claims[j].receiver == _address)
                claimIDs[count++] = j;
        }
    }
}
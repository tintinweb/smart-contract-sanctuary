/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: [@clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.5.16;


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}


/**
 *  @authors: [@hbarcelos]
 *  @reviewers: [@fnanni-0]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath128 {
    uint128 private constant UINT128_MAX = 2**128 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^128 - 1 on overflow.
     */
    function addCap(uint128 _a, uint128 _b) internal pure returns (uint128) {
        uint128 c = _a + _b;
        return c >= _a ? c : UINT128_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint128 _a, uint128 _b) internal pure returns (uint128) {
        if (_b > _a) return 0;
        else return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^128 - 1 on overflow.
     */
    function mulCap(uint128 _a, uint128 _b) internal pure returns (uint128) {
        if (_a == 0) return 0;

        uint128 c = _a * _b;
        return c / _a == _b ? c : UINT128_MAX;
    }
}

 
 /**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.5;


/** @title IArbitrable
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract.
 *  -Allow dispute creation. For this a function must call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 */
interface IArbitrable {

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}


 /**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.5;


/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    /** @dev To be emitted when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be emitted when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be emitted when the current ruling is appealed.
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
    function createDispute(uint _choices, bytes calldata _extraData) external payable returns(uint disputeID);

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns(uint cost);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes calldata _extraData) external payable;

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return cost Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes calldata _extraData) external view returns(uint cost);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint _disputeID) external view returns(uint start, uint end);

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) external view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) external view returns(uint ruling);

}


pragma solidity >=0.5;


/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {

    /** @dev To be emitted when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(IArbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

}


/**
 *  @authors: [@unknownunknown1*, @mtsalenc*, @hbarcelos*]
 *  @reviewers: [@fnanni-0*, @greenlucid, @shalzz]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */


/**
 *  @title LightGeneralizedTCR
 *  This contract is a curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  The difference between LightGeneralizedTCR and GeneralizedTCR is that instead of storing item data in storage and event logs, LightCurate only stores the URI of item in the logs. This makes it considerably cheaper to use and allows more flexibility with the item columns.
 */
contract LightGeneralizedTCR is IArbitrable, IEvidence {
    using CappedMath for uint256;
    using CappedMath128 for uint128;

    /* Enums */

    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    enum RequestType {
        Registration, // Identifies a request to register an item to the registry.
        Clearing // Identifies a request to remove an item from the registry.
    }

    enum DisputeStatus {
        None, // No dispute was created.
        AwaitingRuling, // Dispute was created, but the final ruling was not given yet.
        Resolved // Dispute was ruled.
    }

    /* Structs */

    struct Item {
        Status status; // The current status of the item.
        uint128 sumDeposit; // The total deposit made by the requester and the challenger (if any).
        uint120 requestCount; // The number of requests.
        mapping(uint256 => Request) requests; // List of status change requests made for the item in the form requests[requestID].
    }

    // Arrays with 3 elements map with the Party enum for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        RequestType requestType;
        uint64 submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        uint24 arbitrationParamsIndex; // The index for the arbitration params for the request.
        address payable requester; // Address of the requester.
        // Pack the requester together with the other parameters, as they are written in the same request.
        address payable challenger; // Address of the challenger, if any.
    }

    struct DisputeData {
        uint256 disputeID; // The ID of the dispute on the arbitrator.
        DisputeStatus status; // The current status of the dispute.
        Party ruling; // The ruling given to a dispute. Only set after it has been resolved.
        uint240 roundCount; // The number of rounds.
        mapping(uint256 => Round) rounds; // Data of the different dispute rounds. rounds[roundId].
    }

    struct Round {
        Party sideFunded; // Stores the side that successfully paid the appeal fees in the latest round. Note that if both sides have paid a new round is created.
        uint256 feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        uint256[3] amountPaid; // Tracks the sum paid for each Party in this round.
        mapping(address => uint256[3]) contributions; // Maps contributors to their contributions for each side in the form contributions[address][party].
    }

    struct ArbitrationParams {
        IArbitrator arbitrator; // The arbitrator trusted to solve disputes for this request.
        bytes arbitratorExtraData; // The extra data for the trusted arbitrator of this request.
    }

    /* Constants */

    uint256 public constant RULING_OPTIONS = 2; // The amount of non 0 choices the arbitrator can give.
    uint256 private constant RESERVED_ROUND_ID = 0; // For compatibility with GeneralizedTCR consider the request/challenge cycle the first round (index 0).

    /* Storage */

    bool private initialized;

    address public relayerContract; // The contract that is used to add or remove items directly to speed up the interchain communication.
    address public governor; // The address that can make changes to the parameters of the contract.

    uint256 public submissionBaseDeposit; // The base deposit to submit an item.
    uint256 public removalBaseDeposit; // The base deposit to remove an item.
    uint256 public submissionChallengeBaseDeposit; // The base deposit to challenge a submission.
    uint256 public removalChallengeBaseDeposit; // The base deposit to challenge a removal request.
    uint256 public challengePeriodDuration; // The time after which a request becomes executable if not challenged.

    // Multipliers are in basis points.
    uint256 public winnerStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that won the previous round.
    uint256 public loserStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that lost the previous round.
    uint256 public sharedStakeMultiplier; // Multiplier for calculating the fee stake that must be paid in the case where arbitrator refused to arbitrate.
    uint256 public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    mapping(bytes32 => Item) public items; // Maps the item ID to its data in the form items[_itemID].
    mapping(address => mapping(uint256 => bytes32)) public arbitratorDisputeIDToItemID; // Maps a dispute ID to the ID of the item with the disputed request in the form arbitratorDisputeIDToItemID[arbitrator][disputeID].
    mapping(bytes32 => mapping(uint256 => DisputeData)) public requestsDisputeData; // Maps an item and a request to the data of the dispute related to them. requestsDisputeData[itemID][requestIndex]
    ArbitrationParams[] public arbitrationParamsChanges;

    /* Modifiers */

    modifier onlyGovernor() {
        require(msg.sender == governor, "The caller must be the governor.");
        _;
    }

    modifier onlyRelayer() {
        require(msg.sender == relayerContract, "The caller must be the relay.");
        _;
    }

    /* Events */

    /**
     * @dev Emitted when a party makes a request, raises a dispute or when a request is resolved.
     * @param _itemID The ID of the affected item.
     * @param _updatedDirectly Whether this was emitted in either `addItemDirectly` or `removeItemDirectly`. This is used in the subgraph.
     */
    event ItemStatusChange(bytes32 indexed _itemID, bool _updatedDirectly);

    /**
     * @dev Emitted when someone submits an item for the first time.
     * @param _itemID The ID of the new item.
     * @param _data The item data URI.
     * @param _addedDirectly Whether the item was added via `addItemDirectly`.
     */
    event NewItem(bytes32 indexed _itemID, string _data, bool _addedDirectly);

    /**
     * @dev Emitted when someone submits a request.
     * @param _itemID The ID of the affected item.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     */
    event RequestSubmitted(bytes32 indexed _itemID, uint256 _evidenceGroupID);

    /**
     * @dev Emitted when a party contributes to an appeal. The roundID assumes the initial request and challenge deposits are the first round. This is done so indexers can know more information about the contribution without using call handlers.
     * @param _itemID The ID of the item.
     * @param _requestID The index of the request that received the contribution.
     * @param _roundID The index of the round that received the contribution.
     * @param _contributor The address making the contribution.
     * @param _contribution How much of the contribution was accepted.
     * @param _side The party receiving the contribution.
     */
    event Contribution(
        bytes32 indexed _itemID,
        uint256 _requestID,
        uint256 _roundID,
        address indexed _contributor,
        uint256 _contribution,
        Party _side
    );

    /**
     * @dev Emitted when the address of the connected TCR is set. The connected TCR is an instance of the Generalized TCR contract where each item is the address of a TCR related to this one.
     * @param _connectedTCR The address of the connected TCR.
     */
    event ConnectedTCRSet(address indexed _connectedTCR);

    /**
     * @dev Emitted when someone withdraws more than 0 rewards.
     * @param _beneficiary The address that made contributions to a request.
     * @param _itemID The ID of the item submission to withdraw from.
     * @param _request The request from which to withdraw.
     * @param _round The round from which to withdraw.
     * @param _reward The amount withdrawn.
     */
    event RewardWithdrawn(
        address indexed _beneficiary,
        bytes32 indexed _itemID,
        uint256 _request,
        uint256 _round,
        uint256 _reward
    );

    /**
     * @dev Initialize the arbitrable curated registry.
     * @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     * @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     * @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     * @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     * @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     * @param _governor The trusted governor of this contract.
     * @param _baseDeposits The base deposits for requests/challenges as follows:
     * - The base deposit to submit an item.
     * - The base deposit to remove an item.
     * - The base deposit to challenge a submission.
     * - The base deposit to challenge a removal request.
     * @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     * @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see MULTIPLIER_DIVISOR) as follows:
     * - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when the arbitrator refused to arbitrate).
     * - The multiplier applied to the winner's fee stake for the subsequent round.
     * - The multiplier applied to the loser's fee stake for the subsequent round.
     * @param _relayerContract The address of the relay contract to add/remove items directly.
     */
    function initialize(
        IArbitrator _arbitrator,
        bytes calldata _arbitratorExtraData,
        address _connectedTCR,
        string calldata _registrationMetaEvidence,
        string calldata _clearingMetaEvidence,
        address _governor,
        uint256[4] calldata _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] calldata _stakeMultipliers,
        address _relayerContract
    ) external {
        require(!initialized, "Already initialized.");

        emit ConnectedTCRSet(_connectedTCR);

        governor = _governor;
        submissionBaseDeposit = _baseDeposits[0];
        removalBaseDeposit = _baseDeposits[1];
        submissionChallengeBaseDeposit = _baseDeposits[2];
        removalChallengeBaseDeposit = _baseDeposits[3];
        challengePeriodDuration = _challengePeriodDuration;
        sharedStakeMultiplier = _stakeMultipliers[0];
        winnerStakeMultiplier = _stakeMultipliers[1];
        loserStakeMultiplier = _stakeMultipliers[2];
        relayerContract = _relayerContract;

        _doChangeArbitrationParams(_arbitrator, _arbitratorExtraData, _registrationMetaEvidence, _clearingMetaEvidence);

        initialized = true;
    }

    /* External and Public */

    // ************************ //
    // *       Requests       * //
    // ************************ //

    /**
     * @dev Directly add an item to the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _item The URI to the item data.
     */
    function addItemDirectly(string calldata _item) external onlyRelayer {
        bytes32 itemID = keccak256(abi.encodePacked(_item));
        Item storage item = items[itemID];
        require(item.status == Status.Absent, "Item must be absent to be added.");

        // Note that if the item is added directly once, the next time it is added it will emit this event again.
        if (item.requestCount == 0) {
            emit NewItem(itemID, _item, true);
        }

        item.status = Status.Registered;

        emit ItemStatusChange(itemID, true);
    }

    /**
     * @dev Directly remove an item from the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _itemID The ID of the item to remove.
     */
    function removeItemDirectly(bytes32 _itemID) external onlyRelayer {
        Item storage item = items[_itemID];
        require(item.status == Status.Registered, "Item must be registered to be removed.");

        item.status = Status.Absent;

        emit ItemStatusChange(_itemID, true);
    }

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable {
        bytes32 itemID = keccak256(abi.encodePacked(_item));
        Item storage item = items[itemID];

        // Extremely unlikely, but we check that for correctness sake.
        require(item.requestCount < uint120(-1), "Too many requests for item.");
        require(item.status == Status.Absent, "Item must be absent to be added.");

        // Note that if the item was added previously using `addItemDirectly`, the event will be emitted again here.
        if (item.requestCount == 0) {
            emit NewItem(itemID, _item, false);
        }

        Request storage request = item.requests[item.requestCount++];
        uint256 arbitrationParamsIndex = arbitrationParamsChanges.length - 1;
        IArbitrator arbitrator = arbitrationParamsChanges[arbitrationParamsIndex].arbitrator;
        bytes storage arbitratorExtraData = arbitrationParamsChanges[arbitrationParamsIndex].arbitratorExtraData;

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        uint256 totalCost = arbitrationCost.addCap(submissionBaseDeposit);
        require(msg.value >= totalCost, "You must fully fund the request.");

        emit Contribution(itemID, item.requestCount - 1, RESERVED_ROUND_ID, msg.sender, totalCost, Party.Requester);

        // Casting is safe here because this line will never be executed in case
        // totalCost > type(uint128).max, since it would be an unpayable value.
        item.sumDeposit = uint128(totalCost);
        item.status = Status.RegistrationRequested;

        request.requestType = RequestType.Registration;
        request.submissionTime = uint64(block.timestamp);
        request.arbitrationParamsIndex = uint24(arbitrationParamsIndex);
        request.requester = msg.sender;

        emit RequestSubmitted(itemID, getEvidenceGroupID(itemID, item.requestCount - 1));

        if (msg.value > totalCost) {
            msg.sender.send(msg.value - totalCost);
        }
    }

    /**
     * @dev Submit a request to remove an item from the list. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item to remove.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function removeItem(bytes32 _itemID, string calldata _evidence) external payable {
        Item storage item = items[_itemID];

        // Extremely unlikely, but we check that for correctness sake.
        require(item.requestCount < uint120(-1), "Too many requests for item.");
        require(item.status == Status.Registered, "Item must be registered to be removed.");

        Request storage request = item.requests[item.requestCount++];
        uint256 arbitrationParamsIndex = arbitrationParamsChanges.length - 1;
        IArbitrator arbitrator = arbitrationParamsChanges[arbitrationParamsIndex].arbitrator;
        bytes storage arbitratorExtraData = arbitrationParamsChanges[arbitrationParamsIndex].arbitratorExtraData;

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        uint256 totalCost = arbitrationCost.addCap(removalBaseDeposit);
        require(msg.value >= totalCost, "You must fully fund the request.");

        emit Contribution(_itemID, item.requestCount - 1, RESERVED_ROUND_ID, msg.sender, totalCost, Party.Requester);

        // Casting is safe here because this line will never be executed in case
        // totalCost > type(uint128).max, since it would be an unpayable value.
        item.sumDeposit = uint128(totalCost);
        item.status = Status.ClearingRequested;

        request.submissionTime = uint64(block.timestamp);
        request.arbitrationParamsIndex = uint24(arbitrationParamsIndex);
        request.requester = msg.sender;
        request.requestType = RequestType.Clearing;

        uint256 evidenceGroupID = getEvidenceGroupID(_itemID, item.requestCount - 1);

        emit RequestSubmitted(_itemID, evidenceGroupID);

        // Emit evidence if it was provided.
        if (bytes(_evidence).length > 0) {
            emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
        }

        if (msg.value > totalCost) {
            msg.sender.send(msg.value - totalCost);
        }
    }

    /**
     * @dev Challenges the request of the item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item which request to challenge.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function challengeRequest(bytes32 _itemID, string calldata _evidence) external payable {
        Item storage item = items[_itemID];
        require(item.status > Status.Registered, "The item must have a pending request.");

        uint256 lastRequestIndex = item.requestCount - 1;
        Request storage request = item.requests[lastRequestIndex];
        require(
            block.timestamp - request.submissionTime <= challengePeriodDuration,
            "Challenges must occur during the challenge period."
        );

        DisputeData storage disputeData = requestsDisputeData[_itemID][lastRequestIndex];
        require(disputeData.status == DisputeStatus.None, "The request should not have already been disputed.");

        ArbitrationParams storage arbitrationParams = arbitrationParamsChanges[request.arbitrationParamsIndex];
        IArbitrator arbitrator = arbitrationParams.arbitrator;

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitrationParams.arbitratorExtraData);
        uint256 totalCost;
        {
            uint256 challengerBaseDeposit = item.status == Status.RegistrationRequested
                ? submissionChallengeBaseDeposit
                : removalChallengeBaseDeposit;
            totalCost = arbitrationCost.addCap(challengerBaseDeposit);
        }
        require(msg.value >= totalCost, "You must fully fund the challenge.");

        emit Contribution(_itemID, lastRequestIndex, RESERVED_ROUND_ID, msg.sender, totalCost, Party.Challenger);

        // Casting is safe here because this line will never be executed in case
        // totalCost > type(uint128).max, since it would be an unpayable value.
        item.sumDeposit = item.sumDeposit.addCap(uint128(totalCost)).subCap(uint128(arbitrationCost));

        request.challenger = msg.sender;

        // Raise a dispute.
        disputeData.disputeID = arbitrator.createDispute.value(arbitrationCost)(
            RULING_OPTIONS,
            arbitrationParams.arbitratorExtraData
        );
        disputeData.status = DisputeStatus.AwaitingRuling;
        // For compatibility with GeneralizedTCR consider the request/challenge cycle
        // the first round (index 0), so we need to make the next round index 1.
        disputeData.roundCount = 2;

        arbitratorDisputeIDToItemID[address(arbitrator)][disputeData.disputeID] = _itemID;

        uint256 metaEvidenceID = 2 * request.arbitrationParamsIndex + uint256(request.requestType);
        uint256 evidenceGroupID = getEvidenceGroupID(_itemID, lastRequestIndex);
        emit Dispute(arbitrator, disputeData.disputeID, metaEvidenceID, evidenceGroupID);

        if (bytes(_evidence).length > 0) {
            emit Evidence(arbitrator, evidenceGroupID, msg.sender, _evidence);
        }

        if (msg.value > totalCost) {
            msg.sender.send(msg.value - totalCost);
        }
    }

    /**
     * @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if both sides are fully funded.
     * @param _itemID The ID of the item which request to fund.
     * @param _side The recipient of the contribution.
     */
    function fundAppeal(bytes32 _itemID, Party _side) external payable {
        require(_side > Party.None, "Invalid side.");

        Item storage item = items[_itemID];
        require(item.status > Status.Registered, "The item must have a pending request.");

        uint256 lastRequestIndex = item.requestCount - 1;
        Request storage request = item.requests[lastRequestIndex];

        DisputeData storage disputeData = requestsDisputeData[_itemID][lastRequestIndex];
        require(
            disputeData.status == DisputeStatus.AwaitingRuling,
            "A dispute must have been raised to fund an appeal."
        );

        ArbitrationParams storage arbitrationParams = arbitrationParamsChanges[request.arbitrationParamsIndex];
        IArbitrator arbitrator = arbitrationParams.arbitrator;

        uint256 lastRoundIndex = disputeData.roundCount - 1;
        Round storage round = disputeData.rounds[lastRoundIndex];
        require(round.sideFunded != _side, "Side already fully funded.");

        uint256 multiplier;
        {
            (uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(disputeData.disputeID);
            require(
                block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd,
                "Contributions must be made within the appeal period."
            );

            Party winner = Party(arbitrator.currentRuling(disputeData.disputeID));
            if (winner == Party.None) {
                multiplier = sharedStakeMultiplier;
            } else if (_side == winner) {
                multiplier = winnerStakeMultiplier;
            } else {
                multiplier = loserStakeMultiplier;
                require(
                    block.timestamp < (appealPeriodStart + appealPeriodEnd) / 2,
                    "The loser must contribute during the first half of the appeal period."
                );
            }
        }

        uint256 appealCost = arbitrator.appealCost(disputeData.disputeID, arbitrationParams.arbitratorExtraData);
        uint256 totalCost = appealCost.addCap(appealCost.mulCap(multiplier) / MULTIPLIER_DIVISOR);
        contribute(_itemID, lastRequestIndex, lastRoundIndex, uint256(_side), msg.sender, msg.value, totalCost);

        if (round.amountPaid[uint256(_side)] >= totalCost) {
            if (round.sideFunded == Party.None) {
                round.sideFunded = _side;
            } else {
                // Resets the value because both sides are funded.
                round.sideFunded = Party.None;

                // Raise appeal if both sides are fully funded.
                arbitrator.appeal.value(appealCost)(disputeData.disputeID, arbitrationParams.arbitratorExtraData);
                disputeData.roundCount++;
                round.feeRewards = round.feeRewards.subCap(appealCost);
            }
        }
    }

    /**
     * @dev If a dispute was raised, sends the fee stake rewards and reimbursements proportionally to the contributions made to the winner of a dispute.
     * @param _beneficiary The address that made contributions to a request.
     * @param _itemID The ID of the item submission to withdraw from.
     * @param _requestID The request from which to withdraw from.
     * @param _roundID The round from which to withdraw from.
     */
    function withdrawFeesAndRewards(
        address payable _beneficiary,
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID
    ) external {
        DisputeData storage disputeData = requestsDisputeData[_itemID][_requestID];

        require(disputeData.status == DisputeStatus.Resolved, "Request must be resolved.");

        Round storage round = disputeData.rounds[_roundID];

        uint256 reward;
        if (_roundID == disputeData.roundCount - 1) {
            // Reimburse if not enough fees were raised to appeal the ruling.
            reward =
                round.contributions[_beneficiary][uint256(Party.Requester)] +
                round.contributions[_beneficiary][uint256(Party.Challenger)];
        } else if (disputeData.ruling == Party.None) {
            uint256 totalFeesInRound = round.amountPaid[uint256(Party.Challenger)] +
                round.amountPaid[uint256(Party.Requester)];
            uint256 claimableFees = round.contributions[_beneficiary][uint256(Party.Challenger)] +
                round.contributions[_beneficiary][uint256(Party.Requester)];
            reward = totalFeesInRound > 0 ? (claimableFees * round.feeRewards) / totalFeesInRound : 0;
        } else {
            // Reward the winner.
            reward = round.amountPaid[uint256(disputeData.ruling)] > 0
                ? (round.contributions[_beneficiary][uint256(disputeData.ruling)] * round.feeRewards) /
                    round.amountPaid[uint256(disputeData.ruling)]
                : 0;
        }
        round.contributions[_beneficiary][uint256(Party.Requester)] = 0;
        round.contributions[_beneficiary][uint256(Party.Challenger)] = 0;

        if (reward > 0) {
            _beneficiary.send(reward);
            emit RewardWithdrawn(_beneficiary, _itemID, _requestID, _roundID, reward);
        }
    }

    /**
     * @dev Executes an unchallenged request if the challenge period has passed.
     * @param _itemID The ID of the item to execute.
     */
    function executeRequest(bytes32 _itemID) external {
        Item storage item = items[_itemID];
        uint256 lastRequestIndex = items[_itemID].requestCount - 1;

        Request storage request = item.requests[lastRequestIndex];
        require(block.timestamp - request.submissionTime > challengePeriodDuration, "Time to challenge the request must pass.");

        DisputeData storage disputeData = requestsDisputeData[_itemID][lastRequestIndex];
        require(disputeData.status == DisputeStatus.None, "The request should not be disputed.");

        if (item.status == Status.RegistrationRequested) {
            item.status = Status.Registered;
        } else if (item.status == Status.ClearingRequested) {
            item.status = Status.Absent;
        } else {
            revert("There must be a request.");
        }

        emit ItemStatusChange(_itemID, false);

        uint256 sumDeposit = item.sumDeposit;
        item.sumDeposit = 0;

        if (sumDeposit > 0) {
            // reimburse the requester
            request.requester.send(sumDeposit);
        }
    }

    /**
     * @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     * Accounts for the situation where the winner loses a case due to paying less appeal fees than expected.
     * @param _disputeID ID of the dispute in the arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external {
        require(_ruling <= RULING_OPTIONS, "Invalid ruling option");

        bytes32 itemID = arbitratorDisputeIDToItemID[msg.sender][_disputeID];
        Item storage item = items[itemID];
        uint256 lastRequestIndex = items[itemID].requestCount - 1;
        Request storage request = item.requests[lastRequestIndex];

        DisputeData storage disputeData = requestsDisputeData[itemID][lastRequestIndex];
        require(disputeData.status == DisputeStatus.AwaitingRuling, "The request must not be resolved.");

        ArbitrationParams storage arbitrationParams = arbitrationParamsChanges[request.arbitrationParamsIndex];
        require(address(arbitrationParams.arbitrator) == msg.sender, "Only the arbitrator can give a ruling");

        uint256 finalRuling;
        Round storage round = disputeData.rounds[disputeData.roundCount - 1];

        // If one side paid its fees, the ruling is in its favor.
        // Note that if the other side had also paid, sideFudned would have been reset
        // and an appeal would have been created.
        if (round.sideFunded == Party.Requester) {
            finalRuling = uint256(Party.Requester);
        } else if (round.sideFunded == Party.Challenger) {
            finalRuling = uint256(Party.Challenger);
        } else {
            finalRuling = _ruling;
        }

        emit Ruling(IArbitrator(msg.sender), _disputeID, finalRuling);

        Party winner = Party(finalRuling);

        disputeData.status = DisputeStatus.Resolved;
        disputeData.ruling = winner;

        uint256 sumDeposit = item.sumDeposit;
        item.sumDeposit = 0;

        if (winner == Party.None) {
            // If the arbitrator refuse to rule, then the item status should be the same it was before the request.
            // Regarding item.status this is equivalent to the challenger winning the dispute.
            item.status = item.status == Status.RegistrationRequested ? Status.Absent : Status.Registered;

            // Since nobody has won, then we reimburse both parties equally.
            // If item.sumDeposit is odd, 1 wei will remain in the contract balance.
            uint256 halfSumDeposit = sumDeposit / 2;

            request.requester.send(halfSumDeposit);
            request.challenger.send(halfSumDeposit);
        } else if (winner == Party.Requester) {
            item.status = item.status == Status.RegistrationRequested ? Status.Registered : Status.Absent;

            request.requester.send(sumDeposit);
        } else {
            item.status = item.status == Status.RegistrationRequested ? Status.Absent : Status.Registered;

            request.challenger.send(sumDeposit);
        }

        emit ItemStatusChange(itemID, false);
    }

    /**
     * @dev Submit a reference to evidence. EVENT.
     * @param _itemID The ID of the item which the evidence is related to.
     * @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _itemID, string calldata _evidence) external {
        Item storage item = items[_itemID];
        uint256 lastRequestIndex = item.requestCount - 1;

        Request storage request = item.requests[lastRequestIndex];
        ArbitrationParams storage arbitrationParams = arbitrationParamsChanges[request.arbitrationParamsIndex];

        emit Evidence(
            arbitrationParams.arbitrator,
            getEvidenceGroupID(_itemID, lastRequestIndex),
            msg.sender,
            _evidence
        );
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /**
     * @dev Change the duration of the challenge period.
     * @param _challengePeriodDuration The new duration of the challenge period.
     */
    function changeChallengePeriodDuration(uint256 _challengePeriodDuration) external onlyGovernor {
        challengePeriodDuration = _challengePeriodDuration;
    }

    /**
     * @dev Change the base amount required as a deposit to submit an item.
     * @param _submissionBaseDeposit The new base amount of wei required to submit an item.
     */
    function changeSubmissionBaseDeposit(uint256 _submissionBaseDeposit) external onlyGovernor {
        submissionBaseDeposit = _submissionBaseDeposit;
    }

    /**
     * @dev Change the base amount required as a deposit to remove an item.
     * @param _removalBaseDeposit The new base amount of wei required to remove an item.
     */
    function changeRemovalBaseDeposit(uint256 _removalBaseDeposit) external onlyGovernor {
        removalBaseDeposit = _removalBaseDeposit;
    }

    /**
     * @dev Change the base amount required as a deposit to challenge a submission.
     * @param _submissionChallengeBaseDeposit The new base amount of wei required to challenge a submission.
     */
    function changeSubmissionChallengeBaseDeposit(uint256 _submissionChallengeBaseDeposit) external onlyGovernor {
        submissionChallengeBaseDeposit = _submissionChallengeBaseDeposit;
    }

    /**
     * @dev Change the base amount required as a deposit to challenge a removal request.
     * @param _removalChallengeBaseDeposit The new base amount of wei required to challenge a removal request.
     */
    function changeRemovalChallengeBaseDeposit(uint256 _removalChallengeBaseDeposit) external onlyGovernor {
        removalChallengeBaseDeposit = _removalChallengeBaseDeposit;
    }

    /**
     * @dev Change the governor of the curated registry.
     * @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by parties when there is no winner or loser.
     * @param _sharedStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeSharedStakeMultiplier(uint256 _sharedStakeMultiplier) external onlyGovernor {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by the winner of the previous round.
     * @param _winnerStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeWinnerStakeMultiplier(uint256 _winnerStakeMultiplier) external onlyGovernor {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by the party that lost the previous round.
     * @param _loserStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeLoserStakeMultiplier(uint256 _loserStakeMultiplier) external onlyGovernor {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /**
     * @dev Change the address of connectedTCR, the Generalized TCR instance that stores addresses of TCRs related to this one.
     * @param _connectedTCR The address of the connectedTCR contract to use.
     */
    function changeConnectedTCR(address _connectedTCR) external onlyGovernor {
        emit ConnectedTCRSet(_connectedTCR);
    }

    /**
     * @dev Change the address of the relay contract.
     * @param _relayerContract The new address of the relay contract.
     */
    function changeRelayerContract(address _relayerContract) external onlyGovernor {
        relayerContract = _relayerContract;
    }

    /**
     * @notice Changes the params related to arbitration.
     * @dev Effectively makes all new items use the new set of params.
     * @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     * @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     * @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     * @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     */
    function changeArbitrationParams(
        IArbitrator _arbitrator,
        bytes calldata _arbitratorExtraData,
        string calldata _registrationMetaEvidence,
        string calldata _clearingMetaEvidence
    ) external onlyGovernor {
        _doChangeArbitrationParams(_arbitrator, _arbitratorExtraData, _registrationMetaEvidence, _clearingMetaEvidence);
    }

    /* Internal */

    /**
     * @dev Effectively makes all new items use the new set of params.
     * @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     * @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     * @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     * @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     */
    function _doChangeArbitrationParams(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence
    ) internal {
        emit MetaEvidence(2 * arbitrationParamsChanges.length, _registrationMetaEvidence);
        emit MetaEvidence(2 * arbitrationParamsChanges.length + 1, _clearingMetaEvidence);

        arbitrationParamsChanges.push(
            ArbitrationParams({arbitrator: _arbitrator, arbitratorExtraData: _arbitratorExtraData})
        );
    }

    /**
     * @notice Make a fee contribution.
     * @dev It cannot be inlined in fundAppeal because of the stack limit.
     * @param _itemID The item receiving the contribution.
     * @param _requestID The request to contribute.
     * @param _roundID The round to contribute.
     * @param _side The side for which to contribute.
     * @param _contributor The contributor.
     * @param _amount The amount contributed.
     * @param _totalRequired The total amount required for this side.
     * @return The amount of appeal fees contributed.
     */
    function contribute(
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID,
        uint256 _side,
        address payable _contributor,
        uint256 _amount,
        uint256 _totalRequired
    ) internal {
        Round storage round = requestsDisputeData[_itemID][_requestID].rounds[_roundID];
        uint256 pendingAmount = _totalRequired.subCap(round.amountPaid[_side]);

        // Take up to the amount necessary to fund the current round at the current costs.
        uint256 contribution; // Amount contributed.
        uint256 remainingETH; // Remaining ETH to send back.
        if (pendingAmount > _amount) {
            contribution = _amount;
        } else {
            contribution = pendingAmount;
            remainingETH = _amount - pendingAmount;
        }

        round.contributions[_contributor][_side] += contribution;
        round.amountPaid[_side] += contribution;
        round.feeRewards += contribution;

        // Reimburse leftover ETH.
        if (remainingETH > 0) {
            // Deliberate use of send in order to not block the contract in case of reverting fallback.
            _contributor.send(remainingETH);
        }

        if (contribution > 0) {
            emit Contribution(_itemID, _requestID, _roundID, msg.sender, contribution, Party(_side));
        }
    }

    // ************************ //
    // *       Getters        * //
    // ************************ //

    /**
     * @dev Gets the evidengeGroupID for a given item and request.
     * @param _itemID The ID of the item.
     * @param _requestID The ID of the request.
     * @return The evidenceGroupID
     */
    function getEvidenceGroupID(bytes32 _itemID, uint256 _requestID) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_itemID, _requestID)));
    }

    /**
     * @notice Gets the arbitrator for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator address.
     */
    function arbitrator() external view returns (IArbitrator) {
        return arbitrationParamsChanges[arbitrationParamsChanges.length - 1].arbitrator;
    }

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory) {
        return arbitrationParamsChanges[arbitrationParamsChanges.length - 1].arbitratorExtraData;
    }

    /**
     * @dev Gets the number of times MetaEvidence was updated.
     * @return The number of times MetaEvidence was updated.
     */
    function metaEvidenceUpdates() external view returns (uint256) {
        return arbitrationParamsChanges.length;
    }

    /**
     * @dev Gets the contributions made by a party for a given round of a request.
     * @param _itemID The ID of the item.
     * @param _requestID The request to query.
     * @param _roundID The round to query.
     * @param _contributor The address of the contributor.
     * @return contributions The contributions.
     */
    function getContributions(
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID,
        address _contributor
    ) external view returns (uint256[3] memory contributions) {
        DisputeData storage disputeData = requestsDisputeData[_itemID][_requestID];
        Round storage round = disputeData.rounds[_roundID];
        contributions = round.contributions[_contributor];
    }

    /**
     * @dev Returns item's information. Includes the total number of requests for the item
     * @param _itemID The ID of the queried item.
     * @return status The current status of the item.
     * @return numberOfRequests Total number of requests for the item.
     * @return sumDeposit The total deposit made by the requester and the challenger (if any)
     */
    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (
            Status status,
            uint256 numberOfRequests,
            uint256 sumDeposit
        )
    {
        Item storage item = items[_itemID];
        return (item.status, item.requestCount, item.sumDeposit);
    }

    /**
     * @dev Gets information on a request made for the item.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @return disputed True if a dispute was raised.
     * @return disputeID ID of the dispute, if any.
     * @return submissionTime Time when the request was made.
     * @return resolved True if the request was executed and/or any raised disputes were resolved.
     * @return parties Address of requester and challenger, if any.
     * @return numberOfRounds Number of rounds of dispute.
     * @return ruling The final ruling given, if any.
     * @return arbitrator The arbitrator trusted to solve disputes for this request.
     * @return arbitratorExtraData The extra data for the trusted arbitrator of this request.
     * @return metaEvidenceID The meta evidence to be used in a dispute for this case.
     */
    function getRequestInfo(bytes32 _itemID, uint256 _requestID)
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            IArbitrator requestArbitrator,
            bytes memory requestArbitratorExtraData,
            uint256 metaEvidenceID
        )
    {
        Item storage item = items[_itemID];
        require(item.requestCount > _requestID, "Request does not exist.");

        Request storage request = items[_itemID].requests[_requestID];

        submissionTime = request.submissionTime;
        parties[uint256(Party.Requester)] = request.requester;
        parties[uint256(Party.Challenger)] = request.challenger;

        (disputed, disputeID, numberOfRounds, ruling) = getRequestDisputeData(_itemID, _requestID);

        (requestArbitrator, requestArbitratorExtraData, metaEvidenceID) = getRequestArbitrationParams(
            _itemID,
            _requestID
        );
        resolved = getRequestResolvedStatus(_itemID, _requestID);
    }

    /**
     * @dev Gets the dispute data relative to a given item request.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @return disputed True if a dispute was raised.
     * @return disputeID ID of the dispute, if any.
     * @return ruling The final ruling given, if any.
     * @return numberOfRounds Number of rounds of dispute.
     */
    function getRequestDisputeData(bytes32 _itemID, uint256 _requestID)
        internal
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 numberOfRounds,
            Party ruling
        )
    {
        DisputeData storage disputeData = requestsDisputeData[_itemID][_requestID];

        return (
            disputeData.status >= DisputeStatus.AwaitingRuling,
            disputeData.disputeID,
            disputeData.roundCount,
            disputeData.ruling
        );
    }

    /**
     * @dev Gets the arbitration params relative to a given item request.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @return arbitrator The arbitrator trusted to solve disputes for this request.
     * @return arbitratorExtraData The extra data for the trusted arbitrator of this request.
     * @return metaEvidenceID The meta evidence to be used in a dispute for this case.
     */
    function getRequestArbitrationParams(bytes32 _itemID, uint256 _requestID)
        internal
        view
        returns (
            IArbitrator arbitrator,
            bytes memory arbitratorExtraData,
            uint256 metaEvidenceID
        )
    {
        Request storage request = items[_itemID].requests[_requestID];
        ArbitrationParams storage arbitrationParams = arbitrationParamsChanges[request.arbitrationParamsIndex];

        return (
            arbitrationParams.arbitrator,
            arbitrationParams.arbitratorExtraData,
            2 * request.arbitrationParamsIndex + uint256(request.requestType)
        );
    }

    /**
     * @dev Gets the resovled status of a given item request.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @return resolved True if the request was executed and/or any raised disputes were resolved.
     */
    function getRequestResolvedStatus(bytes32 _itemID, uint256 _requestID) internal view returns (bool resolved) {
        Item storage item = items[_itemID];

        if (item.requestCount == 0) {
            return false;
        }

        if (_requestID < item.requestCount - 1) {
            // It was resolved because it is not the last request.
            return true;
        }

        return item.sumDeposit == 0;
    }

    /**
     * @dev Gets the information of a round of a request.
     * @param _itemID The ID of the queried item.
     * @param _requestID The request to be queried.
     * @param _roundID The round to be queried.
     * @return appealed Whether appealed or not.
     * @return amountPaid Tracks the sum paid for each Party in this round.
     * @return hasPaid True if the Party has fully paid its fee in this round.
     * @return feeRewards Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
     */
    function getRoundInfo(
        bytes32 _itemID,
        uint256 _requestID,
        uint256 _roundID
    )
        external
        view
        returns (
            bool appealed,
            uint256[3] memory amountPaid,
            bool[3] memory hasPaid,
            uint256 feeRewards
        )
    {
        Item storage item = items[_itemID];
        require(item.requestCount > _requestID, "Request does not exist.");

        DisputeData storage disputeData = requestsDisputeData[_itemID][_requestID];
        require(disputeData.roundCount > _roundID, "Round does not exist");

        Round storage round = disputeData.rounds[_roundID];
        appealed = _roundID < disputeData.roundCount - 1;

        hasPaid[uint256(Party.Requester)] = appealed || round.sideFunded == Party.Requester;
        hasPaid[uint256(Party.Challenger)] = appealed || round.sideFunded == Party.Challenger;

        return (appealed, round.amountPaid, hasPaid, round.feeRewards);
    }
}


/**
 *  @title LightGTCRFactory
 *  This contract acts as a registry for LightGeneralizedTCR instances.
 */
contract LightGTCRFactory {
    /**
     *  @dev Emitted when a new Generalized TCR contract is deployed using this factory.
     *  @param _address The address of the newly deployed Generalized TCR.
     */
    event NewGTCR(LightGeneralizedTCR indexed _address);

    LightGeneralizedTCR[] public instances;
    address public GTCR;

    /**
     *  @dev Constructor.
     *  @param _GTCR Address of the generalized TCR contract that is going to be used for each new deployment.
     */
    constructor(address _GTCR) public {
        GTCR = _GTCR;
    }

    /**
     *  @dev Deploy the arbitrable curated registry.
     *  @param _arbitrator Arbitrator to resolve potential disputes. The arbitrator is trusted to support appeal periods and not reenter.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _connectedTCR The address of the TCR that stores related TCR addresses. This parameter can be left empty.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _governor The trusted governor of this contract.
     *  @param _baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param _challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param _stakeMultipliers Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round.
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     *  @param _relayContract The address of the relay contract to add/remove items directly.
     */
    function deploy(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        address _connectedTCR,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        address _governor,
        uint256[4] memory _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] memory _stakeMultipliers,
        address _relayContract
    ) public {
        LightGeneralizedTCR instance = clone(GTCR);
        instance.initialize(
            _arbitrator,
            _arbitratorExtraData,
            _connectedTCR,
            _registrationMetaEvidence,
            _clearingMetaEvidence,
            _governor,
            _baseDeposits,
            _challengePeriodDuration,
            _stakeMultipliers,
            _relayContract
        );
        instances.push(instance);
        emit NewGTCR(instance);
    }

    /**
     * @notice Adaptation of @openzeppelin/contracts/proxy/Clones.sol.
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `GTCR`.
     * @param _implementation Address of the contract to clone.
     * This function uses the create opcode, which should never revert.
     */
    function clone(address _implementation) internal returns (LightGeneralizedTCR instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != LightGeneralizedTCR(0), "ERC1167: create failed");
    }

    /**
     * @return The number of deployed tcrs using this factory.
     */
    function count() external view returns (uint256) {
        return instances.length;
    }
}



/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */


/**
 *  @title LightBatchWithdraw
 *  Withdraw fees and rewards from contributions to disputes rounds in batches.
 */
contract LightBatchWithdraw {
    /** @dev Withdraws rewards and reimbursements of multiple rounds at once. This function is O(n) where n is the number of rounds. This could exceed gas limits, therefore this function should be used only as a utility and not be relied upon by other contracts.
     *  @param _address The address of the LightGTCR.
     *  @param _contributor The address that made contributions to the request.
     *  @param _itemID The ID of the item with funds to be withdrawn.
     *  @param _request The request from which to withdraw contributions.
     *  @param _cursor The round from where to start withdrawing. Round 0 is always empty, so callers can safely start with 1.
     *  @param _count The number of rounds to iterate. If set to 0 or a value larger than the number of rounds, iterates until the last round.
     */
    function batchRoundWithdraw(
        address _address,
        address payable _contributor,
        bytes32 _itemID,
        uint256 _request,
        uint256 _cursor,
        uint256 _count
    ) public {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        (, , , , , uint256 numberOfRounds, , , , ) = gtcr.getRequestInfo(_itemID, _request);
        for (uint256 i = _cursor; i < numberOfRounds && (_count == 0 || i < _cursor + _count); i++)
            gtcr.withdrawFeesAndRewards(_contributor, _itemID, _request, i);
    }

    /** @dev Withdraws rewards and reimbursements of multiple requests at once. This function is O(n*m) where n is the number of requests and m is the number of rounds to withdraw per request. This could exceed gas limits, therefore this function should be used only as a utility and not be relied upon by other contracts.
     *  @param _address The address of the GTCR.
     *  @param _contributor The address that made contributions to the request.
     *  @param _itemID The ID of the item with funds to be withdrawn.
     *  @param _cursor The request from which to start withdrawing.
     *  @param _count The number of requests to iterate. If set to 0 or a value larger than the number of request, iterates until the last request.
     *  @param _roundCursor The round of each request from where to start withdrawing. Round 0 is always empty, so callers can safely start with 1.
     *  @param _roundCount The number of rounds to iterate on each request. If set to 0 or a value larger than the number of rounds a request has, iteration for that request will stop at the last round.
     */
    function batchRequestWithdraw(
        address _address,
        address payable _contributor,
        bytes32 _itemID,
        uint256 _cursor,
        uint256 _count,
        uint256 _roundCursor,
        uint256 _roundCount
    ) external {
        LightGeneralizedTCR gtcr = LightGeneralizedTCR(_address);
        (, uint256 numberOfRequests, ) = gtcr.getItemInfo(_itemID);
        for (uint256 i = _cursor; i < numberOfRequests && (_count == 0 || i < _cursor + _count); i++)
            batchRoundWithdraw(_address, _contributor, _itemID, i, _roundCursor, _roundCount);
    }
}
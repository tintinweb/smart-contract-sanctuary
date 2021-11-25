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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


 
 /**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */


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


interface ILightGeneralizedTCR {

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
    }

    struct Round {
        Party sideFunded; // Stores the side that successfully paid the appeal fees in the latest round. Note that if both sides have paid a new round is created.
        uint256 feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        uint256[3] amountPaid; // Tracks the sum paid for each Party in this round.
    }

    struct ArbitrationParams {
        IArbitrator arbitrator; // The arbitrator trusted to solve disputes for this request.
        bytes arbitratorExtraData; // The extra data for the trusted arbitrator of this request.
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
    ) external;

    /* External and Public */

    // ************************ //
    // *       Requests       * //
    // ************************ //

    /**
     * @dev Directly add an item to the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _item The URI to the item data.
     */
    function addItemDirectly(string calldata _item) external;

    /**
     * @dev Directly remove an item from the list bypassing request-challenge. Can only be used by the relay contract.
     * @param _itemID The ID of the item to remove.
     */
    function removeItemDirectly(bytes32 _itemID) external;

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable;

    /**
     * @dev Submit a request to remove an item from the list. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item to remove.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function removeItem(bytes32 _itemID, string calldata _evidence) external payable;

    /**
     * @dev Challenges the request of the item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _itemID The ID of the item which request to challenge.
     * @param _evidence A link to an evidence using its URI. Ignored if not provided.
     */
    function challengeRequest(bytes32 _itemID, string calldata _evidence) external payable ;

    /**
     * @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if both sides are fully funded.
     * @param _itemID The ID of the item which request to fund.
     * @param _side The recipient of the contribution.
     */
    function fundAppeal(bytes32 _itemID, Party _side) external payable ;

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
    ) external ;

    /**
     * @dev Executes an unchallenged request if the challenge period has passed.
     * @param _itemID The ID of the item to execute.
     */
    function executeRequest(bytes32 _itemID) external;

    /**
     * @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     * Accounts for the situation where the winner loses a case due to paying less appeal fees than expected.
     * @param _disputeID ID of the dispute in the arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;

    /**
     * @dev Submit a reference to evidence. EVENT.
     * @param _itemID The ID of the item which the evidence is related to.
     * @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _itemID, string calldata _evidence) external;

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /**
     * @dev Change the duration of the challenge period.
     * @param _challengePeriodDuration The new duration of the challenge period.
     */
    function changeChallengePeriodDuration(uint256 _challengePeriodDuration) external;
    /**
     * @dev Change the base amount required as a deposit to submit an item.
     * @param _submissionBaseDeposit The new base amount of wei required to submit an item.
     */
    function changeSubmissionBaseDeposit(uint256 _submissionBaseDeposit) external;

    /**
     * @dev Change the base amount required as a deposit to remove an item.
     * @param _removalBaseDeposit The new base amount of wei required to remove an item.
     */
    function changeRemovalBaseDeposit(uint256 _removalBaseDeposit) external;

    /**
     * @dev Change the base amount required as a deposit to challenge a submission.
     * @param _submissionChallengeBaseDeposit The new base amount of wei required to challenge a submission.
     */
    function changeSubmissionChallengeBaseDeposit(uint256 _submissionChallengeBaseDeposit) external;

    /**
     * @dev Change the base amount required as a deposit to challenge a removal request.
     * @param _removalChallengeBaseDeposit The new base amount of wei required to challenge a removal request.
     */
    function changeRemovalChallengeBaseDeposit(uint256 _removalChallengeBaseDeposit) external;

    /**
     * @dev Change the governor of the curated registry.
     * @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external;

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by parties when there is no winner or loser.
     * @param _sharedStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeSharedStakeMultiplier(uint256 _sharedStakeMultiplier) external;

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by the winner of the previous round.
     * @param _winnerStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeWinnerStakeMultiplier(uint256 _winnerStakeMultiplier) external;

    /**
     * @dev Change the proportion of arbitration fees that must be paid as fee stake by the party that lost the previous round.
     * @param _loserStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeLoserStakeMultiplier(uint256 _loserStakeMultiplier) external;

    /**
     * @dev Change the address of connectedTCR, the Generalized TCR instance that stores addresses of TCRs related to this one.
     * @param _connectedTCR The address of the connectedTCR contract to use.
     */
    function changeConnectedTCR(address _connectedTCR) external;

    /**
     * @dev Change the address of the relay contract.
     * @param _relayerContract The new address of the relay contract.
     */
    function changeRelayerContract(address _relayerContract) external;

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
    ) external;    

    // ************************ //
    // *       Getters        * //
    // ************************ //

    /**
     * @dev Gets the evidengeGroupID for a given item and request.
     * @param _itemID The ID of the item.
     * @param _requestID The ID of the request.
     * @return The evidenceGroupID
     */
    function getEvidenceGroupID(bytes32 _itemID, uint256 _requestID) external pure returns (uint256);

    /**
     * @notice Gets the arbitrator for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator address.
     */
    function arbitrator() external view returns (IArbitrator);

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory);

    /**
     * @dev Gets the number of times MetaEvidence was updated.
     * @return The number of times MetaEvidence was updated.
     */
    function metaEvidenceUpdates() external view returns (uint256);

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
    ) external view returns (uint256[3] memory contributions);

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
        );

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
        );    

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
        );

    function governor() external view returns (address);

    function relayerContract() external view returns (address);

    function submissionBaseDeposit() external view returns (uint256);

    function removalBaseDeposit() external view returns (uint256);

    function submissionChallengeBaseDeposit() external view returns (uint256);

    function removalChallengeBaseDeposit() external view returns (uint256);

    function challengePeriodDuration() external view returns (uint256);

    function winnerStakeMultiplier() external view returns (uint256);

    function loserStakeMultiplier() external view returns (uint256);

    function sharedStakeMultiplier() external view returns (uint256);

    function MULTIPLIER_DIVISOR() external view returns (uint256);

    function items(bytes32 _itemID) external view returns (Item memory);

    function arbitratorDisputeIDToItemID(address _address, uint256 _disputeID) external view returns (bytes32);

    function requestsDisputeData(bytes32 _itemID, uint256 _requestID) external view returns (DisputeData memory);

    function arbitrationParamsChanges(uint256 _index) external view returns (ArbitrationParams memory);
}


/**
 *  @title LightGeneralizedTCRView
 *  A view contract to fetch, batch, parse and return GTCR contract data efficiently.
 *  This contract includes functions that can halt execution due to out-of-gas exceptions. Because of this it should never be relied upon by other contracts.
 */
contract LightGeneralizedTCRView {
    struct QueryResult {
        bytes32 ID;
        ILightGeneralizedTCR.Status status;
        bool disputed;
        bool resolved;
        uint256 disputeID;
        uint256 appealCost;
        bool appealed;
        uint256 appealStart;
        uint256 appealEnd;
        ILightGeneralizedTCR.Party ruling;
        address requester;
        address challenger;
        address arbitrator;
        bytes arbitratorExtraData;
        ILightGeneralizedTCR.Party currentRuling;
        bool[3] hasPaid;
        uint256 feeRewards;
        uint256 submissionTime;
        uint256[3] amountPaid;
        IArbitrator.DisputeStatus disputeStatus;
        uint256 numberOfRequests;
    }

    struct ArbitrableData {
        address governor;
        address arbitrator;
        bytes arbitratorExtraData;
        uint256 submissionBaseDeposit;
        uint256 removalBaseDeposit;
        uint256 submissionChallengeBaseDeposit;
        uint256 removalChallengeBaseDeposit;
        uint256 challengePeriodDuration;
        uint256 metaEvidenceUpdates;
        uint256 winnerStakeMultiplier;
        uint256 loserStakeMultiplier;
        uint256 sharedStakeMultiplier;
        uint256 MULTIPLIER_DIVISOR;
        uint256 arbitrationCost;
    }

    /** @dev Fetch arbitrable TCR data in a single call.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @return The latest data on an arbitrable TCR contract.
     */
    function fetchArbitrable(address _address) external view returns (ArbitrableData memory result) {
        ILightGeneralizedTCR tcr = ILightGeneralizedTCR(_address);
        result.governor = tcr.governor();
        result.arbitrator = address(tcr.arbitrator());
        result.arbitratorExtraData = tcr.arbitratorExtraData();
        result.submissionBaseDeposit = tcr.submissionBaseDeposit();
        result.removalBaseDeposit = tcr.removalBaseDeposit();
        result.submissionChallengeBaseDeposit = tcr.submissionChallengeBaseDeposit();
        result.removalChallengeBaseDeposit = tcr.removalChallengeBaseDeposit();
        result.challengePeriodDuration = tcr.challengePeriodDuration();
        result.metaEvidenceUpdates = tcr.metaEvidenceUpdates();
        result.winnerStakeMultiplier = tcr.winnerStakeMultiplier();
        result.loserStakeMultiplier = tcr.loserStakeMultiplier();
        result.sharedStakeMultiplier = tcr.sharedStakeMultiplier();
        result.MULTIPLIER_DIVISOR = tcr.MULTIPLIER_DIVISOR();
        result.arbitrationCost = IArbitrator(result.arbitrator).arbitrationCost(result.arbitratorExtraData);
    }

    /** @dev Fetch the latest data on an item in a single call.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The item data.
     */
    function getItem(address _address, bytes32 _itemID) public view returns (QueryResult memory result) {
        RoundData memory round = getLatestRoundRequestData(_address, _itemID);
        result = QueryResult({
            ID: _itemID,
            status: round.request.item.status,
            disputed: round.request.disputed,
            resolved: round.request.resolved,
            disputeID: round.request.disputeID,
            appealCost: 0,
            appealed: round.appealed,
            appealStart: 0,
            appealEnd: 0,
            ruling: round.request.ruling,
            requester: round.request.parties[uint256(ILightGeneralizedTCR.Party.Requester)],
            challenger: round.request.parties[uint256(ILightGeneralizedTCR.Party.Challenger)],
            arbitrator: address(round.request.arbitrator),
            arbitratorExtraData: round.request.arbitratorExtraData,
            currentRuling: ILightGeneralizedTCR.Party.None,
            hasPaid: round.hasPaid,
            feeRewards: round.feeRewards,
            submissionTime: round.request.submissionTime,
            amountPaid: round.amountPaid,
            disputeStatus: IArbitrator.DisputeStatus.Waiting,
            numberOfRequests: round.request.item.numberOfRequests
        });
        if (
            round.request.disputed &&
            round.request.arbitrator.disputeStatus(result.disputeID) == IArbitrator.DisputeStatus.Appealable
        ) {
            result.currentRuling = ILightGeneralizedTCR.Party(round.request.arbitrator.currentRuling(result.disputeID));
            result.disputeStatus = round.request.arbitrator.disputeStatus(result.disputeID);
            (result.appealStart, result.appealEnd) = round.request.arbitrator.appealPeriod(result.disputeID);
            result.appealCost = round.request.arbitrator.appealCost(result.disputeID, result.arbitratorExtraData);
        }
    }

    struct ItemRequest {
        bool disputed;
        uint256 disputeID;
        uint256 submissionTime;
        bool resolved;
        address requester;
        address challenger;
        address arbitrator;
        bytes arbitratorExtraData;
        uint256 metaEvidenceID;
    }

    /** @dev Fetch all requests for an item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The items requests.
     */
    function getItemRequests(address _address, bytes32 _itemID) external view returns (ItemRequest[] memory requests) {
        ILightGeneralizedTCR gtcr = ILightGeneralizedTCR(_address);
        ItemData memory itemData = getItemData(_address, _itemID);
        requests = new ItemRequest[](itemData.numberOfRequests);
        for (uint256 i = 0; i < itemData.numberOfRequests; i++) {
            (
                bool disputed,
                uint256 disputeID,
                uint256 submissionTime,
                bool resolved,
                address payable[3] memory parties,
                ,
                ,
                IArbitrator arbitrator,
                bytes memory arbitratorExtraData,
                uint256 metaEvidenceID
            ) = gtcr.getRequestInfo(_itemID, i);

            // Sort requests by newest first.
            requests[itemData.numberOfRequests - i - 1] = ItemRequest({
                disputed: disputed,
                disputeID: disputeID,
                submissionTime: submissionTime,
                resolved: resolved,
                requester: parties[uint256(ILightGeneralizedTCR.Party.Requester)],
                challenger: parties[uint256(ILightGeneralizedTCR.Party.Challenger)],
                arbitrator: address(arbitrator),
                arbitratorExtraData: arbitratorExtraData,
                metaEvidenceID: metaEvidenceID
            });
        }
    }

    /** @dev Return the withdrawable rewards for a contributor.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @param _contributor The address of the contributor.
     *  @return The amount withdrawable per round per request.
     */
    function availableRewards(
        address _address,
        bytes32 _itemID,
        address _contributor
    ) external view returns (uint256 rewards) {
        ILightGeneralizedTCR gtcr = ILightGeneralizedTCR(_address);

        // Using arrays to avoid stack limit.
        uint256[2] memory requestRoundCount = [uint256(0), uint256(0)];
        uint256[2] memory indexes = [uint256(0), uint256(0)]; // Request index and round index.

        (, requestRoundCount[0], ) = gtcr.getItemInfo(_itemID);
        for (indexes[0]; indexes[0] < requestRoundCount[0]; indexes[0]++) {
            ILightGeneralizedTCR.Party ruling;
            bool resolved;
            (, , , resolved, , requestRoundCount[1], ruling, , , ) = gtcr.getRequestInfo(_itemID, indexes[0]);
            if (!resolved) continue;
            for (indexes[1]; indexes[1] < requestRoundCount[1]; indexes[1]++) {
                (, uint256[3] memory amountPaid, bool[3] memory hasPaid, uint256 feeRewards) = gtcr.getRoundInfo(
                    _itemID,
                    indexes[0],
                    indexes[1]
                );

                uint256[3] memory roundContributions = gtcr.getContributions(
                    _itemID,
                    indexes[0],
                    indexes[1],
                    _contributor
                );
                if (
                    !hasPaid[uint256(ILightGeneralizedTCR.Party.Requester)] ||
                    !hasPaid[uint256(ILightGeneralizedTCR.Party.Challenger)]
                ) {
                    // Amount reimbursable if not enough fees were raised to appeal the ruling.
                    rewards +=
                        roundContributions[uint256(ILightGeneralizedTCR.Party.Requester)] +
                        roundContributions[uint256(ILightGeneralizedTCR.Party.Challenger)];
                } else if (ruling == ILightGeneralizedTCR.Party.None) {
                    // Reimbursable fees proportional if there aren't a winner and loser.
                    rewards += amountPaid[uint256(ILightGeneralizedTCR.Party.Requester)] > 0
                        ? (roundContributions[uint256(ILightGeneralizedTCR.Party.Requester)] * feeRewards) /
                            (amountPaid[uint256(ILightGeneralizedTCR.Party.Challenger)] +
                                amountPaid[uint256(ILightGeneralizedTCR.Party.Requester)])
                        : 0;
                    rewards += amountPaid[uint256(ILightGeneralizedTCR.Party.Challenger)] > 0
                        ? (roundContributions[uint256(ILightGeneralizedTCR.Party.Challenger)] * feeRewards) /
                            (amountPaid[uint256(ILightGeneralizedTCR.Party.Challenger)] +
                                amountPaid[uint256(ILightGeneralizedTCR.Party.Requester)])
                        : 0;
                } else {
                    // Contributors to the winner take the rewards.
                    rewards += amountPaid[uint256(ruling)] > 0
                        ? (roundContributions[uint256(ruling)] * feeRewards) / amountPaid[uint256(ruling)]
                        : 0;
                }
            }
            indexes[1] = 0;
        }
    }

    // Functions and structs below used mainly to avoid stack limit.
    struct ItemData {
        ILightGeneralizedTCR.Status status;
        uint256 numberOfRequests;
    }

    struct RequestData {
        ItemData item;
        bool disputed;
        uint256 disputeID;
        uint256 submissionTime;
        bool resolved;
        address payable[3] parties;
        uint256 numberOfRounds;
        ILightGeneralizedTCR.Party ruling;
        IArbitrator arbitrator;
        bytes arbitratorExtraData;
    }

    struct RoundData {
        RequestData request;
        bool appealed;
        uint256[3] amountPaid;
        bool[3] hasPaid;
        uint256 feeRewards;
    }

    /** @dev Fetch data of the an item and return a struct.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getItemData(address _address, bytes32 _itemID) public view returns (ItemData memory item) {
        ILightGeneralizedTCR gtcr = ILightGeneralizedTCR(_address);
        (ILightGeneralizedTCR.Status status, uint256 numberOfRequests, ) = gtcr.getItemInfo(_itemID);
        item = ItemData(status, numberOfRequests);
    }

    /** @dev Fetch the latest request of item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getLatestRequestData(address _address, bytes32 _itemID) public view returns (RequestData memory request) {
        ILightGeneralizedTCR gtcr = ILightGeneralizedTCR(_address);
        ItemData memory item = getItemData(_address, _itemID);
        (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            ILightGeneralizedTCR.Party ruling,
            IArbitrator arbitrator,
            bytes memory arbitratorExtraData,

        ) = gtcr.getRequestInfo(_itemID, item.numberOfRequests - 1);
        request = RequestData(
            item,
            disputed,
            disputeID,
            submissionTime,
            resolved,
            parties,
            numberOfRounds,
            ruling,
            arbitrator,
            arbitratorExtraData
        );
    }

    /** @dev Fetch the latest round of the latest request of an item.
     *  @param _address The address of the LightGeneralized TCR to query.
     *  @param _itemID The ID of the item to query.
     *  @return The round data.
     */
    function getLatestRoundRequestData(address _address, bytes32 _itemID) public view returns (RoundData memory round) {
        ILightGeneralizedTCR gtcr = ILightGeneralizedTCR(_address);
        (, , uint256 sumDeposit) = gtcr.getItemInfo(_itemID);
        RequestData memory request = getLatestRequestData(_address, _itemID);

        if (request.disputed) {
            (bool appealed, uint256[3] memory amountPaid, bool[3] memory hasPaid, uint256 feeRewards) = gtcr
                .getRoundInfo(_itemID, request.item.numberOfRequests - 1, request.numberOfRounds - 1);

            round = RoundData(request, appealed, amountPaid, hasPaid, feeRewards);
        } else {
            round = RoundData(request, false, [0, sumDeposit, 0], [false, true, false], sumDeposit);
        }
    }
}
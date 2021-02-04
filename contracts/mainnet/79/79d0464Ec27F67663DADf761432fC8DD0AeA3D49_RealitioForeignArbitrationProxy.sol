/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu*]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu*]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity >=0.7;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {Waiting, Appealable, Solved}

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import {IArbitrable} from "@kleros/erc-792/contracts/IArbitrable.sol";
import {IEvidence} from "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";

interface IHomeArbitrationProxy {
    /**
     * @notice To be emitted when the Realitio contract has been notified of an arbitration request.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     * @param _maxPrevious The maximum value of the previous bond for the question.
     */
    event RequestNotified(bytes32 indexed _questionID, address indexed _requester, uint256 _maxPrevious);

    /**
     * @notice To be emitted when arbitration request is rejected.
     * @dev This can happen if the current bond for the question is higher than maxPrevious
     * or if the question is already finalized.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     * @param _maxPrevious The maximum value of the current bond for the question.
     * @param _reason The reason why the request was rejected.
     */
    event RequestRejected(
        bytes32 indexed _questionID,
        address indexed _requester,
        uint256 _maxPrevious,
        string _reason
    );

    /**
     * @notice To be emitted when the arbitration request acknowledgement is sent to the Foreign Chain.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    event RequestAcknowledged(bytes32 indexed _questionID, address indexed _requester);

    /**
     * @notice To be emitted when the arbitration request is canceled.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    event RequestCanceled(bytes32 indexed _questionID, address indexed _requester);

    /**
     * @notice To be emitted when the dispute could not be created on the Foreign Chain.
     * @dev This will happen if the arbitration fee increases in between the arbitration request and acknowledgement.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    event ArbitrationFailed(bytes32 indexed _questionID, address indexed _requester);

    /**
     * @notice To be emitted when receiving the answer from the arbitrator.
     * @param _questionID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    event ArbitratorAnswered(bytes32 indexed _questionID, bytes32 _answer);

    /**
     * @notice To be emitted when reporting the arbitrator answer to Realitio.
     * @param _questionID The ID of the question.
     */
    event ArbitrationFinished(bytes32 indexed _questionID);

    /**
     * @dev Receives the requested arbitration for a question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     * @param _maxPrevious The maximum value of the current bond for the question. The arbitration request will get rejected if the current bond is greater than _maxPrevious. If set to 0, _maxPrevious is ignored.
     */
    function receiveArbitrationRequest(
        bytes32 _questionID,
        address _requester,
        uint256 _maxPrevious
    ) external;

    /**
     * @notice Handles arbitration request after it has been notified to Realitio for a given question.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function handleNotifiedRequest(bytes32 _questionID, address _requester) external;

    /**
     * @notice Handles arbitration request after it has been rejected.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * Reasons why the request might be rejected:
     *  - The question does not exist
     *  - The question was not answered yet
     *  - The quesiton bond value changed while the arbitration was being requested
     *  - Another request was already accepted
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function handleRejectedRequest(bytes32 _questionID, address _requester) external;

    /**
     * @notice Receives a failed attempt to request arbitration. TRUSTED.
     * @dev Currently this can happen only if the arbitration cost increased.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function receiveArbitrationFailure(bytes32 _questionID, address _requester) external;

    /**
     * @notice Receives the answer to a specified question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    function receiveArbitrationAnswer(bytes32 _questionID, bytes32 _answer) external;
}

interface IForeignArbitrationProxy is IArbitrable, IEvidence {
    /**
     * @notice Should be emitted when the arbitration is requested.
     * @param _questionID The ID of the question with the request for arbitration.
     * @param _requester The address of the arbitration requester.
     * @param _maxPrevious The maximum value of the current bond for the question. The arbitration request will get rejected if the current bond is greater than _maxPrevious. If set to 0, _maxPrevious is ignored.
     */
    event ArbitrationRequested(bytes32 indexed _questionID, address indexed _requester, uint256 _maxPrevious);

    /**
     * @notice Should be emitted when the dispute is created.
     * @param _questionID The ID of the question with the request for arbitration.
     * @param _requester The address of the arbitration requester.
     * @param _disputeID The ID of the dispute.
     */
    event ArbitrationCreated(bytes32 indexed _questionID, address indexed _requester, uint256 indexed _disputeID);

    /**
     * @notice Should be emitted when the arbitration is canceled by the Home Chain.
     * @param _questionID The ID of the question with the request for arbitration.
     * @param _requester The address of the arbitration requester.
     */
    event ArbitrationCanceled(bytes32 indexed _questionID, address indexed _requester);

    /**
     * @notice Should be emitted when the dispute could not be created.
     * @dev This will happen if there is an increase in the arbitration fees
     * between the time the arbitration is made and the time it is acknowledged.
     * @param _questionID The ID of the question with the request for arbitration.
     * @param _requester The address of the arbitration requester.
     */
    event ArbitrationFailed(bytes32 indexed _questionID, address indexed _requester);

    /**
     * @notice Requests arbitration for the given question.
     * @param _questionID The ID of the question.
     * @param _maxPrevious The maximum value of the current bond for the question. The arbitration request will get rejected if the current bond is greater than _maxPrevious. If set to 0, _maxPrevious is ignored.
     */
    function requestArbitration(bytes32 _questionID, uint256 _maxPrevious) external payable;

    /**
     * @notice Receives the acknowledgement of the arbitration request for the given question and requester. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function receiveArbitrationAcknowledgement(bytes32 _questionID, address _requester) external;

    /**
     * @notice Receives the cancelation of the arbitration request for the given question and requester. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function receiveArbitrationCancelation(bytes32 _questionID, address _requester) external;

    /**
     * @notice Cancels the arbitration in case the dispute could not be created.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function handleFailedDisputeCreation(bytes32 _questionID, address _requester) external;

    /**
     * @notice Gets the fee to create a dispute.
     * @param _questionID the ID of the question.
     * @return The fee to create a dispute.
     */
    function getDisputeFee(bytes32 _questionID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@hbarcelos]
 *  @reviewers: [@ferittuncer*, @fnanni-0, @nix1g, @epiqueras*, @clesaege, @unknownunknown1]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.2;

import {IArbitrator} from "@kleros/erc-792/contracts/IArbitrator.sol";
import {IAMB} from "./dependencies/IAMB.sol";
import {IForeignArbitrationProxy, IHomeArbitrationProxy} from "./ArbitrationProxyInterfaces.sol";

/**
 * @title Arbitration proxy for Realitio on Ethereum side (A.K.A. the Foreign Chain).
 * @dev This contract is meant to be deployed to the Ethereum chains where Kleros is deployed.
 */
contract RealitioForeignArbitrationProxy is IForeignArbitrationProxy {
    /// @dev ArbitraryMessageBridge contract address. TRUSTED.
    IAMB public immutable amb;

    /// @dev Address of the counter-party proxy on the Home Chain. TRUSTED.
    address public immutable homeProxy;

    /// @dev The chain ID where the home proxy is deployed.
    bytes32 public immutable homeChainId;

    /// @dev The address of the arbitrator. TRUSTED.
    IArbitrator public immutable arbitrator;

    /// @dev The extra data used to raise a dispute in the arbitrator.
    bytes public arbitratorExtraData;

    /// @dev The path for the Terms of Service for Kleros as an arbitrator for Realitio.
    string public termsOfService;

    /// @dev The ID of the MetaEvidence for disputes.
    uint256 public constant META_EVIDENCE_ID = 0;

    /// @dev The number of choices for the arbitrator. Kleros is currently able to provide ruling values of up to 2^256 - 2.
    uint256 public constant NUMBER_OF_CHOICES_FOR_ARBITRATOR = type(uint256).max - 1;

    enum Status {None, Requested, Created, Ruled, Failed}

    struct ArbitrationRequest {
        Status status; // Status of the arbitration.
        uint248 deposit; // The deposit paid by the requester at the time of the arbitration.
    }

    struct DisputeDetails {
        bytes32 questionID; // The question ID for the dispute.
        address requester; // The address of the requester who managed to go through with the arbitration request.
    }

    /// @dev Tracks arbitration requests for question ID. arbitrationRequests[questionID][requester]
    mapping(bytes32 => mapping(address => ArbitrationRequest)) public arbitrationRequests;

    /// @dev Associates dispute ID to question ID and the requester. disputeIDToDisputeDetails[disputeID] -> {questionID, requester}
    mapping(uint256 => DisputeDetails) public disputeIDToDisputeDetails;

    /// @dev Whether a dispute has already been created for the given question ID or not. questionIDToDisputeExists[questionID]
    mapping(bytes32 => bool) public questionIDToDisputeExists;

    modifier onlyArbitrator() {
        require(msg.sender == address(arbitrator), "Only arbitrator allowed");
        _;
    }

    modifier onlyHomeProxy() {
        require(msg.sender == address(amb), "Only AMB allowed");
        require(amb.messageSourceChainId() == homeChainId, "Only home chain allowed");
        require(amb.messageSender() == homeProxy, "Only home proxy allowed");
        _;
    }

    /**
     * @notice Creates an arbitration proxy on the foreign chain.
     * @param _amb ArbitraryMessageBridge contract address.
     * @param _homeProxy The address of the proxy contract in the counter-party Home Chain (i.e.: xDAI)
     * @param _homeChainId The ID of the counter-party Home Chain.
     * @param _arbitrator Arbitrator contract address.
     * @param _arbitratorExtraData The extra data used to raise a dispute in the arbitrator.
     * @param _metaEvidence The URI of the meta evidence file.
     * @param _termsOfService The path for the Terms of Service for Kleros as an arbitrator for Realitio.
     */
    constructor(
        IAMB _amb,
        address _homeProxy,
        bytes32 _homeChainId,
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaEvidence,
        string memory _termsOfService
    ) {
        amb = _amb;
        homeProxy = _homeProxy;
        homeChainId = _homeChainId;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        termsOfService = _termsOfService;

        emit MetaEvidence(META_EVIDENCE_ID, _metaEvidence);
    }

    /**
     * @notice Requests arbitration for the given question and contested answer.
     * @param _questionID The ID of the question.
     * @param _maxPrevious The maximum value of the current bond for the question. The arbitration request will get rejected if the current bond is greater than _maxPrevious. If set to 0, _maxPrevious is ignored.
     */
    function requestArbitration(bytes32 _questionID, uint256 _maxPrevious) external payable override {
        require(!questionIDToDisputeExists[_questionID], "Dispute already exists");

        ArbitrationRequest storage arbitration = arbitrationRequests[_questionID][msg.sender];
        require(arbitration.status == Status.None, "Arbitration already requested");

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= arbitrationCost, "Deposit value too low");

        arbitration.status = Status.Requested;
        arbitration.deposit = uint248(msg.value);

        bytes4 methodSelector = IHomeArbitrationProxy(0).receiveArbitrationRequest.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _questionID, msg.sender, _maxPrevious);
        amb.requireToPassMessage(homeProxy, data, amb.maxGasPerTx());

        emit ArbitrationRequested(_questionID, msg.sender, _maxPrevious);
    }

    /**
     * @notice Receives the acknowledgement of the arbitration request for the given question and requester. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function receiveArbitrationAcknowledgement(bytes32 _questionID, address _requester)
        external
        override
        onlyHomeProxy
    {
        ArbitrationRequest storage arbitration = arbitrationRequests[_questionID][_requester];
        require(arbitration.status == Status.Requested, "Invalid arbitration status");

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        if (arbitration.deposit >= arbitrationCost) {
            try
                arbitrator.createDispute{value: arbitrationCost}(NUMBER_OF_CHOICES_FOR_ARBITRATOR, arbitratorExtraData)
            returns (uint256 disputeID) {
                DisputeDetails storage disputeDetails = disputeIDToDisputeDetails[disputeID];
                disputeDetails.questionID = _questionID;
                disputeDetails.requester = _requester;

                questionIDToDisputeExists[_questionID] = true;

                // At this point, arbitration.deposit is guaranteed to be greater than or equal to the arbitration cost.
                uint256 remainder = arbitration.deposit - arbitrationCost;

                arbitration.status = Status.Created;
                arbitration.deposit = 0;

                if (remainder > 0) {
                    payable(_requester).send(remainder);
                }

                emit ArbitrationCreated(_questionID, _requester, disputeID);
                emit Dispute(arbitrator, disputeID, META_EVIDENCE_ID, uint256(_questionID));
            } catch {
                arbitration.status = Status.Failed;
                emit ArbitrationFailed(_questionID, _requester);
            }
        } else {
            arbitration.status = Status.Failed;
            emit ArbitrationFailed(_questionID, _requester);
        }
    }

    /**
     * @notice Receives the cancelation of the arbitration request for the given question and requester. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function receiveArbitrationCancelation(bytes32 _questionID, address _requester) external override onlyHomeProxy {
        ArbitrationRequest storage arbitration = arbitrationRequests[_questionID][_requester];
        require(arbitration.status == Status.Requested, "Invalid arbitration status");
        uint256 deposit = arbitration.deposit;

        delete arbitrationRequests[_questionID][_requester];

        payable(_requester).send(deposit);

        emit ArbitrationCanceled(_questionID, _requester);
    }

    /**
     * @notice Cancels the arbitration in case the dispute could not be created.
     * @param _questionID The ID of the question.
     * @param _requester The address of the arbitration requester.
     */
    function handleFailedDisputeCreation(bytes32 _questionID, address _requester) external override {
        ArbitrationRequest storage arbitration = arbitrationRequests[_questionID][_requester];
        require(arbitration.status == Status.Failed, "Invalid arbitration status");
        uint256 deposit = arbitration.deposit;

        delete arbitrationRequests[_questionID][_requester];

        payable(_requester).send(deposit);

        bytes4 methodSelector = IHomeArbitrationProxy(0).receiveArbitrationFailure.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _questionID, _requester);
        amb.requireToPassMessage(homeProxy, data, amb.maxGasPerTx());

        emit ArbitrationCanceled(_questionID, _requester);
    }

    /**
     * @notice Rules a specified dispute.
     * @dev Note that 0 is reserved for "Unable/refused to arbitrate" and we map it to `bytes32(-1)` which has a similar meaning in Realitio.
     * @param _disputeID The ID of the dispute in the ERC792 arbitrator.
     * @param _ruling The ruling given by the arbitrator.
     */
    function rule(uint256 _disputeID, uint256 _ruling) external override onlyArbitrator {
        DisputeDetails storage disputeDetails = disputeIDToDisputeDetails[_disputeID];
        bytes32 questionID = disputeDetails.questionID;
        address requester = disputeDetails.requester;

        ArbitrationRequest storage arbitration = arbitrationRequests[questionID][requester];
        require(arbitration.status == Status.Created, "Invalid arbitration status");

        arbitration.status = Status.Ruled;

        // Realitio ruling is shifted by 1 compared to Kleros.
        // For example, jurors refusing to rule is `0` on Kleros, but uint(-1) on Realitio.
        // The line below could be written more explicitly as:
        //     bytes32(_ruling == 0 ? uint256(-1) : _ruling - 1)
        // But the way it is written saves some gas.
        bytes32 answer = bytes32(_ruling - 1);

        bytes4 methodSelector = IHomeArbitrationProxy(0).receiveArbitrationAnswer.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, questionID, answer);
        amb.requireToPassMessage(homeProxy, data, amb.maxGasPerTx());

        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    /**
     * @notice Gets the fee to create a dispute.
     * @param _questionID the ID of the question.
     * @return The fee to create a dispute.
     */
    function getDisputeFee(bytes32 _questionID) external view override returns (uint256) {
        return arbitrator.arbitrationCost(arbitratorExtraData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

interface IAMB {
    function requireToPassMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);

    function maxGasPerTx() external view returns (uint256);

    function messageSender() external view returns (address);

    function messageSourceChainId() external view returns (bytes32);

    function messageId() external view returns (bytes32);
}
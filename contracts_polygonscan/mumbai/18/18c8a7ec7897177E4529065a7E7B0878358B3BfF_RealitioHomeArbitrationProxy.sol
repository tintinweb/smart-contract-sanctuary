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
 *  @reviewers: [@ferittuncer, @fnanni-0, @nix1g, @epiqueras*, @clesaege, @unknownunknown1]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: [0xe40DD83a262da3f56976038F1554Fe541Fa75ecd]
 */

pragma solidity ^0.7.2;

import {FxBaseChildTunnel} from "./dependencies/FxBaseChildTunnel.sol";
import {RealitioInterface} from "./dependencies/RealitioInterface.sol";
import {IForeignArbitrationProxy, IHomeArbitrationProxy} from "./ArbitrationProxyInterfaces.sol";

/**
 * @title Arbitration proxy for Realitio on the side-chain side (A.K.A. the Home Chain).
 * @dev This contract is meant to be deployed to side-chains (i.e.: xDAI) in which Reality.eth is deployed.
 */
contract RealitioHomeArbitrationProxy is IHomeArbitrationProxy, FxBaseChildTunnel {
    /// @dev The address of the Realitio contract (v2.1+ required). TRUSTED.
    RealitioInterface public immutable realitio;

    /// @dev Metadata for Realitio interface.
    string public constant metadata = '{"foreignProxy":true}';

    enum Status {
        None,
        Rejected,
        Notified,
        AwaitingRuling,
        Ruled,
        Finished
    }

    struct Request {
        Status status;
        bytes32 arbitratorAnswer;
    }

    /// @dev Associates an arbitration request with a question ID and a requester address. requests[questionID][requester]
    mapping(bytes32 => mapping(address => Request)) public requests;

    /// @dev Associates a question ID with the requester who succeeded in requesting arbitration. questionIDToRequester[questionID]
    mapping(bytes32 => address) public questionIDToRequester;

    /**
     * @notice Creates an arbitration proxy on the home chain.
     * @param _fxChild Address of the FxChild contract of the Polygon bridge
     * @param _foreignProxy The address of the proxy.
     * @param _realitio Realitio contract address.
     */
    constructor(
        address _fxChild,
        address _foreignProxy,
        RealitioInterface _realitio
    ) FxBaseChildTunnel(_fxChild, _foreignProxy) {
        realitio = _realitio;
    }

    /**
     * @dev Receives the requested arbitration for a question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _requester The address of the user that requested arbitration.
     * @param _maxPrevious The maximum value of the previous bond for the question.
     */
    function receiveArbitrationRequest(
        bytes32 _questionID,
        address _requester,
        uint256 _maxPrevious
    ) public override {
        require(msg.sender == address(this), "Can only be called via bridge");
        Request storage request = requests[_questionID][_requester];
        require(request.status == Status.None, "Request already exists");

        try realitio.notifyOfArbitrationRequest(_questionID, _requester, _maxPrevious) {
            request.status = Status.Notified;
            questionIDToRequester[_questionID] = _requester;

            emit RequestNotified(_questionID, _requester, _maxPrevious);
        } catch Error(string memory reason) {
            /*
             * Will fail if:
             *  - The question does not exist.
             *  - The question was not answered yet.
             *  - Another request was already accepted.
             *  - Someone increased the bond on the question to a value > _maxPrevious
             */
            request.status = Status.Rejected;

            emit RequestRejected(_questionID, _requester, _maxPrevious, reason);
        } catch {
            // In case `reject` did not have a reason string or some other error happened
            request.status = Status.Rejected;

            emit RequestRejected(_questionID, _requester, _maxPrevious, "");
        }
    }

    /**
     * @notice Handles arbitration request after it has been notified to Realitio for a given question.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * @param _questionID The ID of the question.
     * @param _requester The address of the user that requested arbitration.
     */
    function handleNotifiedRequest(bytes32 _questionID, address _requester) external override {
        Request storage request = requests[_questionID][_requester];
        require(request.status == Status.Notified, "Invalid request status");

        request.status = Status.AwaitingRuling;

        bytes4 selector = IForeignArbitrationProxy(0).receiveArbitrationAcknowledgement.selector;
        bytes memory data = abi.encodeWithSelector(selector, _questionID, _requester);
        _sendMessageToRoot(data);

        emit RequestAcknowledged(_questionID, _requester);
    }

    /**
     * @notice Handles arbitration request after it has been rejected.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * Reasons why the request might be rejected:
     *  - The question does not exist
     *  - The question was not answered yet
     *  - The quesiton bond value changed while the arbitration was being requested
     *  - Another request was already accepted
     * @param _questionID The ID of the question.
     * @param _requester The address of the user that requested arbitration.
     */
    function handleRejectedRequest(bytes32 _questionID, address _requester) external override {
        Request storage request = requests[_questionID][_requester];
        require(request.status == Status.Rejected, "Invalid request status");

        // At this point, only the request.status is set, simply reseting the status to Status.None is enough.
        request.status = Status.None;

        bytes4 selector = IForeignArbitrationProxy(0).receiveArbitrationCancelation.selector;
        bytes memory data = abi.encodeWithSelector(selector, _questionID, _requester);
        _sendMessageToRoot(data);

        emit RequestCanceled(_questionID, _requester);
    }

    /**
     * @notice Receives a failed attempt to request arbitration. TRUSTED.
     * @dev Currently this can happen only if the arbitration cost increased.
     * @param _questionID The ID of the question.
     * @param _requester The address of the user that requested arbitration.
     */
    function receiveArbitrationFailure(bytes32 _questionID, address _requester) public override {
        require(msg.sender == address(this), "Can only be called via bridge");
        Request storage request = requests[_questionID][_requester];
        require(request.status == Status.AwaitingRuling, "Invalid request status");

        // At this point, only the request.status is set, simply reseting the status to Status.None is enough.
        request.status = Status.None;

        realitio.cancelArbitration(_questionID);

        emit ArbitrationFailed(_questionID, _requester);
    }

    /**
     * @notice Receives the answer to a specified question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    function receiveArbitrationAnswer(bytes32 _questionID, bytes32 _answer) public override {
        require(msg.sender == address(this), "Can only be called via bridge");
        address requester = questionIDToRequester[_questionID];
        Request storage request = requests[_questionID][requester];
        require(request.status == Status.AwaitingRuling, "Invalid request status");

        request.status = Status.Ruled;
        request.arbitratorAnswer = _answer;

        emit ArbitratorAnswered(_questionID, _answer);
    }

    /**
     * @notice Reports the answer provided by the arbitrator to a specified question.
     * @dev The Realitio contract validates the input parameters passed to this method,
     * so making this publicly accessible is safe.
     * @param _questionID The ID of the question.
     * @param _lastHistoryHash The history hash given with the last answer to the question in the Realitio contract.
     * @param _lastAnswerOrCommitmentID The last answer given, or its commitment ID if it was a commitment,
     * to the question in the Realitio contract.
     * @param _lastAnswerer The last answerer to the question in the Realitio contract.
     */
    function reportArbitrationAnswer(
        bytes32 _questionID,
        bytes32 _lastHistoryHash,
        bytes32 _lastAnswerOrCommitmentID,
        address _lastAnswerer
    ) external {
        address requester = questionIDToRequester[_questionID];
        Request storage request = requests[_questionID][requester];
        require(request.status == Status.Ruled, "Arbitrator has not ruled yet");

        realitio.assignWinnerAndSubmitAnswerByArbitrator(
            _questionID,
            request.arbitratorAnswer,
            requester,
            _lastHistoryHash,
            _lastAnswerOrCommitmentID,
            _lastAnswerer
        );

        request.status = Status.Finished;

        emit ArbitrationFinished(_questionID);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory _data
    ) internal override validateSender(sender) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(_data);
        require(success, "Failed to call contract");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);
    address public fxChild;
    address public fxRootTunnel;

    constructor(address _fxChild, address _fxRootTunnel) {
        fxChild = _fxChild;
        fxRootTunnel = _fxRootTunnel;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: MIT

/** Interface of https://github.com/realitio/realitio-contracts/blob/master/truffle/contracts/Realitio_v2_1.sol original contract is to be reviewed.
 *  @reviewers: [@hbarcelos, @fnanni-0, @nix1g, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.2;

interface RealitioInterface {
    event LogNewAnswer(
        bytes32 answer,
        bytes32 indexed question_id,
        bytes32 history_hash,
        address indexed user,
        uint256 bond,
        uint256 ts,
        bool is_commitment
    );

    event LogNewTemplate(uint256 indexed template_id, address indexed user, string question_text);

    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user,
        uint256 template_id,
        string question,
        bytes32 indexed content_hash,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce,
        uint256 created
    );

    /**
     * @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
     * @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
     * @param question_id The ID of the question.
     * @param requester The account that requested arbitration.
     * @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
     */
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external;

    /**
     * @notice Cancel a previously-requested arbitration and extend the timeout
     * @dev Useful when doing arbitration across chains that can't be requested atomically
     * @param question_id The ID of the question
     */
    function cancelArbitration(bytes32 question_id) external;

    /**
     * @notice Submit the answer for a question, for use by the arbitrator, working out the appropriate winner based on the last answer details.
     * @dev Doesn't require (or allow) a bond.
     * @param question_id The ID of the question
     * @param answer The answer, encoded into bytes32
     * @param payee_if_wrong The account to be credited as winner if the last answer given is wrong, usually the account that paid the arbitrator
     * @param last_history_hash The history hash before the final one
     * @param last_answer_or_commitment_id The last answer given, or the commitment ID if it was a commitment.
     * @param last_answerer The address that supplied the last answer
     */
    function assignWinnerAndSubmitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address payee_if_wrong,
        bytes32 last_history_hash,
        bytes32 last_answer_or_commitment_id,
        address last_answerer
    ) external;
}


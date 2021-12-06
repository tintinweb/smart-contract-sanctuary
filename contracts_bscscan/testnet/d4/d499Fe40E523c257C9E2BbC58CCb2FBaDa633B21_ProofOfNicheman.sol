/**
    Nicheman — has superpower

    TG: @NichemanToken
    URL: Nicheman.com
    Website:  https://nicheman.com/
    Telegram: https://t.me/NichemanToken
    Twitter:  https://twitter.com/NichemanToken
    SPDX-License-Identifier: GPL-3.0-or-later
 */
 
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IArbitrable.sol";
import "./interfaces/IEvidence.sol";
import "./interfaces/IArbitrator.sol";
import "./libraries/CappedMath.sol";

/**
 *  @title ProofOfNicheman
 *  This contract is a curated registry for people. The users are identified by their address and can be added or removed through the request-challenge protocol.
 *  In order to challenge a registration request the challenger must provide one of the four reasons.
 *  New registration requests firstly should gain sufficient amount of vouches from other registered users and only after that they can be accepted or challenged.
 *  The users who vouched for submission that lost the challenge with the reason Duplicate or DoesNotExist would be penalized with optional fine or ban period.
 *  NOTE: This contract trusts that the Arbitrator is honest and will not reenter or modify its costs during a call.
 *  The arbitrator must support appeal period.
 */
contract ProofOfNicheman is Initializable,IArbitrable, IEvidence {
    using CappedMath for uint;
    using CappedMath for uint64;

    /* Constants and immutable */

    uint private constant RULING_OPTIONS = 2; // The amount of non 0 choices the arbitrator can give.
    uint private constant AUTO_PROCESSED_VOUCH = 10; // The number of vouches that will be automatically processed when executing a request.
    uint private constant FULL_REASONS_SET = 15; // Indicates that reasons' bitmap is full. 0b1111.
    uint private constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    bytes32 private DOMAIN_SEPARATOR; // The EIP-712 domainSeparator specific to this deployed instance. It is used to verify the IsHumanVoucher's signature.
    bytes32 private constant IS_HUMAN_VOUCHER_TYPEHASH = 0xa9e3fa1df5c3dbef1e9cfb610fa780355a0b5e0acb0fa8249777ec973ca789dc; // The EIP-712 typeHash of IsHumanVoucher. keccak256("IsHumanVoucher(address vouchedSubmission,uint256 voucherExpirationTimestamp)").

    /* Enums */

    enum Status {
        None, // The submission doesn't have a pending status.
        Vouching, // The submission is in the state where it can be vouched for and crowdfunded.
        PendingRegistration, // The submission is in the state where it can be challenged. Or accepted to the list, if there are no challenges within the time limit.
        PendingRemoval // The submission is in the state where it can be challenged. Or removed from the list, if there are no challenges within the time limit.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenged the request to change a status.
    }

    enum Reason {
        None, // No reason specified. This option should be used to challenge removal requests.
        IncorrectSubmission, // The submission does not comply with the submission rules.
        Deceased, // The submitter has existed but does not exist anymore.
        Duplicate, // The submitter is already registered. The challenger has to point to the identity already registered or to a duplicate submission.
        DoesNotExist // The submitter is not real. For example, this can be used for videos showing computer generated persons.
    }

    /* Structs */

    struct Submission {
        Status status; // The current status of the submission.
        bool registered; // Whether the submission is in the registry or not. Note that a registered submission won't have privileges (e.g. vouching) if its duration expired.
        bool hasVouched; // True if this submission used its vouch for another submission. This is set back to false once the vouch is processed.
        uint64 submissionTime; // The time when the submission was accepted to the list.
        uint64 index; // Index of a submission.
        Request[] requests; // List of status change requests made for the submission.
    }

    struct Request {
        bool disputed; // True if a dispute was raised. Note that the request can enter disputed state multiple times, once per reason.
        bool resolved; // True if the request is executed and/or all raised disputes are resolved.
        bool requesterLost; // True if the requester has already had a dispute that wasn't ruled in his favor.
        Reason currentReason; // Current reason a registration request was challenged with. Is left empty for removal requests.
        uint8 usedReasons; // Bitmap of the reasons used by challengers of this request.
        uint16 nbParallelDisputes; // Tracks the number of simultaneously raised disputes. Parallel disputes are only allowed for reason Duplicate.
        uint16 arbitratorDataID; // The index of the relevant arbitratorData struct. All the arbitrator info is stored in a separate struct to reduce gas cost.
        uint16 lastChallengeID; // The ID of the last challenge, which is equal to the total number of challenges for the request.
        uint32 lastProcessedVouch; // Stores the index of the last processed vouch in the array of vouches. It is used for partial processing of the vouches in resolved submissions.
        uint64 currentDuplicateIndex; // Stores the index of the duplicate submission provided by the challenger who is currently winning.
        uint64 challengePeriodStart; // Time when the submission can be challenged.
        address payable requester; // Address that made a request. It is left empty for the registration requests since it matches submissionID in that case.
        address payable ultimateChallenger; // Address of the challenger who won a dispute. Users who vouched for the challenged submission must pay the fines to this address.
        address[] vouches; // Stores the addresses of submissions that vouched for this request and whose vouches were used in this request.
        mapping(uint => Challenge) challenges; // Stores all the challenges of this request. challengeID -> Challenge.
        mapping(address => bool) challengeDuplicates; // Indicates whether a certain duplicate address has been used in a challenge or not.
    }

    // Some arrays below have 3 elements to map with the Party enums for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Round {
        uint[3] paidFees; // Tracks the fees paid by each side in this round.
        Party sideFunded; // Stores the side that successfully paid the appeal fees in the latest round. Note that if both sides have paid a new round is created.
        uint feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        mapping(address => uint[3]) contributions; // Maps contributors to their contributions for each side.
    }

    struct Challenge {
        uint disputeID; // The ID of the dispute related to the challenge.
        Party ruling; // Ruling given by the arbitrator of the dispute.
        uint16 lastRoundID; // The ID of the last round.
        uint64 duplicateSubmissionIndex; // Index of a submission, which is a supposed duplicate of a challenged submission. It is only used for reason Duplicate.
        address payable challenger; // Address that challenged the request.
        mapping(uint => Round) rounds; // Tracks the info of each funding round of the challenge.
    }

    // The data tied to the arbitrator that will be needed to recover the submission info for arbitrator's call.
    struct DisputeData {
        uint96 challengeID; // The ID of the challenge of the request.
        address submissionID; // The submission, which ongoing request was challenged.
    }

    struct ArbitratorData {
        IArbitrator arbitrator; // Address of the trusted arbitrator to solve disputes.
        uint96 metaEvidenceUpdates; // The meta evidence to be used in disputes.
        bytes arbitratorExtraData; // Extra data for the arbitrator.
    }

    address public governor; // The address that can make governance changes to the parameters of the contract.
    uint public submissionBaseDeposit; // The base deposit to make a new request for a submission.
    
    // Note that to ensure correct contract behaviour the sum of challengePeriodDuration and renewalPeriodDuration should be less than submissionDuration.
    uint64 public submissionDuration; // Time after which the registered submission will no longer be considered registered. The submitter has to reapply to the list to refresh it.
    uint64 public renewalPeriodDuration; //  The duration of the period when the registered submission can reapply.
    uint64 public challengePeriodDuration; // The time after which a request becomes executable if not challenged. Note that this value should be less than the time spent on potential dispute's resolution, to avoid complications of parallel dispute handling.

    uint64 public requiredNumberOfVouches; // The number of registered users that have to vouch for a new registration request in order for it to enter PendingRegistration state.

    uint public sharedStakeMultiplier; // Multiplier for calculating the fee stake that must be paid in the case where arbitrator refused to arbitrate.
    uint public winnerStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that won the previous round.
    uint public loserStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that lost the previous round.

    uint public submissionCounter; // The total count of all submissions that made a registration request at some point. Includes manually added submissions as well.

    ArbitratorData[] public arbitratorDataList; // Stores the arbitrator data of the contract. Updated each time the data is changed.

    mapping(address => Submission) private submissions; // Maps the submission ID to its data. submissions[submissionID]. It is private because of getSubmissionInfo().
    mapping(address => mapping(address => bool)) public vouches; // Indicates whether or not the voucher has vouched for a certain submission. vouches[voucherID][submissionID].
    mapping(address => mapping(uint => DisputeData)) public arbitratorDisputeIDToDisputeData; // Maps a dispute ID with its data. arbitratorDisputeIDToDisputeData[arbitrator][disputeID].

    
    modifier onlyGovernor {require(msg.sender == governor, "The caller must be the governor"); _;}

    /* Events */

    /**
     *  @dev Emitted when a vouch is added.
     *  @param _submissionID The submission that receives the vouch.
     *  @param _voucher The address that vouched.
     */
    event VouchAdded(address indexed _submissionID, address indexed _voucher);

    /**
     *  @dev Emitted when a vouch is removed.
     *  @param _submissionID The submission which vouch is removed.
     *  @param _voucher The address that removes its vouch.
     */
    event VouchRemoved(address indexed _submissionID, address indexed _voucher);

    /** @dev Emitted when the request to add a submission to the registry is made.
     *  @param _submissionID The ID of the submission.
     *  @param _requestID The ID of the newly created request.
     */
    event AddSubmission(address indexed _submissionID, uint _requestID);

    /** @dev Emitted when the reapplication request is made.
     *  @param _submissionID The ID of the submission.
     *  @param _requestID The ID of the newly created request.
     */
    event ReapplySubmission(address indexed _submissionID, uint _requestID);

    /** @dev Emitted when the removal request is made.
     *  @param _requester The address that made the request.
     *  @param _submissionID The ID of the submission.
     *  @param _requestID The ID of the newly created request.
     */
    event RemoveSubmission(address indexed _requester, address indexed _submissionID, uint _requestID);

    /** @dev Emitted when the submission is challenged.
     *  @param _submissionID The ID of the submission.
     *  @param _requestID The ID of the latest request.
     *  @param _challengeID The ID of the challenge.
     */
    event SubmissionChallenged(address indexed _submissionID, uint indexed _requestID, uint _challengeID);

    /** @dev Emitted when someone contributes to the appeal process.
     *  @param _submissionID The ID of the submission.
     *  @param _challengeID The index of the challenge.
     *  @param _party The party which received the contribution.
     *  @param _contributor The address of the contributor.
     *  @param _amount The amount contributed.
     */
    event AppealContribution(address indexed _submissionID, uint indexed _challengeID, Party _party, address indexed _contributor, uint _amount);

    /** @dev Emitted when one of the parties successfully paid its appeal fees.
     *  @param _submissionID The ID of the submission.
     *  @param _challengeID The index of the challenge which appeal was funded.
     *  @param _side The side that is fully funded.
     */
    event HasPaidAppealFee(address indexed _submissionID, uint indexed _challengeID, Party _side);

    /** @dev Emitted when the challenge is resolved.
     *  @param _submissionID The ID of the submission.
     *  @param _requestID The ID of the latest request.
     *  @param _challengeID The ID of the challenge that was resolved.
     */
    event ChallengeResolved(address indexed _submissionID, uint indexed _requestID, uint _challengeID);

    /** @dev Emitted in the constructor using most of its parameters.
     *  This event is needed for Subgraph. ArbitratorExtraData and renewalPeriodDuration are not needed for this event.
     */
    event ArbitratorComplete(
        IArbitrator _arbitrator,
        address indexed _governor,
        uint _submissionBaseDeposit,
        uint _submissionDuration,
        uint _challengePeriodDuration,
        uint _requiredNumberOfVouches,
        uint _sharedStakeMultiplier,
        uint _winnerStakeMultiplier,
        uint _loserStakeMultiplier
    );

    /** @dev Constructor.
     *  @param _arbitrator The trusted arbitrator to resolve potential disputes.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param _submissionBaseDeposit The base deposit to make a request for a submission.
     *  @param _submissionDuration Time in seconds during which the registered submission won't automatically lose its status.
     *  @param _renewalPeriodDuration Value that defines the duration of submission's renewal period.
     *  @param _challengePeriodDuration The time in seconds during which the request can be challenged.
     *  @param _multipliers The array that contains fee stake multipliers to avoid 'stack too deep' error.
     *  @param _requiredNumberOfVouches The number of vouches the submission has to have to pass from Vouching to PendingRegistration state.
     */
     function initialize(
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _registrationMetaEvidence,
        string memory _clearingMetaEvidence,
        uint _submissionBaseDeposit,
        uint64 _submissionDuration,
        uint64 _renewalPeriodDuration,
        uint64 _challengePeriodDuration,
        uint[3] memory _multipliers,
        uint64 _requiredNumberOfVouches
    ) public initializer {
        emit MetaEvidence(0, _registrationMetaEvidence);
        emit MetaEvidence(1, _clearingMetaEvidence);
        governor = msg.sender;
        submissionBaseDeposit = _submissionBaseDeposit;
        submissionDuration = _submissionDuration;
        renewalPeriodDuration = _renewalPeriodDuration;
        challengePeriodDuration = _challengePeriodDuration;
        sharedStakeMultiplier = _multipliers[0];
        winnerStakeMultiplier = _multipliers[1];
        loserStakeMultiplier = _multipliers[2];
        requiredNumberOfVouches = _requiredNumberOfVouches;
        arbitratorDataList.push();
	    uint256 newIndex = arbitratorDataList.length - 1;
        arbitratorDataList[newIndex].arbitrator = _arbitrator;
        arbitratorDataList[newIndex].arbitratorExtraData = _arbitratorExtraData;
        emit ArbitratorComplete(_arbitrator, msg.sender, _submissionBaseDeposit, _submissionDuration, _challengePeriodDuration, _requiredNumberOfVouches, _multipliers[0], _multipliers[1], _multipliers[2]);

        // EIP-712.
        bytes32 DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866; // keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)").
        uint256 chainId;
        assembly { chainId := chainid() } // block.chainid got introduced in Solidity v0.8.0.
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256("Proof of Nicheman"), chainId, address(this)));
    }

    /* External and Public */

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Allow the governor to directly add new submissions to the list as a part of the seeding event.
     *  @param _submissionIDs The addresses of newly added submissions.
     *  @param _evidence The array of evidence links for each submission.
     *  @param _names The array of names of the submitters. This parameter is for Subgraph only and it won't be used in this function.
     */
    function addSubmissionManually(address[] calldata _submissionIDs, string[] calldata _evidence, string[] calldata _names) external onlyGovernor {
        uint counter = submissionCounter;
        uint arbitratorDataID = arbitratorDataList.length - 1;
        for (uint i = 0; i < _submissionIDs.length; i++) {
            Submission storage submission = submissions[_submissionIDs[i]];
            require(submission.requests.length == 0, "Submission already been created");
            submission.index = uint64(counter);
            counter++;

            // Request storage request = submission.requests[submission.requests.length++];
            // request.arbitratorDataID = uint16(arbitratorDataID);
            // request.resolved = true;
            submission.registered = true;
            submission.submissionTime = uint64(block.timestamp);
            
            // submission.requests.push(Request({arbitratorDataID:uint16(arbitratorDataID),resolved:true}));

            if (bytes(_evidence[i]).length > 0)
                emit Evidence(arbitratorDataList[arbitratorDataID].arbitrator, f(_submissionIDs[i]), msg.sender, _evidence[i]);
        }
        submissionCounter = counter;
    }

    /** @dev Allow the governor to directly remove a registered entry from the list as a part of the seeding event.
     *  @param _submissionID The address of a submission to remove.
     */
    function removeSubmissionManually(address _submissionID) external onlyGovernor {
        Submission storage submission = submissions[_submissionID];
        require(submission.registered && submission.status == Status.None, "Wrong status");
        submission.registered = false;
    }

    /** @dev Change the base amount required as a deposit to make a request for a submission.
     *  @param _submissionBaseDeposit The new base amount of wei required to make a new request.
     */
    function changeSubmissionBaseDeposit(uint _submissionBaseDeposit) external onlyGovernor {
        submissionBaseDeposit = _submissionBaseDeposit;
    }

    /** @dev Change the duration of the submission, renewal and challenge periods.
     *  @param _submissionDuration The new duration of the time the submission is considered registered.
     *  @param _renewalPeriodDuration The new value that defines the duration of submission's renewal period.
     *  @param _challengePeriodDuration The new duration of the challenge period. It should be lower than the time for a dispute.
     */
    function changeDurations(uint64 _submissionDuration, uint64 _renewalPeriodDuration, uint64 _challengePeriodDuration) external onlyGovernor {
        require(_challengePeriodDuration.addCap64(_renewalPeriodDuration) < _submissionDuration, "Incorrect inputs");
        submissionDuration = _submissionDuration;
        renewalPeriodDuration = _renewalPeriodDuration;
        challengePeriodDuration = _challengePeriodDuration;
    }

    /** @dev Change the number of vouches required for the request to pass to the pending state.
     *  @param _requiredNumberOfVouches The new required number of vouches.
     */
    function changeRequiredNumberOfVouches(uint64 _requiredNumberOfVouches) external onlyGovernor {
        requiredNumberOfVouches = _requiredNumberOfVouches;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by parties when there is no winner or loser (e.g. when the arbitrator refused to rule).
     *  @param _sharedStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeSharedStakeMultiplier(uint _sharedStakeMultiplier) external onlyGovernor {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by the winner of the previous round.
     *  @param _winnerStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeWinnerStakeMultiplier(uint _winnerStakeMultiplier) external onlyGovernor {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

    /** @dev Change the proportion of arbitration fees that must be paid as fee stake by the party that lost the previous round.
     *  @param _loserStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeLoserStakeMultiplier(uint _loserStakeMultiplier) external onlyGovernor {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /** @dev Change the governor of the contract.
     *  @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

    /** @dev Update the meta evidence used for disputes.
     *  @param _registrationMetaEvidence The meta evidence to be used for future registration request disputes.
     *  @param _clearingMetaEvidence The meta evidence to be used for future clearing request disputes.
     */
    function changeMetaEvidence(string calldata _registrationMetaEvidence, string calldata _clearingMetaEvidence) external onlyGovernor {
        ArbitratorData storage arbitratorData = arbitratorDataList[arbitratorDataList.length - 1];
        uint96 newMetaEvidenceUpdates = arbitratorData.metaEvidenceUpdates + 1;
        arbitratorDataList.push(ArbitratorData({
            arbitrator: arbitratorData.arbitrator,
            metaEvidenceUpdates: newMetaEvidenceUpdates,
            arbitratorExtraData: arbitratorData.arbitratorExtraData
        }));
        emit MetaEvidence(2 * newMetaEvidenceUpdates, _registrationMetaEvidence);
        emit MetaEvidence(2 * newMetaEvidenceUpdates + 1, _clearingMetaEvidence);
    }

    /** @dev Change the arbitrator to be used for disputes that may be raised in the next requests. The arbitrator is trusted to support appeal period and not reenter.
     *  @param _arbitrator The new trusted arbitrator to be used in the next requests.
     *  @param _arbitratorExtraData The extra data used by the new arbitrator.
     */
    function changeArbitrator(IArbitrator _arbitrator, bytes calldata _arbitratorExtraData) external onlyGovernor {
        ArbitratorData storage arbitratorData = arbitratorDataList[arbitratorDataList.length - 1];
        arbitratorDataList.push(ArbitratorData({
            arbitrator: _arbitrator,
            metaEvidenceUpdates: arbitratorData.metaEvidenceUpdates,
            arbitratorExtraData: _arbitratorExtraData
        }));
    }

    // ************************ //
    // *       Requests       * //
    // ************************ //

    /** @dev Make a request to add a new entry to the list. Paying the full deposit right away is not required as it can be crowdfunded later.
     *  @param _evidence A link to evidence using its URI.
     *  @param _name The name of the submitter. This parameter is for Subgraph only and it won't be used in this function.
     */
    function addSubmission(string calldata _evidence, string calldata _name) external payable {
        Submission storage submission = submissions[msg.sender];
        require(!submission.registered && submission.status == Status.None, "Wrong status");
        if (submission.requests.length == 0) {
            submission.index = uint64(submissionCounter);
            submissionCounter++;
        }
        submission.status = Status.Vouching;
        emit AddSubmission(msg.sender, submission.requests.length);
        requestRegistration(msg.sender, _evidence);
    }

    /** @dev Make a request to refresh a submissionDuration. Paying the full deposit right away is not required as it can be crowdfunded later.
     *  Note that the user can reapply even when current submissionDuration has not expired, but only after the start of renewal period.
     *  @param _evidence A link to evidence using its URI.
     *  @param _name The name of the submitter. This parameter is for Subgraph only and it won't be used in this function.
     */
    function reapplySubmission(string calldata _evidence, string calldata _name) external payable {
        Submission storage submission = submissions[msg.sender];
        require(submission.registered && submission.status == Status.None, "Wrong status");
        uint renewalAvailableAt = submission.submissionTime.addCap64(submissionDuration.subCap64(renewalPeriodDuration));
        require(block.timestamp >= renewalAvailableAt, "Can't reapply yet");
        submission.status = Status.Vouching;
        emit ReapplySubmission(msg.sender, submission.requests.length);
        requestRegistration(msg.sender, _evidence);
    }

    /** @dev Make a request to remove a submission from the list. Requires full deposit. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  Note that this request can't be made during the renewal period to avoid spam leading to submission's expiration.
     *  @param _submissionID The address of the submission to remove.
     *  @param _evidence A link to evidence using its URI.
     */
    function removeSubmission(address _submissionID, string calldata _evidence) external payable {
        Submission storage submission = submissions[_submissionID];
        require(submission.registered && submission.status == Status.None, "Wrong status");
        uint renewalAvailableAt = submission.submissionTime.addCap64(submissionDuration.subCap64(renewalPeriodDuration));
        require(block.timestamp < renewalAvailableAt, "Can't remove after renewal");
        submission.status = Status.PendingRemoval;


        submission.requests.push();
	    uint256 _newIndex = submission.requests.length - 1;
        submission.requests[_newIndex].requester = payable(msg.sender);
        submission.requests[_newIndex].challengePeriodStart = uint64(block.timestamp);
        uint arbitratorDataID = arbitratorDataList.length - 1;
        submission.requests[_newIndex].arbitratorDataID = uint16(arbitratorDataID);

        Round storage round = submission.requests[_newIndex].challenges[0].rounds[0];

        IArbitrator requestArbitrator = arbitratorDataList[arbitratorDataID].arbitrator;
        uint arbitrationCost = requestArbitrator.arbitrationCost(arbitratorDataList[arbitratorDataID].arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap(submissionBaseDeposit);
        contribute(round, Party.Requester, payable(msg.sender), msg.value, totalCost);

        require(round.paidFees[uint(Party.Requester)] >= totalCost, "You must fully fund your side");
        round.sideFunded = Party.Requester;

        emit RemoveSubmission(msg.sender, _submissionID, submission.requests.length - 1);

        if (bytes(_evidence).length > 0)
            emit Evidence(requestArbitrator, submission.requests.length - 1 + f(_submissionID), payable(msg.sender), _evidence);
    }

    /** @dev Fund the requester's deposit. Accepts enough ETH to cover the deposit, reimburses the rest.
     *  @param _submissionID The address of the submission which ongoing request to fund.
     */
    function fundSubmission(address _submissionID) external payable {
        Submission storage submission = submissions[_submissionID];
        require(submission.status == Status.Vouching, "Wrong status");
        Request storage request = submission.requests[submission.requests.length - 1];
        Challenge storage challenge = request.challenges[0];
        Round storage round = challenge.rounds[0];

        ArbitratorData storage arbitratorData = arbitratorDataList[request.arbitratorDataID];
        uint arbitrationCost = arbitratorData.arbitrator.arbitrationCost(arbitratorData.arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap(submissionBaseDeposit);
        contribute(round, Party.Requester, payable(msg.sender), msg.value, totalCost);

        if (round.paidFees[uint(Party.Requester)] >= totalCost)
            round.sideFunded = Party.Requester;
    }

    /** @dev Vouch for the submission. Note that the event spam is not an issue as it will be handled by the UI.
     *  @param _submissionID The address of the submission to vouch for.
     */
    function addVouch(address _submissionID) external {
        vouches[msg.sender][_submissionID] = true;
        emit VouchAdded(_submissionID, msg.sender);
    }

    /** @dev Remove the submission's vouch that has been added earlier. Note that the event spam is not an issue as it will be handled by the UI.
     *  @param _submissionID The address of the submission to remove vouch from.
     */
    function removeVouch(address _submissionID) external {
        vouches[msg.sender][_submissionID] = false;
        emit VouchRemoved(_submissionID, msg.sender);
    }

    /** @dev Allow to withdraw a mistakenly added submission while it's still in a vouching state.
     */
    function withdrawSubmission() external {
        Submission storage submission = submissions[msg.sender];
        require(submission.status == Status.Vouching, "Wrong status");
        Request storage request = submission.requests[submission.requests.length - 1];

        submission.status = Status.None;
        request.resolved = true;

        withdrawFeesAndRewards(payable(msg.sender), msg.sender, submission.requests.length - 1, 0, 0); // Automatically withdraw for the requester.
    }

    /** @dev Change submission's state from Vouching to PendingRegistration if all conditions are met.
     *  @param _submissionID The address of the submission which status to change.
     *  @param _vouches Array of users whose vouches to count.
     *  @param _signatures Array of EIP-712 signatures of struct IsHumanVoucher (optional).
     *  @param _expirationTimestamps Array of expiration timestamps for each signature (optional).
     *  struct IsHumanVoucher {
     *      address vouchedSubmission;
     *      uint256 voucherExpirationTimestamp;
     *  }
     */
    function changeStateToPending(address _submissionID, address[] calldata _vouches, bytes[] calldata _signatures, uint[] calldata _expirationTimestamps) external {
        Submission storage submission = submissions[_submissionID];
        require(submission.status == Status.Vouching, "Wrong status");
        Request storage request = submission.requests[submission.requests.length - 1];
        /* solium-disable indentation */
        {
            Challenge storage challenge = request.challenges[0];
            Round storage round = challenge.rounds[0];
            require(round.sideFunded == Party.Requester, "Requester is not funded");
        }
        /* solium-enable indentation */
        uint timeOffset = block.timestamp - submissionDuration; // Precompute the offset before the loop for efficiency and then compare it with the submission time to check the expiration.

        bytes2 PREFIX = "\x19\x01";
        for (uint i = 0; i < _signatures.length && request.vouches.length < requiredNumberOfVouches; i++) {
            address voucherAddress;
            /* solium-disable indentation */
            {
                // Get typed structure hash.
                bytes32 messageHash = keccak256(abi.encode(IS_HUMAN_VOUCHER_TYPEHASH, _submissionID, _expirationTimestamps[i]));
                bytes32 hash = keccak256(abi.encodePacked(PREFIX, DOMAIN_SEPARATOR, messageHash));

                // Decode the signature.
                bytes memory signature = _signatures[i];
                bytes32 r;
                bytes32 s;
                uint8 v;
                assembly {
                    r := mload(add(signature, 0x20))
                    s := mload(add(signature, 0x40))
                    v := byte(0, mload(add(signature, 0x60)))
                }
                if (v < 27) v += 27;
                require(v == 27 || v == 28, "Invalid signature");

                // Recover the signer's address.
                voucherAddress = ecrecover(hash, v, r, s);
            }
            /* solium-enable indentation */

            Submission storage voucher = submissions[voucherAddress];
            if (!voucher.hasVouched && voucher.registered && timeOffset <= voucher.submissionTime &&
            block.timestamp < _expirationTimestamps[i] && _submissionID != voucherAddress) {
                request.vouches.push(voucherAddress);
                voucher.hasVouched = true;
                emit VouchAdded(_submissionID, voucherAddress);
            }
        }

        for (uint i = 0; i<_vouches.length && request.vouches.length<requiredNumberOfVouches; i++) {
            // Check that the vouch isn't currently used by another submission and the voucher has a right to vouch.
            Submission storage voucher = submissions[_vouches[i]];
            if (!voucher.hasVouched && voucher.registered && timeOffset <= voucher.submissionTime &&
            vouches[_vouches[i]][_submissionID] && _submissionID != _vouches[i]) {
                request.vouches.push(_vouches[i]);
                voucher.hasVouched = true;
            }
        }
        require(request.vouches.length >= requiredNumberOfVouches, "Not enough valid vouches");
        submission.status = Status.PendingRegistration;
        request.challengePeriodStart = uint64(block.timestamp);
    }

    /** @dev Challenge the submission's request. Accept enough ETH to cover the deposit, reimburse the rest.
     *  @param _submissionID The address of the submission which request to challenge.
     *  @param _reason The reason to challenge the request. Left empty for removal requests.
     *  @param _duplicateID The address of a supposed duplicate submission. Ignored if the reason is not Duplicate.
     *  @param _evidence A link to evidence using its URI. Ignored if not provided.
     */
    function challengeRequest(address _submissionID, Reason _reason, address _duplicateID, string calldata _evidence) external payable {
        Submission storage submission = submissions[_submissionID];
        if (submission.status == Status.PendingRegistration)
            require(_reason != Reason.None, "Reason must be specified");
        else if (submission.status == Status.PendingRemoval)
            require(_reason == Reason.None, "Reason must be left empty");
        else
            revert("Wrong status");

        Request storage request = submission.requests[submission.requests.length - 1];
        require(block.timestamp - request.challengePeriodStart <= challengePeriodDuration, "Time to challenge has passed");

        Challenge storage challenge = request.challenges[request.lastChallengeID];
        /* solium-disable indentation */
        {
            Reason currentReason = request.currentReason;
            if (_reason == Reason.Duplicate) {
                require(submissions[_duplicateID].status > Status.None || submissions[_duplicateID].registered, "Wrong duplicate status");
                require(_submissionID != _duplicateID, "Can't be a duplicate of itself");
                require(currentReason == Reason.Duplicate || currentReason == Reason.None, "Another reason is active");
                require(!request.challengeDuplicates[_duplicateID], "Duplicate address already used");
                request.challengeDuplicates[_duplicateID] = true;
                challenge.duplicateSubmissionIndex = submissions[_duplicateID].index;
            } else
                require(!request.disputed, "The request is disputed");

            if (currentReason != _reason) {
                uint8 reasonBit = uint8(1 << (uint8(_reason) - 1)); // Get the bit that corresponds with reason's index.
                require((reasonBit & ~request.usedReasons) == reasonBit, "The reason has already been used");

                request.usedReasons ^= reasonBit; // Mark the bit corresponding with reason's index as 'true', to indicate that the reason was used.
                request.currentReason = _reason;
            }
        }
        /* solium-enable indentation */

        Round storage round = challenge.rounds[0];
        ArbitratorData storage arbitratorData = arbitratorDataList[request.arbitratorDataID];

        uint arbitrationCost = arbitratorData.arbitrator.arbitrationCost(arbitratorData.arbitratorExtraData);
        contribute(round, Party.Challenger, payable(msg.sender), msg.value, arbitrationCost);
        require(round.paidFees[uint(Party.Challenger)] >= arbitrationCost, "You must fully fund your side");
        round.feeRewards = round.feeRewards.subCap(arbitrationCost);
        round.sideFunded = Party.None; // Set this back to 0, since it's no longer relevant as the new round is created.

        challenge.disputeID = arbitratorData.arbitrator.createDispute{value:arbitrationCost}(RULING_OPTIONS, arbitratorData.arbitratorExtraData);
        challenge.challenger = payable(msg.sender);

        DisputeData storage disputeData = arbitratorDisputeIDToDisputeData[address(arbitratorData.arbitrator)][challenge.disputeID];
        disputeData.challengeID = uint96(request.lastChallengeID);
        disputeData.submissionID = _submissionID;

        request.disputed = true;
        request.nbParallelDisputes++;

        challenge.lastRoundID++;
        emit SubmissionChallenged(_submissionID, submission.requests.length - 1, disputeData.challengeID);

        request.lastChallengeID++;

        emit Dispute(
            arbitratorData.arbitrator,
            challenge.disputeID,
            submission.status == Status.PendingRegistration ? 2 * arbitratorData.metaEvidenceUpdates : 2 * arbitratorData.metaEvidenceUpdates + 1,
            submission.requests.length - 1 + uint256(uint160(address(_submissionID)))
        );

        if (bytes(_evidence).length > 0)
            emit Evidence(arbitratorData.arbitrator, submission.requests.length - 1 + f(_submissionID), msg.sender, _evidence);
    }

    /** @dev Take up to the total amount required to fund a side of an appeal. Reimburse the rest. Create an appeal if both sides are fully funded.
     *  @param _submissionID The address of the submission which request to fund.
     *  @param _challengeID The index of a dispute, created for the request.
     *  @param _side The recipient of the contribution.
     */
    function fundAppeal(address _submissionID, uint _challengeID, Party _side) external payable {
        require(_side != Party.None); // You can only fund either requester or challenger.
        Submission storage submission = submissions[_submissionID];
        require(submission.status == Status.PendingRegistration || submission.status == Status.PendingRemoval, "Wrong status");
        Request storage request = submission.requests[submission.requests.length - 1];
        require(request.disputed, "No dispute to appeal");
        require(_challengeID < request.lastChallengeID, "Challenge out of bounds");

        Challenge storage challenge = request.challenges[_challengeID];
        ArbitratorData storage arbitratorData = arbitratorDataList[request.arbitratorDataID];

        (uint appealPeriodStart, uint appealPeriodEnd) = arbitratorData.arbitrator.appealPeriod(challenge.disputeID);
        require(block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, "Appeal period is over");

        uint multiplier;
        /* solium-disable indentation */
        {
            Party winner = Party(arbitratorData.arbitrator.currentRuling(challenge.disputeID));
            if (winner == _side){
                multiplier = winnerStakeMultiplier;
            } else if (winner == Party.None){
                multiplier = sharedStakeMultiplier;
            } else {
                multiplier = loserStakeMultiplier;
                require(block.timestamp-appealPeriodStart < (appealPeriodEnd-appealPeriodStart)/2, "Appeal period is over for loser");
            }
        }
        /* solium-enable indentation */

        Round storage round = challenge.rounds[challenge.lastRoundID];
        require(_side != round.sideFunded, "Side is already funded");

        uint appealCost = arbitratorData.arbitrator.appealCost(challenge.disputeID, arbitratorData.arbitratorExtraData);
        uint totalCost = appealCost.addCap((appealCost.mulCap(multiplier)) / MULTIPLIER_DIVISOR);
        uint contribution = contribute(round, _side, payable(msg.sender), msg.value, totalCost);
        emit AppealContribution(_submissionID, _challengeID, _side, payable(msg.sender), contribution);

        if (round.paidFees[uint(_side)] >= totalCost) {
            if (round.sideFunded == Party.None) {
                round.sideFunded = _side;
            } else {
                // Both sides are fully funded. Create an appeal.
                arbitratorData.arbitrator.appeal{value:appealCost}(challenge.disputeID, arbitratorData.arbitratorExtraData);
                challenge.lastRoundID++;
                round.feeRewards = round.feeRewards.subCap(appealCost);
                round.sideFunded = Party.None; // Set this back to default in the past round as it's no longer relevant.
            }
            emit HasPaidAppealFee(_submissionID, _challengeID, _side);
        }
    }

    /** @dev Execute a request if the challenge period passed and no one challenged the request.
     *  @param _submissionID The address of the submission with the request to execute.
     */
    function executeRequest(address _submissionID) external {
        Submission storage submission = submissions[_submissionID];
        uint requestID = submission.requests.length - 1;
        Request storage request = submission.requests[requestID];
        require(block.timestamp - request.challengePeriodStart > challengePeriodDuration, "Can't execute yet");
        require(!request.disputed, "The request is disputed");
        address payable requester;
        if (submission.status == Status.PendingRegistration) {
            // It is possible for the requester to lose without a dispute if he was penalized for bad vouching while reapplying.
            if (!request.requesterLost) {
                submission.registered = true;
                submission.submissionTime = uint64(block.timestamp);
            }
            requester = payable(address(uint160(_submissionID)));
        } else if (submission.status == Status.PendingRemoval) {
            submission.registered = false;
            requester = request.requester;
        } else
            revert("Incorrect status.");

        submission.status = Status.None;
        request.resolved = true;

        if (request.vouches.length != 0)
            processVouches(_submissionID, requestID, AUTO_PROCESSED_VOUCH);

        withdrawFeesAndRewards(requester, _submissionID, requestID, 0, 0); // Automatically withdraw for the requester.
    }

    /** @dev Process vouches of the resolved request, so vouchings of users who vouched for it can be used in other submissions.
     *  Penalize users who vouched for bad submissions.
     *  @param _submissionID The address of the submission which vouches to iterate.
     *  @param _requestID The ID of the request which vouches to iterate.
     *  @param _iterations The number of iterations to go through.
     */
    function processVouches(address _submissionID, uint _requestID, uint _iterations) public {
        Submission storage submission = submissions[_submissionID];
        Request storage request = submission.requests[_requestID];
        require(request.resolved, "Submission must be resolved");

        uint lastProcessedVouch = request.lastProcessedVouch;
        uint endIndex = _iterations.addCap(lastProcessedVouch);
        uint vouchCount = request.vouches.length;

        if (endIndex > vouchCount)
            endIndex = vouchCount;

        Reason currentReason = request.currentReason;
        // If the ultimate challenger is defined that means that the request was ruled in favor of the challenger.
        bool applyPenalty = request.ultimateChallenger != address(0x0) && (currentReason == Reason.Duplicate || currentReason == Reason.DoesNotExist);
        for (uint i = lastProcessedVouch; i < endIndex; i++) {
            Submission storage voucher = submissions[request.vouches[i]];
            voucher.hasVouched = false;
            if (applyPenalty) {
                // Check the situation when vouching address is in the middle of reapplication process.
                if (voucher.status == Status.Vouching || voucher.status == Status.PendingRegistration)
                    voucher.requests[voucher.requests.length - 1].requesterLost = true;

                voucher.registered = false;
            }
        }
        request.lastProcessedVouch = uint32(endIndex);
    }

    /** @dev Reimburse contributions if no disputes were raised. If a dispute was raised, transfer the fee stake rewards and reimbursements proportionally to the contributions made to the winner of a dispute.
     *  @param _beneficiary The address that made contributions to a request.
     *  @param _submissionID The address of the submission with the request from which to withdraw.
     *  @param _requestID The request from which to withdraw.
     *  @param _challengeID The ID of the challenge from which to withdraw.
     *  @param _round The round from which to withdraw.
     */
    function withdrawFeesAndRewards(address payable _beneficiary, address _submissionID, uint _requestID, uint _challengeID, uint _round) public {
        Submission storage submission = submissions[_submissionID];
        Request storage request = submission.requests[_requestID];
        Challenge storage challenge = request.challenges[_challengeID];
        Round storage round = challenge.rounds[_round];
        require(request.resolved, "Submission must be resolved");
        require(_beneficiary != address(0x0), "Beneficiary must not be empty");

        Party ruling = challenge.ruling;
        uint reward;
        // Reimburse the payment if the last round wasn't fully funded.
        // Note that the 0 round is always considered funded if there is a challenge. If there was no challenge the requester will be reimbursed with the subsequent condition, since the ruling will be Party.None.
        if (_round != 0 && _round == challenge.lastRoundID) {
            reward = round.contributions[_beneficiary][uint(Party.Requester)] + round.contributions[_beneficiary][uint(Party.Challenger)];
        } else if (ruling == Party.None) {
            uint totalFeesInRound = round.paidFees[uint(Party.Challenger)] + round.paidFees[uint(Party.Requester)];
            uint claimableFees = round.contributions[_beneficiary][uint(Party.Challenger)] + round.contributions[_beneficiary][uint(Party.Requester)];
            reward = totalFeesInRound > 0 ? claimableFees * round.feeRewards / totalFeesInRound : 0;
        } else {
            // Challenger, who ultimately wins, will be able to get the deposit of the requester, even if he didn't participate in the initial dispute.
            if (_round == 0 && _beneficiary == request.ultimateChallenger && _challengeID == 0) {
                reward = round.feeRewards;
                round.feeRewards = 0;
            // This condition will prevent claiming a reward, intended for the ultimate challenger.
            } else if (request.ultimateChallenger==address(0x0) || _challengeID!=0 || _round!=0) {
                uint paidFees = round.paidFees[uint(ruling)];
                reward = paidFees > 0
                    ? (round.contributions[_beneficiary][uint(ruling)] * round.feeRewards) / paidFees
                    : 0;
            }
        }
        round.contributions[_beneficiary][uint(Party.Requester)] = 0;
        round.contributions[_beneficiary][uint(Party.Challenger)] = 0;
        _beneficiary.transfer(reward);
    }

    /** @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     *  Account for the situation where the winner loses a case due to paying less appeal fees than expected.
     *  @param _disputeID ID of the dispute in the arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function rule(uint _disputeID, uint _ruling) public override{
        Party resultRuling = Party(_ruling);
        DisputeData storage disputeData = arbitratorDisputeIDToDisputeData[msg.sender][_disputeID];
        address submissionID = disputeData.submissionID;
        uint challengeID = disputeData.challengeID;
        Submission storage submission = submissions[submissionID];

        Request storage request = submission.requests[submission.requests.length - 1];
        Challenge storage challenge = request.challenges[challengeID];
        Round storage round = challenge.rounds[challenge.lastRoundID];
        ArbitratorData storage arbitratorData = arbitratorDataList[request.arbitratorDataID];

        require(address(arbitratorData.arbitrator) == msg.sender);
        require(!request.resolved);

        // The ruling is inverted if the loser paid its fees.
        if (round.sideFunded == Party.Requester) // If one side paid its fees, the ruling is in its favor. Note that if the other side had also paid, an appeal would have been created.
            resultRuling = Party.Requester;
        else if (round.sideFunded == Party.Challenger)
            resultRuling = Party.Challenger;

        emit Ruling(IArbitrator(msg.sender), _disputeID, uint(resultRuling));
        executeRuling(submissionID, challengeID, resultRuling);
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _submissionID The address of the submission which the evidence is related to.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(address _submissionID, string calldata _evidence) external {
        Submission storage submission = submissions[_submissionID];
        Request storage request = submission.requests[submission.requests.length - 1];
        ArbitratorData storage arbitratorData = arbitratorDataList[request.arbitratorDataID];

        emit Evidence(arbitratorData.arbitrator, submission.requests.length - 1 + f(_submissionID), msg.sender, _evidence);
    }

    /* Internal */

    /** @dev Make a request to register/reapply the submission. Paying the full deposit right away is not required as it can be crowdfunded later.
     *  @param _submissionID The address of the submission.
     *  @param _evidence A link to evidence using its URI.
     */
    function requestRegistration(address _submissionID, string memory _evidence) internal {
        Submission storage submission = submissions[_submissionID];
        submission.requests.push();
	    uint256 _newIndex = submission.requests.length - 1;
        uint arbitratorDataID = arbitratorDataList.length - 1;
        submission.requests[_newIndex].arbitratorDataID = uint16(arbitratorDataID);

        Round storage round = submission.requests[_newIndex].challenges[0].rounds[0];


        IArbitrator requestArbitrator = arbitratorDataList[arbitratorDataID].arbitrator;
        uint arbitrationCost = requestArbitrator.arbitrationCost(arbitratorDataList[arbitratorDataID].arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap(submissionBaseDeposit);
        contribute(round, Party.Requester, payable(msg.sender), msg.value, totalCost);

        if (round.paidFees[uint(Party.Requester)] >= totalCost)
            round.sideFunded = Party.Requester;

        if (bytes(_evidence).length > 0)
            emit Evidence(requestArbitrator, submission.requests.length - 1 + f(_submissionID), msg.sender, _evidence);
    }

    /** @dev Return the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return taken The amount of ETH taken.
     *  @return remainder The amount of ETH left from the contribution.
     */
    function calculateContribution(uint _available, uint _requiredAmount)
        internal
        pure
        returns(uint taken, uint remainder)
    {
        if (_requiredAmount > _available)
            return (_available, 0);

        remainder = _available - _requiredAmount;
        return (_requiredAmount, remainder);
    }

    /** @dev Make a fee contribution.
     *  @param _round The round to contribute to.
     *  @param _side The side to contribute to.
     *  @param _contributor The contributor.
     *  @param _amount The amount contributed.
     *  @param _totalRequired The total amount required for this side.
     *  @return The amount of fees contributed.
     */
    function contribute(Round storage _round, Party _side, address payable _contributor, uint _amount, uint _totalRequired) internal returns (uint) {
        uint contribution;
        uint remainingETH;
        (contribution, remainingETH) = calculateContribution(_amount, _totalRequired.subCap(_round.paidFees[uint(_side)]));
        _round.contributions[_contributor][uint(_side)] += contribution;
        _round.paidFees[uint(_side)] += contribution;
        _round.feeRewards += contribution;

        if (remainingETH != 0)
            _contributor.transfer(remainingETH);

        return contribution;
    }

    /** @dev Execute the ruling of a dispute.
     *  @param _submissionID ID of the submission.
     *  @param _challengeID ID of the challenge, related to the dispute.
     *  @param _winner Ruling given by the arbitrator. Note that 0 is reserved for "Refused to arbitrate".
     */
    function executeRuling(address _submissionID, uint _challengeID, Party _winner) internal {
        Submission storage submission = submissions[_submissionID];
        uint requestID = submission.requests.length - 1;
        Status status = submission.status;

        Request storage request = submission.requests[requestID];
        uint nbParallelDisputes = request.nbParallelDisputes;

        Challenge storage challenge = request.challenges[_challengeID];

        if (status == Status.PendingRemoval) {
            if (_winner == Party.Requester)
                submission.registered = false;

            submission.status = Status.None;
            request.resolved = true;
        } else if (status == Status.PendingRegistration) {
            // For a registration request there can be more than one dispute.
            if (_winner == Party.Requester) {
                if (nbParallelDisputes == 1) {
                    // Check whether or not the requester won all of his previous disputes for current reason.
                    if (!request.requesterLost) {
                        if (request.usedReasons == FULL_REASONS_SET) {
                            // All reasons being used means the request can't be challenged again, so we can update its status.
                            submission.status = Status.None;
                            submission.registered = true;
                            submission.submissionTime = uint64(block.timestamp);
                            request.resolved = true;
                        } else {
                            // Refresh the state of the request so it can be challenged again.
                            request.disputed = false;
                            request.challengePeriodStart = uint64(block.timestamp);
                            request.currentReason = Reason.None;
                        }
                    } else {
                        submission.status = Status.None;
                        request.resolved = true;
                    }
                }
            // Challenger won or it’s a tie.
            } else {
                request.requesterLost = true;
                // Update the status of the submission if there is no more disputes left.
                if (nbParallelDisputes == 1) {
                    submission.status = Status.None;
                    request.resolved = true;
                }
                // Store the challenger that made the requester lose. Update the challenger if there is a duplicate with lower submission time, which is indicated by submission's index.
                if (_winner==Party.Challenger && (request.ultimateChallenger==address(0x0) || challenge.duplicateSubmissionIndex<request.currentDuplicateIndex)) {
                    request.ultimateChallenger = challenge.challenger;
                    request.currentDuplicateIndex = challenge.duplicateSubmissionIndex;
                }
            }
        }
        // Decrease the number of parallel disputes each time the dispute is resolved. Store the rulings of each dispute for correct distribution of rewards.
        request.nbParallelDisputes--;
        challenge.ruling = _winner;
        emit ChallengeResolved(_submissionID, requestID, _challengeID);
    }

    // ************************ //
    // *       Getters        * //
    // ************************ //

    /** @dev Return true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool) {
        Submission storage submission = submissions[_submissionID];
        return submission.registered && block.timestamp - submission.submissionTime <= submissionDuration;
    }

    /** @dev Get the number of times the arbitrator data was updated.
     *  @return The number of arbitrator data updates.
     */
    function getArbitratorDataListCount() external view returns (uint) {
        return arbitratorDataList.length;
    }

    /** @dev Check whether the duplicate address has been used in challenging the request or not.
     *  @param _submissionID The address of the submission to check.
     *  @param _requestID The request to check.
     *  @param _duplicateID The duplicate to check.
     *  @return Whether the duplicate has been used.
     */
    function checkRequestDuplicates(address _submissionID, uint _requestID, address _duplicateID) external view returns (bool) {
        Request storage request = submissions[_submissionID].requests[_requestID];
        return request.challengeDuplicates[_duplicateID];
    }

    /** @dev Get the contributions made by a party for a given round of a given challenge of a request.
     *  @param _submissionID The address of the submission.
     *  @param _requestID The request to query.
     *  @param _challengeID the challenge to query.
     *  @param _round The round to query.
     *  @param _contributor The address of the contributor.
     */
    function getContributions(
        address _submissionID,
        uint _requestID,
        uint _challengeID,
        uint _round,
        address _contributor
    ) external view returns(uint[3] memory contributions) {
        Request storage request = submissions[_submissionID].requests[_requestID];
        Challenge storage challenge = request.challenges[_challengeID];
        Round storage round = challenge.rounds[_round];
        contributions = round.contributions[_contributor];
    }

    /** @dev Return the information of the submission. Includes length of requests array.
     *  @param _submissionID The address of the queried submission.
     */
    function getSubmissionInfo(address _submissionID)
        external
        view
        returns (
            Status status,
            uint64 submissionTime,
            uint64 index,
            bool registered,
            bool hasVouched,
            uint numberOfRequests
        )
    {
        Submission storage submission = submissions[_submissionID];
        return (
            submission.status,
            submission.submissionTime,
            submission.index,
            submission.registered,
            submission.hasVouched,
            submission.requests.length
        );
    }

    /** @dev Get the information of a particular challenge of the request.
     *  @param _submissionID The address of the queried submission.
     *  @param _requestID The request to query.
     *  @param _challengeID The challenge to query.
     */
    function getChallengeInfo(address _submissionID, uint _requestID, uint _challengeID)
        external
        view
        returns (
            uint16 lastRoundID,
            address challenger,
            uint disputeID,
            Party ruling,
            uint64 duplicateSubmissionIndex
        )
    {
        Request storage request = submissions[_submissionID].requests[_requestID];
        Challenge storage challenge = request.challenges[_challengeID];
        return (
            challenge.lastRoundID,
            challenge.challenger,
            challenge.disputeID,
            challenge.ruling,
            challenge.duplicateSubmissionIndex
        );
    }

    /** @dev Get information of a request of a submission.
     *  @param _submissionID The address of the queried submission.
     *  @param _requestID The request to be queried.
     */
    function getRequestInfo(address _submissionID, uint _requestID)
        external
        view
        returns (
            bool disputed,
            bool resolved,
            bool requesterLost,
            Reason currentReason,
            uint16 nbParallelDisputes,
            uint16 lastChallengeID,
            uint16 arbitratorDataID,
            address payable requester,
            address payable ultimateChallenger,
            uint8 usedReasons
        )
    {
        Request storage request = submissions[_submissionID].requests[_requestID];
        return (
            request.disputed,
            request.resolved,
            request.requesterLost,
            request.currentReason,
            request.nbParallelDisputes,
            request.lastChallengeID,
            request.arbitratorDataID,
            request.requester,
            request.ultimateChallenger,
            request.usedReasons
        );
    }

    /** @dev Get the number of vouches of a particular request.
     *  @param _submissionID The address of the queried submission.
     *  @param _requestID The request to query.
     *  @return The current number of vouches.
     */
    function getNumberOfVouches(address _submissionID, uint _requestID) external view returns (uint) {
        Request storage request = submissions[_submissionID].requests[_requestID];
        return request.vouches.length;
    }

    /** @dev Get the information of a round of a request.
     *  @param _submissionID The address of the queried submission.
     *  @param _requestID The request to query.
     *  @param _challengeID The challenge to query.
     *  @param _round The round to query.
     */
    function getRoundInfo(address _submissionID, uint _requestID, uint _challengeID, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            Party sideFunded,
            uint feeRewards
        )
    {
        Request storage request = submissions[_submissionID].requests[_requestID];
        Challenge storage challenge = request.challenges[_challengeID];
        Round storage round = challenge.rounds[_round];
        appealed = _round < (challenge.lastRoundID);
        return (
            appealed,
            round.paidFees,
            round.sideFunded,
            round.feeRewards
        );
    }

    function f(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/** 
    Nicheman — has superpower
    SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.6;

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
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.6;

import "./IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
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

/** 
    Nicheman — has superpower
    SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.6;

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
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;
    uint64 constant private UINT64_MAX = 2**64 - 1;

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

    function addCap64(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        return c >= _a ? c : UINT64_MAX;
    }


    function subCap64(uint64 _a, uint64 _b) internal pure returns (uint64) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

    function mulCap64(uint64 _a, uint64 _b) internal pure returns (uint64) {
        if (_a == 0)
            return 0;

        uint64 c = _a * _b;
        return c / _a == _b ? c : UINT64_MAX;
    }
}
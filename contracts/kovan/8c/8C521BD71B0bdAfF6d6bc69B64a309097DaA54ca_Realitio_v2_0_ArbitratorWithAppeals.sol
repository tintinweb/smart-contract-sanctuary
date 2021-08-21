// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@hbarcelos]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.6;

/**
 *  @title IRealitio
 *  @dev Required subset of https://github.com/realitio/realitio-contracts/blob/master/truffle/contracts/IRealitio.sol to implement a Realitio arbitrator.
 */
interface IRealitio {
    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external;

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond. Required only in v2.0.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question.
    /// @param answer The answer, encoded into bytes32.
    /// @param answerer The account credited with this answer for the purpose of bond claims.
    function submitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address answerer
    ) external;

    /// @notice Returns the history hash of the question. Required before calling submitAnswerByArbitrator to make sure history is correct.
    /// @dev Required only in v2.0.
    /// @param question_id The ID of the question.
    /// @dev Updated on each answer, then rewound as each is claimed.
    function getHistoryHash(bytes32 question_id) external view returns (bytes32);

    /// @notice Returns the commitment info by its id. Required before calling submitAnswerByArbitrator to make sure history is correct.
    /// @dev Required only in v2.0.
    /// @param commitment_id The ID of the commitment.
    /// @return Time after which the committed answer can be revealed.
    /// @return Whether the commitment has already been revealed or not.
    /// @return The committed answer, encoded as bytes32.
    function commitments(bytes32 commitment_id)
        external
        view
        returns (
            uint32,
            bool,
            bytes32
        );

    /// @notice Submit the answer for a question, for use by the arbitrator, working out the appropriate winner based on the last answer details.
    /// @dev Doesn't require (or allow) a bond. Required only in v2.1.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param payee_if_wrong The account to by credited as winner if the last answer given is wrong, usually the account that paid the arbitrator
    /// @param last_history_hash The history hash before the final one
    /// @param last_answer_or_commitment_id The last answer given, or the commitment ID if it was a commitment.
    /// @param last_answerer The address that supplied the last answer
    function assignWinnerAndSubmitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address payee_if_wrong,
        bytes32 last_history_hash,
        bytes32 last_answer_or_commitment_id,
        address last_answerer
    ) external;
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@hbarcelos]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.6;
import "./IRealitio.sol";

/**
 *  @title IRealitioArbitrator
 *  @dev Based on https://github.com/realitio/realitio-dapp/blob/1860548a51f52eba4930baad051f811e9f7adaee/docs/arbitrators.rst
 */
interface IRealitioArbitrator {
    /** @dev Returns Realitio implementation instance.
     */
    function realitio() external view returns (IRealitio);

    /** @dev Provides a string of json-encoded metadata. The following properties are scheduled for implementation in the Reality.eth dapp:
        tos: A URI representing the location of a terms-of-service document for the arbitrator.
        template_hashes: An array of hashes of templates supported by the arbitrator. If you have a numerical ID for a template registered with Reality.eth, you can look up this hash by calling the Reality.eth template_hashes() function.
     */
    function metadata() external view returns (string calldata);

    /** @dev Returns arbitrators fee for arbitrating this question.
     */
    function getDisputeFee(bytes32 questionID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@unknownunknown1*, @hbarcelos, @MerlinEgalite, @shalzz, @fnanni-0, @clesaege, @jaybuidl]
 *  @auditors: []
 *  @bounties: []
 */

pragma solidity ^0.7.0;

import "./IRealitio.sol";
import "./IRealitioArbitrator.sol";
import "@kleros/dispute-resolver-interface-contract/contracts/solc-0.7.x/IDisputeResolver.sol";
import "@kleros/ethereum-libraries/contracts/CappedMath.sol";

/**
 *  @title RealitioArbitratorWithAppealsBase
 *  @dev A Realitio arbitrator base implementation that uses Realitio v2.x and Kleros. It notifies Realitio contract for arbitration requests and creates corresponding dispute on Kleros. Transmits Kleros ruling to Realitio contract. Maintains crowdfunded appeals and notifies Kleros contract. Provides a function to submit evidence for Kleros dispute. This contract is abstract as it does not have a function to report answer, see child contracts.
 *  There is a conversion between Kleros ruling and Realitio answer and there is a need for shifting by 1. This is because ruling 0 in Kleros signals tie or no-ruling but in Realitio 0 is a valid answer. For reviewers this should be a focus as it's quite easy to get confused. Any mistakes on this conversion will render this contract useless.
 *  NOTE: This contract trusts the Kleros arbitrator and Realitio.
 */
abstract contract RealitioArbitratorWithAppealsBase is IDisputeResolver, IRealitioArbitrator {
    using CappedMath for uint256; // Overflows and underflows are prevented by returning uint256 max and min values in case of overflows and underflows, respectively.

    IRealitio public immutable override realitio; // Actual implementation of Realitio.
    IArbitrator public immutable arbitrator; // The Kleros arbitrator.
    bytes public arbitratorExtraData; // Required for Kleros arbitrator. First 64 bytes contain subcourtID and the second 64 bytes contain number of votes in the jury.
    string public override metadata; // Metadata for Realitio. See IRealitioArbitrator.

    // The required fee stake that a party must deposit, which depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is `multiplier * arbitration_cost` for that round.
    uint256 public constant WINNER_STAKE_MULTIPLIER = 3000; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points.
    uint256 public constant LOSER_STAKE_MULTIPLIER = 7000; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points.
    uint256 public constant LOSER_APPEAL_PERIOD_MULTIPLIER = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
    uint256 public constant MULTIPLIER_DENOMINATOR = 10000; // Denominator for multipliers.
    uint256 private constant NUMBER_OF_RULING_OPTIONS = type(uint256).max - 1; // The amount of non 0 choices the arbitrator can give. The uint256(-1) number of choices can not be used in the current Kleros Court implementation.

    enum Status {
        None, // The question hasn't been requested arbitration yet.
        Disputed, // The question has been requested arbitration.
        Ruled, // The question has been ruled by arbitrator.
        Reported // The answer of the question has been reported to Realitio.
    }

    // To track internal dispute state in this contract.
    struct ArbitrationRequest {
        Status status; // The current status of the question.
        address requester; // The address that requested the arbitration.
        uint256 disputeID; // The ID of the dispute raised in the arbitrator contract.
        uint256 ruling; // The ruling given by the arbitrator.
        Round[] rounds; // Tracks each appeal round of a dispute.
    }

    // For appeal logic.
    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid in this round in the form paidFees[answer].
        mapping(uint256 => bool) hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[answer].
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each answer in the form contributions[address][answer].
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the answer that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the answer choices that are fully funded.
    }

    mapping(uint256 => ArbitrationRequest) public arbitrationRequests; // Maps a question identifier in uint to its arbitration details. Example: arbitrationRequests[uint(questionID)]
    mapping(uint256 => uint256) public override externalIDtoLocalID; // Map arbitrator dispute identifiers to local identifiers. We use question ids casted to uint as local identifier.

    /** @dev Emitted when arbitration is requested, to link dispute identifier to question identifier for dynamic script that is used in metaevidence. See https://github.com/kleros/realitio-script/blob/master/src/index.js
     *  @param _disputeID The ID of the dispute in the ERC792 arbitrator.
     *  @param _questionID The ID of the question.
     */
    event DisputeIDToQuestionID(uint256 indexed _disputeID, bytes32 _questionID);

    /** @dev Constructor.
     *  @param _realitio The address of the Realitio contract.
     *  @param _metadata The metadata required for RealitioArbitrator.
     *  @param _arbitrator The address of the ERC792 arbitrator.
     *  @param _arbitratorExtraData The extra data used to raise a dispute in the ERC792 arbitrator.
     *  @param _metaevidence Metaevidence as defined in ERC-1497.
     */
    constructor(
        IRealitio _realitio,
        string memory _metadata,
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaevidence
    ) {
        realitio = _realitio;
        metadata = _metadata;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        emit MetaEvidence(0, _metaevidence); // No setter for meta-evidence. To change it, deploy a new contract.
    }

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _questionID Realitio question identifier.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(uint256 _questionID, string calldata _evidenceURI) external override {
        emit Evidence(arbitrator, _questionID, msg.sender, _evidenceURI); // We use _questionID for evidence group identifier.
    }

    /** @dev Request arbitration from Kleros for given _questionID.
     *  @param _questionID The question identifier in Realitio contract.
     *  @param _maxPrevious If specified, reverts if a bond higher than this was submitted after you sent your transaction.
     *  @return disputeID ID of the resulting dispute on arbitrator.
     */
    function requestArbitration(bytes32 _questionID, uint256 _maxPrevious) external payable returns (uint256 disputeID) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[uint256(_questionID)];
        require(arbitrationRequest.status == Status.None, "Arbitration already requested");

        // Notify Kleros
        disputeID = arbitrator.createDispute{value: msg.value}(NUMBER_OF_RULING_OPTIONS, arbitratorExtraData); /* If msg.value is greater than intended number of votes (specified in arbitratorExtraData),
        Kleros will automatically spend excess for additional votes. */
        emit Dispute(arbitrator, disputeID, 0, uint256(_questionID)); // We use _questionID in uint as evidence group identifier.
        emit DisputeIDToQuestionID(disputeID, _questionID); // For the dynamic script https://github.com/kleros/realitio-script/blob/master/src/index.js
        externalIDtoLocalID[disputeID] = uint256(_questionID);

        // Update internal state
        arbitrationRequest.requester = msg.sender;
        arbitrationRequest.status = Status.Disputed;
        arbitrationRequest.disputeID = disputeID;
        arbitrationRequest.rounds.push();

        // Notify Realitio
        realitio.notifyOfArbitrationRequest(_questionID, msg.sender, _maxPrevious);
    }

    /** @dev Receives ruling from Kleros and enforces it.
     *  @param _disputeID ID of Kleros dispute.
     *  @param _ruling Ruling that is given by Kleros. This needs to be converted to Realitio answer before reporting the answer by shifting by 1.
     */
    function rule(uint256 _disputeID, uint256 _ruling) public override {
        require(IArbitrator(msg.sender) == arbitrator, "Only arbitrator allowed");
        require(_ruling <= NUMBER_OF_RULING_OPTIONS, "Invalid ruling");

        uint256 questionID = externalIDtoLocalID[_disputeID];
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[questionID];

        require(arbitrationRequest.status == Status.Disputed, "Invalid arbitration status");

        Round storage round = arbitrationRequest.rounds[arbitrationRequest.rounds.length - 1];

        // If there is only one ruling option in last round that is fully funded, no matter what Kleros ruling was this ruling option is the winner by default.
        uint256 finalRuling = (round.fundedRulings.length == 1) ? round.fundedRulings[0] : _ruling;

        arbitrationRequest.ruling = finalRuling;
        arbitrationRequest.status = Status.Ruled;

        emit Ruling(IArbitrator(msg.sender), _disputeID, finalRuling);

        // Ready to call `reportAnswer` now.
    }

    /** @dev TRUSTED. Manages crowdfunded appeals contributions and calls appeal function of the Kleros arbitrator to appeal a dispute.
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _ruling The ruling option to which the caller wants to contribute to.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _questionID, uint256 _ruling) external payable override returns (bool fullyFunded) {
        require(_ruling <= NUMBER_OF_RULING_OPTIONS, "Answer is out of bounds");
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        require(arbitrationRequest.status == Status.Disputed, "No dispute to appeal.");

        uint256 disputeID = arbitrationRequest.disputeID;
        uint256 currentRuling = arbitrator.currentRuling(disputeID);
        uint256 originalCost;
        uint256 totalCost;
        {
            (uint256 originalStart, uint256 originalEnd) = arbitrator.appealPeriod(disputeID);

            uint256 multiplier;

            if (_ruling == currentRuling) {
                require(block.timestamp < originalEnd, "Funding must be made within the appeal period.");

                multiplier = WINNER_STAKE_MULTIPLIER;
            } else {
                require(block.timestamp < (originalStart + ((originalEnd - originalStart) / 2)), "Funding must be made within the first half appeal period.");

                multiplier = LOSER_STAKE_MULTIPLIER;
            }

            originalCost = arbitrator.appealCost(disputeID, arbitratorExtraData);
            totalCost = originalCost.addCap(originalCost.mulCap(multiplier) / MULTIPLIER_DENOMINATOR);
        }

        uint256 lastRoundIndex = arbitrationRequest.rounds.length - 1;
        Round storage lastRound = arbitrationRequest.rounds[lastRoundIndex];
        require(!lastRound.hasPaid[_ruling], "Appeal fee has already been paid.");

        uint256 contribution = totalCost.subCap(lastRound.paidFees[_ruling]) > msg.value ? msg.value : totalCost.subCap(lastRound.paidFees[_ruling]);
        emit Contribution(_questionID, lastRoundIndex, _ruling, msg.sender, contribution);

        lastRound.contributions[msg.sender][_ruling] += contribution;
        lastRound.paidFees[_ruling] += contribution;

        if (lastRound.paidFees[_ruling] >= totalCost) {
            lastRound.feeRewards += lastRound.paidFees[_ruling];
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(_questionID, lastRoundIndex, _ruling);
        }

        if (lastRound.fundedRulings.length == 2) {
            // At least two ruling options are fully funded.
            arbitrationRequest.rounds.push();

            lastRound.feeRewards = lastRound.feeRewards.subCap(originalCost);
            arbitrator.appeal{value: originalCost}(disputeID, arbitratorExtraData);
        }

        if (msg.value.subCap(contribution) > 0) msg.sender.send(msg.value.subCap(contribution)); // Sending extra value back to contributor.

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Returns number of possible ruling options. Valid rulings are [0, count].
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256) external pure override returns (uint256 count) {
        return NUMBER_OF_RULING_OPTIONS;
    }

    /** @dev Returns arbitration fee by calling arbitrationCost function in the arbitrator contract.
     *  @return fee Arbitration fee that needs to be paid.
     */
    function getDisputeFee(bytes32) external view override returns (uint256 fee) {
        return arbitrator.arbitrationCost(arbitratorExtraData);
    }

    /** @dev Returns multipliers for appeals.
     *  @return _WINNER_STAKE_MULTIPLIER Winners stake multiplier.
     *  @return _LOSER_STAKE_MULTIPLIER Losers stake multiplier.
     *  @return _LOSER_APPEAL_PERIOD_MULTIPLIER Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return _DENOMINATOR Multiplier denominator in basis points. Required for achieving floating-point-like behavior.
     */
    function getMultipliers()
        external
        pure
        override
        returns (
            uint256 _WINNER_STAKE_MULTIPLIER,
            uint256 _LOSER_STAKE_MULTIPLIER,
            uint256 _LOSER_APPEAL_PERIOD_MULTIPLIER,
            uint256 _DENOMINATOR
        )
    {
        return (WINNER_STAKE_MULTIPLIER, LOSER_STAKE_MULTIPLIER, LOSER_APPEAL_PERIOD_MULTIPLIER, MULTIPLIER_DENOMINATOR);
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For all rounds at once.
     *  This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(2^m).
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The address whose rewards to withdraw.
     *  @param _ruling Ruling that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _questionID,
        address payable _contributor,
        uint256 _ruling
    ) external override {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        uint256 noOfRounds = arbitrationRequest.rounds.length;

        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewards(_questionID, _contributor, roundNumber, _ruling);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The address whose rewards to withdraw.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling Ruling that received contribution from contributor.
     *  @return amount The amount available to withdraw for given question, contributor, round number and ruling option.
     */
    function withdrawFeesAndRewards(
        uint256 _questionID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override returns (uint256 amount) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        require(arbitrationRequest.status > Status.Disputed, "There is no ruling yet.");

        Round storage round = arbitrationRequest.rounds[_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, arbitrationRequest.ruling);

        if (amount != 0) {
            round.contributions[_contributor][_ruling] = 0;
            _contributor.send(amount); // Ignoring failure condition deliberately.
            emit Withdrawal(_questionID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /** @dev Returns the sum of withdrawable amount.
     *  This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(m^2).
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling Ruling option to look for potential withdrawals.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _questionID,
        address payable _contributor,
        uint256 _ruling
    ) external view override returns (uint256 sum) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        if (arbitrationRequest.status < Status.Ruled) return 0;
        uint256 noOfRounds = arbitrationRequest.rounds.length;
        uint256 finalRuling = arbitrationRequest.ruling;

        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            Round storage round = arbitrationRequest.rounds[roundNumber];
            sum += getWithdrawableAmount(round, _contributor, _ruling, finalRuling);
        }
    }

    /** @dev Returns withdrawable amount for given parameters.
     *  @param _round The round to calculate amount for.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling The ruling option to search for potential withdrawal.
     *  @param _finalRuling Final ruling given by arbitrator.
     *  @return amount Amount available to withdraw for given ruling option.
     */
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        uint256 _ruling,
        uint256 _finalRuling
    ) internal view returns (uint256 amount) {
        if (!_round.hasPaid[_ruling]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][_ruling];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.paidFees[_ruling] > 0 ? (_round.contributions[_contributor][_ruling] * _round.feeRewards) / _round.paidFees[_ruling] : 0;
            } else if (!_round.hasPaid[_finalRuling]) {
                // The ultimate winner was not funded in this round. Contributions discounting the appeal fee are reimbursed proportionally.
                amount = (_round.contributions[_contributor][_ruling] * _round.feeRewards) / (_round.paidFees[_round.fundedRulings[0]] + _round.paidFees[_round.fundedRulings[1]]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@unknownunknown1*, @hbarcelos, @MerlinEgalite, @shalzz, @fnanni-0, @clesaege, @jaybuidl]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.0;

import "./IRealitio.sol";
import "./RealitioArbitratorWithAppealsBase.sol";

/**
 *  @title Realitio_v2_0_ArbitratorWithAppeals
 *  @dev A Realitio arbitrator implementation that uses Realitio v2.0 and Kleros.
 *  It notifies Realitio contract for arbitration requests and creates corresponding dispute on Kleros. Transmits Kleros ruling to Realitio contract.
 *  Maintains crowdfunded appeals and notifies Kleros contract. Provides a function to submit evidence for Kleros dispute.
 *  There is a conversion between Kleros ruling and Realitio answer and there is a need for shifting by 1. This is because ruling 0 in Kleros signals tie or no-ruling but in Realitio 0 is a valid answer.
 *  For reviewers this should be a focus as it's quite easy to get confused. Any mistakes on this conversion will render this contract useless.
 *  NOTE: This contract trusts the Kleros arbitrator and Realitio.
 */
contract Realitio_v2_0_ArbitratorWithAppeals is RealitioArbitratorWithAppealsBase {
    /** @dev Constructor.
     *  @param _realitio The address of the Realitio contract.
     *  @param _metadata The metadata required for RealitioArbitrator.
     *  @param _arbitrator The address of the ERC792 arbitrator.
     *  @param _arbitratorExtraData The extra data used to raise a dispute in the ERC792 arbitrator.
     *  @param _metaevidence Metaevidence as defined in ERC-1497.
     */
    constructor(
        IRealitio _realitio,
        string memory _metadata,
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaevidence
    ) RealitioArbitratorWithAppealsBase(_realitio, _metadata, _arbitrator, _arbitratorExtraData, _metaevidence) {}

    /** @dev Compute winner and report the answer to a specified question from the ERC792 arbitrator to the Realitio v2.0 contract. TRUSTED.
     *  @param _questionID The ID of the question.
     *  @param _lastHistoryHash The history hash given with the last answer to the question in the Realitio contract.
     *  @param _lastAnswerOrCommitmentID The last answer given, or its commitment ID if it was a commitment, to the question in the Realitio contract.
     *  @param _lastBond The bond paid for the last answer to the question in the Realitio contract.
     *  @param _lastAnswerer The last answerer to the question in the Realitio contract.
     *  @param _isCommitment Whether the last answer to the question in the Realitio contract used commit or reveal or not. True if it did, false otherwise.
     */
    function computeWinnerAndReportAnswer(
        bytes32 _questionID,
        bytes32 _lastHistoryHash,
        bytes32 _lastAnswerOrCommitmentID,
        uint256 _lastBond,
        address _lastAnswerer,
        bool _isCommitment
    ) external {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[uint256(_questionID)];
        require(arbitrationRequest.status == Status.Ruled, "The status should be Ruled.");
        require(
            realitio.getHistoryHash(_questionID) == keccak256(abi.encodePacked(_lastHistoryHash, _lastAnswerOrCommitmentID, _lastBond, _lastAnswerer, _isCommitment)),
            "The hash of the history parameters supplied does not match the one stored in the Realitio contract."
        ); // This is normally Realitio's responsibility to check but it does not, so we do instead. This is fixed in v2.1.

        arbitrationRequest.status = Status.Reported;

        // Note that ruling is shifted by -1 before calling Realitio. This works because 0-1 is equivalent to type(uint256).max. However, this won't be the case starting from Solidity 0.8.x.
        // https://docs.soliditylang.org/en/v0.8.0/080-breaking-changes.html
        realitio.submitAnswerByArbitrator(_questionID, bytes32(arbitrationRequest.ruling - 1), computeWinner(arbitrationRequest, _lastAnswerOrCommitmentID, _lastBond, _lastAnswerer, _isCommitment));
    }

    /** @dev Computes the Realitio answerer, of a specified question, that should win. This function is needed to avoid the "stack too deep error". TRUSTED.
     *  @param _arbitrationRequest Arbitration request to compute it's winner.
     *  @param _lastAnswerOrCommitmentID The last answer given, or its commitment ID if it was a commitment, to the question in the Realitio contract.
     *  @param _lastBond The bond paid for the last answer to the question in the Realitio contract.
     *  @param _lastAnswerer The last answerer to the question in the Realitio contract.
     *  @param _isCommitment Whether the last answer to the question in the Realitio contract used commit or reveal or not. True if it did, false otherwise.
     *  @return winner The computed winner.
     */
    function computeWinner(
        ArbitrationRequest storage _arbitrationRequest,
        bytes32 _lastAnswerOrCommitmentID,
        uint256 _lastBond,
        address _lastAnswerer,
        bool _isCommitment
    ) internal view returns (address winner) {
        bytes32 lastAnswer;
        bool isAnswered;
        if (_lastBond == 0) {
            // If the question hasn't been answered, nobody is ever right.
            isAnswered = false;
        } else if (_isCommitment) {
            (uint32 revealTS, bool isRevealed, bytes32 revealedAnswer) = realitio.commitments(_lastAnswerOrCommitmentID);
            if (isRevealed) {
                lastAnswer = revealedAnswer;
                isAnswered = true;
            } else {
                require(revealTS <= uint32(block.timestamp), "Arbitration cannot be done until the last answerer has had time to reveal its commitment.");
                isAnswered = false;
            }
        } else {
            lastAnswer = _lastAnswerOrCommitmentID;
            isAnswered = true;
        }

        // Note that 0-1=type(uint256).max. However starting from Solidity 0.8.x this won't be the case. https://docs.soliditylang.org/en/v0.8.0/080-breaking-changes.html
        return isAnswered && lastAnswer == bytes32(_arbitrationRequest.ruling - 1) ? _lastAnswerer : _arbitrationRequest.requester;
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc*, @hbarcelos*, @unknownunknown1*, @MerlinEgalite*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.0;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title This serves as a standard interface for crowdfunded appeals and evidence submission, which aren't a part of the arbitration (erc-792 and erc-1497) standard yet.
    This interface is used in Dispute Resolver (resolve.kleros.io).
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "2.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param _contributor Caller of fundAppeal function.
     *  @param _amount Contribution amount.
     */
    event Contribution(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 ruling, address indexed _contributor, uint256 _amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round The round number the withdrawal was made from.
     *  @param _ruling Indicates the ruling option which contributor gets rewards from.
     *  @param _contributor The beneficiary of withdrawal.
     *  @param _reward Total amount of withdrawal, consists of reimbursed deposits plus rewards.
     */
    event Withdrawal(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 _ruling, address indexed _contributor, uint256 _reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _round Number of the round this ruling option was fully funded in.
     *  @param _ruling The ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed _localDisputeID, uint256 indexed _round, uint256 indexed _ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
     *  @param _externalDisputeID Dispute id as in arbitrator contract.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 _externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external virtual;

    /** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable virtual returns (bool fullyFunded);

    /** @dev Returns appeal multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 denominator
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _round Number of the round that caller wants to execute withdraw on.
     *  @param _ruling A ruling option that caller wants to execute withdraw on.
     *  @return sum The amount that is going to be transferred to contributor as a result of this function call.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _round,
        uint256 _ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _ruling Ruling option that caller wants to get withdrawable amount from.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _ruling
    ) external view virtual returns (uint256 sum);
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

/**
 * @authors: [@mtsalenc, @hbarcelos]
 * @reviewers: [@clesaege*, @ferittuncer]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.7.6;


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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
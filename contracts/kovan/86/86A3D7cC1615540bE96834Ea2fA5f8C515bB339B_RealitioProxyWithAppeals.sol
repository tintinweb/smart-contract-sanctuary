// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.7;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/**
 *  @title This is a common interface for apps to interact with Dispute Resolver's standard operations.
 *  Sets a standard arbitrable contract implementation to provide a general purpose user interface.
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "1.0.0";

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param disputeID The dispute id as in the arbitrable contract.
     *  @param round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param contributor Caller of fundAppeal function.
     *  @param amount Contribution amount.
     */
    event Contribution(IArbitrator indexed arbitrator, uint256 indexed disputeID, uint256 indexed round, uint256 ruling, address contributor, uint256 amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param disputeID The dispute id as in arbitrable contract.
     *  @param round The round number the withdrawal was made from.
     *  @param ruling Indicates the ruling option which contributor gets rewards from.
     *  @param contributor The beneficiary of withdrawal.
     *  @param reward Total amount of deposits reimbursed plus rewards. This amount will be sent to contributor as an effect of calling withdrawFeesAndRewards function.
     */
    event Withdrawal(IArbitrator indexed arbitrator, uint256 indexed disputeID, uint256 indexed round, uint256 ruling, address contributor, uint256 reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param disputeID The dispute id as in arbitrable contract.
     *  @param round Round code of the appeal. Starts from 0.
     *  @param ruling THe ruling option which just got fully funded.
     */
    event RulingFunded(IArbitrator indexed arbitrator, uint256 indexed disputeID, uint256 indexed round, uint256 ruling);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(IArbitrator arbitrator, uint256 disputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param  evidenceURI Link to evidence.
     */
    function submitEvidence(
        IArbitrator arbitrator,
        uint256 disputeID,
        string calldata evidenceURI
    ) external virtual;

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
        Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(
        IArbitrator arbitrator,
        uint256 disputeID,
        uint256 ruling
    ) external payable virtual returns (bool fullyFunded);

    /** @dev Returns stake multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return tieStakeMultiplier Stake multiplier in case of a tie (ruling 0).
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return divisor Multiplier divisor in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 tieStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 divisor
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param contributor The address to withdraw its rewards.
     *  @param roundNumber The number of the round caller wants to withdraw from.
     *  @param ruling A ruling option that the caller wants to withdraw fees and rewards related to it.
     *  @return sum The reward that is going to be paid as a result of this function call, if it's not zero.
     */
    function withdrawFeesAndRewards(
        IArbitrator arbitrator,
        uint256 disputeID,
        address payable contributor,
        uint256 roundNumber,
        uint256 ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved. For multiple ruling options at once.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param contributor The address to withdraw its rewards.
     *  @param roundNumber The number of the round caller wants to withdraw from.
     *  @param contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        IArbitrator arbitrator,
        uint256 disputeID,
        address payable contributor,
        uint256 roundNumber,
        uint256[] memory contributedTo
    ) external virtual;

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param contributor The address to withdraw its rewards.
     *  @param contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        IArbitrator arbitrator,
        uint256 disputeID,
        address payable contributor,
        uint256[] memory contributedTo
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param disputeID Dispute id as in arbitrable contract.
     *  @param contributor The contributor for which to query.
     *  @param contributedTo Ruling options to look for potential withdrawals.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        IArbitrator arbitrator,
        uint256 disputeID,
        address payable contributor,
        uint256[] memory contributedTo
    ) public view virtual returns (uint256 sum);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: []
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
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external;

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
 *  @reviewers: []
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
    function realitio() external view returns (IRealitio);

    function metadata() external view returns (string calldata);

    function getDisputeFee(bytes32 questionID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.7;
pragma abicoder v2;

import "./IRealitio.sol";
import "./IRealitioArbitrator.sol";
import "../IDisputeResolver.sol";

import "@kleros/ethereum-libraries/contracts/CappedMath.sol";

/**
 *  @title RealitioArbitratorProxyWithAppeals
 *  @dev A proxy contract for Realitio with extra logic to form an adapter between Kleros and Realitio. It notifies Realitio contract for arbitration requests and creates corresponding dispute on Kleros. Transmits Kleros ruling to Realitio contract. Maintains crowdfunded appeals and notifies Kleros contract. Provides a function to submit evidence for Kleros dispute.
 *  Disputes happen between the last answer and the challengers answer. But Kleros can rule for any valid answer as a response.
 *  There is a conversion between Kleros ruling and Realitio answer and there is a need for shifting by 1. For reviewers this should be a focus as it's quite easy to get confused. Any mistakes on this conversion will render this contract useless.
 *  NOTE: This contract trusts to the Kleros arbitrator and Realitio.
 */
contract RealitioProxyWithAppeals is IDisputeResolver, IRealitioArbitrator {
    IRealitio public override realitio; // Actual implementation of Realitio.
    string public override metadata = "0x0";
    uint256 private constant NO_OF_RULING_OPTIONS = (2**256) - 2; // The amount of non 0 choices the arbitrator can give. The uint256(-1) number of choices can not be used in the current Kleros Court implementation.
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour. First 64 characters contain subcourtID and the second 64 characters contain number of votes in the jury.
    IArbitrator public immutable arbitrator; // The arbitrator contract. This will be Kleros arbitrator.
    address public governor = msg.sender; // The address that can make governance changes.

    // The required fee stake that a party must pay depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is stake multiplier * arbitration cost for that round.
    uint256 public winnerStakeMultiplier = 3000; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points. Default is 1x of appeal fee.
    uint256 public loserStakeMultiplier = 7000; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points. Default is 2x of appeal fee.
    uint256 public tieStakeMultiplier = 3000; // Multiplier of the arbitration cost that the parties has to pay as fee stake for a round in basis points, in case of tie. Default is 1x of appeal fee.
    uint256 public loserAppealPeriodMultiplier = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. Default is 1/2 of original appeal period.
    uint256 public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    enum Status {
        None, // The question hasn't been requested arbitration yet.
        Disputed, // The question has been requested arbitration.
        Ruled, // The question has been ruled by arbitrator.
        Reported // The answer of the question has been reported to Realitio.
    }

    // To track internal state in this contract
    struct QuestionArbitrationData {
        address disputer; // The address that requested the arbitration.
        Status status; // The current status of the question.
        uint256 disputeID; // The ID of the dispute raised in the arbitrator contract.
        bytes32 answer; // The answer given by the arbitrator.
        Round[] rounds; // Tracks each appeal round of a dispute.
    }

    // For appeal logic
    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid in this round in the form paidFees[answer].
        mapping(uint256 => bool) hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[answer].
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each answer in the form contributions[address][answer].
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the answer that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the answer choices that are fully funded.
    }
    using CappedMath for uint256; // Operations bounded between 0 and 2**256 - 2. Note the 0 is reserver for invalid / refused to rule.

    mapping(bytes32 => QuestionArbitrationData) public questionArbitrationDatas; // Maps a question ID to its data.
    uint256 public metaEvidenceUpdates; // The number of times the meta evidence has been updated. Used to track the latest meta evidence ID.
    mapping(uint256 => bytes32) public disputeIDtoQuestionID; // Arbitrator dispute ids to question ids.

    /** @dev Constructor.
     *  @param _realitio The address of the Realitio contract.
     *  @param _arbitrator The address of the ERC792 arbitrator.
     *  @param _arbitratorExtraData The extra data used to raise a dispute in the ERC792 arbitrator.
     */
    constructor(
        IRealitio _realitio,
        string memory _metadata,
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaEvidence
    ) {
        realitio = _realitio;
        metadata = _metadata;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        emit MetaEvidence(metaEvidenceUpdates, _metaEvidence);
    }

    /** @dev Updates the meta evidence used for disputes.
     *  @param _metaEvidence URI to the new meta evidence file.
     */
    function changeMetaEvidence(string calldata _metaEvidence) external {
        require(msg.sender == governor, "Only governor can execute this");
        metaEvidenceUpdates++;
        emit MetaEvidence(metaEvidenceUpdates, _metaEvidence);
    }

    /** @dev Sets the meta evidence. Can only be called once.
     *  @param _questionID The question id as in Realitio side.
     */
    function getDisputeFee(bytes32 _questionID) external view override returns (uint256 fee) {
        QuestionArbitrationData storage question = questionArbitrationDatas[_questionID];
        require(question.status == Status.None, "Arbitration already requested");

        return arbitrator.arbitrationCost(arbitratorExtraData);
    }

    /** @dev Sets the meta evidence. Can only be called once.
     *  @param _questionID The question id as in Realitio side.
     *  @param _maxPrevious If specified, reverts if a bond higher than this was submitted after you sent your transaction.
     */
    function requestArbitration(bytes32 _questionID, uint256 _maxPrevious) external payable returns (uint256 disputeID) {
        QuestionArbitrationData storage question = questionArbitrationDatas[_questionID];
        require(question.status == Status.None, "Arbitration already requested");

        // Notify Kleros
        disputeID = arbitrator.createDispute{value: msg.value}(NO_OF_RULING_OPTIONS, arbitratorExtraData);
        emit Dispute(arbitrator, disputeID, metaEvidenceUpdates, uint256(_questionID));
        disputeIDtoQuestionID[disputeID] = _questionID;

        // Update internal state
        question.disputer = msg.sender;
        question.status = Status.Disputed;
        question.disputeID = disputeID;
        question.rounds.push();

        // Notify Realitio
        realitio.notifyOfArbitrationRequest(_questionID, msg.sender, _maxPrevious);
    }

    /** @dev Reports the answer to a specified question from the Kleros arbitrator to the Realitio contract.
     *  @param _questionID The ID of the question.
     *  @param _lastHistoryHash The history hash given with the last answer to the question in the Realitio contract.
     *  @param _lastAnswerOrCommitmentID The last answer given, or its commitment ID if it was a commitment, to the question in the Realitio contract, in bytes32.
     *  @param _lastAnswerer The last answerer to the question in the Realitio contract.
     */
    function reportAnswer(
        bytes32 _questionID,
        bytes32 _lastHistoryHash,
        bytes32 _lastAnswerOrCommitmentID,
        address _lastAnswerer
    ) external {
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[_questionID];
        require(questionDispute.status == Status.Ruled, "The status should be Ruled.");

        questionDispute.status = Status.Reported;

        realitio.assignWinnerAndSubmitAnswerByArbitrator(_questionID, questionDispute.answer, questionDispute.disputer, _lastHistoryHash, _lastAnswerOrCommitmentID, _lastAnswerer);
    }

    /* Following section contains implementation of IDisputeResolver */

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(IArbitrator, uint256) external pure override returns (uint256 count) {
        return NO_OF_RULING_OPTIONS;
    }

    /** @dev Receives ruling from Kleros and executes consequences.
     *  @param _disputeID ID of Kleros dispute.
     *  @param _ruling Ruling that is given by Kleros. This needs to be converted to Realitio answer by shifting by 1.
     */
    function rule(uint256 _disputeID, uint256 _ruling) public override {
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];

        require(IArbitrator(msg.sender) == arbitrator, "Only arbitrator allowed");
        require(_ruling <= NO_OF_RULING_OPTIONS, "Invalid ruling");
        require(questionDispute.status == Status.Disputed, "Invalid arbitration status");

        Round storage round = questionDispute.rounds[questionDispute.rounds.length - 1];
        uint256 finalRuling = (round.fundedRulings.length == 1) ? round.fundedRulings[0] : _ruling;

        questionDispute.answer = bytes32(finalRuling - 1); // Shift Kleros ruling by +1 to match Realitio layout
        questionDispute.status = Status.Ruled;

        // Notify Kleros
        emit Ruling(IArbitrator(msg.sender), _disputeID, finalRuling);
    }

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _disputeID Dispute id as in arbitrable contract.
     *  @param  _evidenceURI Link to evidence.
     */
    function submitEvidence(
        IArbitrator,
        uint256 _disputeID,
        string calldata _evidenceURI
    ) external override {
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];

        require(questionDispute.status < Status.Ruled, "Cannot submit evidence to a resolved dispute.");

        emit Evidence(arbitrator, _disputeID, msg.sender, _evidenceURI);
    }

    /** @dev Retrieves appeal cost for each ruling. It extends the function with the same name on the arbitrator side by adding
     *  _ruling parameter because total to be raised depends on multipliers.
     *  @param _disputeID The dispute this function returns its appeal costs.
     *  @param _ruling The ruling option which the caller wants to learn about its appeal cost.
     *  @param _currentRuling The ruling option which the caller wants to learn about its appeal cost.
     */
    function appealCost(
        uint256 _disputeID,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view returns (uint256 originalCost, uint256 specificCost) {
        uint256 multiplier;
        if (_currentRuling == 0) multiplier = tieStakeMultiplier;
        else if (_ruling == _currentRuling) multiplier = winnerStakeMultiplier;
        else multiplier = loserStakeMultiplier;

        uint256 appealFee = arbitrator.appealCost(_disputeID, arbitratorExtraData);
        return (appealFee, appealFee.addCap(appealFee.mulCap(multiplier) / MULTIPLIER_DIVISOR));
    }

    /** @dev Reverts if appeal period has expired for given ruling option. It gives less time for funding appeal for losing ruling option (in the last round).
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _ruling The ruling option to query for.
     *  @param _currentRuling The latest ruling given by Kleros. Note that this ruling is not final at this point, can be appealed.
     */
    function checkAppealPeriod(
        uint256 _disputeID,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view {
        (uint256 originalStart, uint256 originalEnd) = arbitrator.appealPeriod(_disputeID);

        if (_currentRuling == _ruling || _currentRuling == 0) require(block.timestamp >= originalStart && block.timestamp < originalEnd, "Funding must be made within the appeal period.");
        else {
            require(block.timestamp >= originalStart && block.timestamp < (originalStart + ((originalEnd - originalStart) * loserAppealPeriodMultiplier) / MULTIPLIER_DIVISOR), "Funding must be made within the appeal period.");
        }
    }

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
        Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _ruling The ruling option to which the caller wants to contribute to.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(
        IArbitrator,
        uint256 _disputeID,
        uint256 _ruling
    ) external payable override returns (bool fullyFunded) {
        require(_ruling <= NO_OF_RULING_OPTIONS, "Answer is out of bounds");
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];
        require(questionDispute.status == Status.Disputed, "No dispute to appeal.");

        uint256 currentRuling = arbitrator.currentRuling(_disputeID);

        checkAppealPeriod(_disputeID, _ruling, currentRuling);
        (uint256 originalCost, uint256 totalCost) = appealCost(_disputeID, _ruling, currentRuling);

        uint256 roundsLength = questionDispute.rounds.length;
        Round storage lastRound = questionDispute.rounds[roundsLength - 1];
        require(!lastRound.hasPaid[_ruling], "Appeal fee has already been paid.");
        uint256 paidFeesInLastRound = lastRound.paidFees[_ruling];

        uint256 contribution = totalCost.subCap(paidFeesInLastRound) > msg.value ? msg.value : totalCost.subCap(paidFeesInLastRound);
        emit Contribution(arbitrator, _disputeID, roundsLength - 1, _ruling, msg.sender, contribution);

        lastRound.contributions[msg.sender][_ruling] += contribution;

        if (paidFeesInLastRound >= totalCost) {
            lastRound.feeRewards += paidFeesInLastRound;
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(arbitrator, _disputeID, roundsLength - 1, _ruling);
        }

        if (lastRound.fundedRulings.length > 1) {
            // At least two ruling options are fully funded.
            questionDispute.rounds.push();

            lastRound.feeRewards = lastRound.feeRewards.subCap(originalCost);
            arbitrator.appeal{value: originalCost}(_disputeID, arbitratorExtraData);
        }

        msg.sender.transfer(msg.value.subCap(contribution)); // Sending extra value back to contributor.

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Returns stake multipliers.
     *  @return _winnerStakeMultiplier Winners stake multiplier.
     *  @return _loserStakeMultiplier Losers stake multiplier.
     *  @return _tieStakeMultiplier Stake multiplier in case of a tie (ruling 0).
     *  @return _loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return _divisor Multiplier divisor in basis points.
     */
    function getMultipliers()
        public
        view
        override
        returns (
            uint256 _winnerStakeMultiplier,
            uint256 _loserStakeMultiplier,
            uint256 _tieStakeMultiplier,
            uint256 _loserAppealPeriodMultiplier,
            uint256 _divisor
        )
    {
        return (winnerStakeMultiplier, loserStakeMultiplier, tieStakeMultiplier, loserAppealPeriodMultiplier, MULTIPLIER_DIVISOR);
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling A ruling option that the caller wants to withdraw fees and rewards related to it.
     */
    function withdrawFeesAndRewards(
        IArbitrator,
        uint256 _disputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override returns (uint256 amount) {
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];

        Round storage round = questionDispute.rounds[_roundNumber];

        require(questionDispute.status >= Status.Ruled, "There is no ruling yet.");

        if (!round.hasPaid[_ruling]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = round.contributions[_contributor][_ruling];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == (uint256(questionDispute.answer) + 1)) {
                // This ruling option is the ultimate winner.
                uint256 paidFees = round.paidFees[_ruling];
                amount += paidFees > 0 ? (round.contributions[_contributor][_ruling] * round.feeRewards) / paidFees : 0;
            } else if (!round.hasPaid[uint256(questionDispute.answer) + 1]) {
                // This ruling option was not the ultimate winner, but the ultimate winner was not funded in this round. In this case funded ruling option(s) wins by default. Prize is distributed among contributors of funded ruling option(s).
                amount += (round.contributions[_contributor][_ruling] * round.feeRewards) / (round.paidFees[round.fundedRulings[0]] + round.paidFees[round.fundedRulings[1]]);
            }
        }

        round.contributions[_contributor][_ruling] = 0;
        if (amount != 0) {
            _contributor.send(amount); // User is responsible for accepting the reward.
            emit Withdrawal(arbitrator, _disputeID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved. For multiple ruling options at once.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        IArbitrator,
        uint256 _disputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256[] memory _contributedTo
    ) public override {
        uint256 contributionArrayLength = _contributedTo.length;
        for (uint256 contributionNumber = 0; contributionNumber < contributionArrayLength; contributionNumber++) {
            withdrawFeesAndRewards(arbitrator, _disputeID, _contributor, _roundNumber, _contributedTo[contributionNumber]);
        }
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        IArbitrator,
        uint256 _disputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) external override {
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];
        uint256 noOfRounds = questionDispute.rounds.length;

        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewardsForMultipleRulings(arbitrator, _disputeID, _contributor, roundNumber, _contributedTo);
        }
    }

    /** @dev Returns the sum of withdrawable amount.
     *  @param _disputeID Dispute ID of Kleros dispute.
     *  @param _contributor The contributor for which to query.
     *  @param _contributedTo Ruling options to look for potential withdrawals.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        IArbitrator,
        uint256 _disputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) public view override returns (uint256 sum) {
        bytes32 questionID = disputeIDtoQuestionID[_disputeID];
        QuestionArbitrationData storage questionDispute = questionArbitrationDatas[questionID];
        uint256 noOfRounds = questionDispute.rounds.length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            for (uint256 contributionNumber = 0; contributionNumber < _contributedTo.length; contributionNumber++) {
                Round storage round = questionDispute.rounds[roundNumber];
                uint256 finalRuling = uint256(questionDispute.answer) + 1;
                uint256 ruling = _contributedTo[contributionNumber];
                require(questionDispute.status >= Status.Ruled, "There is no ruling yet.");

                if (!round.hasPaid[ruling]) {
                    // Allow to reimburse if funding was unsuccessful for this ruling option.
                    sum += round.contributions[_contributor][ruling];
                } else {
                    //Funding was successful for this ruling option.
                    if (ruling == finalRuling) {
                        // This ruling option is the ultimate winner.
                        sum += round.paidFees[ruling] > 0 ? (round.contributions[_contributor][ruling] * round.feeRewards) / round.paidFees[ruling] : 0;
                    } else if (!round.hasPaid[finalRuling]) {
                        // This ruling option was not the ultimate winner, but the ultimate winner was not funded in this round. In this case funded ruling option(s) wins by default. Prize is distributed among contributors of funded ruling option(s).
                        sum += (round.contributions[_contributor][ruling] * round.feeRewards) / (round.paidFees[round.fundedRulings[0]] + round.paidFees[round.fundedRulings[1]]);
                    }
                }
            }
        }
    }
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

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: [@clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.6;


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
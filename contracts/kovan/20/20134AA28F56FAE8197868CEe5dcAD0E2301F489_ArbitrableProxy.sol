// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@fnanni-0*, @unknownunknown1*, @mtsalenc*, @MerlinEgalite*, @shalzz*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: [0xA3B02bA6E10F55fb177637917B1b472da0110CcC]
 */

pragma solidity ^0.7.0;

import "@kleros/ethereum-libraries/contracts/CappedMath.sol";
import "@kleros/dispute-resolver-interface-contract/contracts/solc-0.7.x/IDisputeResolver.sol";

/**
 *  @title ArbitrableProxy
 *  A general purpose arbitrable contract. Supports non-binary rulings.
 */
contract ArbitrableProxy is IDisputeResolver {
    using CappedMath for uint256; // Operations bounded between 0 and `type(uint256).max`.

    uint256 public constant MAX_NUMBER_OF_CHOICES = type(uint256).max - 1;

    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid for each ruling option in this round.
        mapping(uint256 => bool) hasPaid; // True if this ruling option was fully funded, false otherwise.
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each side.
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the ruling that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the ruling options that are fully funded.
    }

    struct DisputeStruct {
        bytes arbitratorExtraData;
        bool isRuled;
        uint256 ruling;
        uint256 disputeIDOnArbitratorSide;
    }

    address public governor = msg.sender; // By default the governor is the deployer of this contract.
    IArbitrator public immutable arbitrator; // Arbitrator is set in constructor and never changed.

    // The required fee stake that a party must pay depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is stake multiplier * arbitration cost for that round.
    uint256 public winnerStakeMultiplier = 10000; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points. Default is 1x of appeal fee.
    uint256 public loserStakeMultiplier = 20000; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points. Default is 2x of appeal fee.
    uint256 public loserAppealPeriodMultiplier = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. Default is 1/2 of original appeal period.
    uint256 public constant DENOMINATOR = 10000; // Denominator for multipliers.

    DisputeStruct[] public disputes;
    mapping(uint256 => uint256) public override externalIDtoLocalID; // Maps external (arbitrator side) dispute IDs to local dispute IDs.
    mapping(uint256 => Round[]) public disputeIDtoRoundArray; // Maps dispute IDs to round arrays.
    mapping(uint256 => uint256) public override numberOfRulingOptions; // Maps localDisputeIDs to number of possible ruling options.

    /** @dev Constructor
     *  @param _arbitrator Target global arbitrator for any disputes.
     */
    constructor(IArbitrator _arbitrator) {
        arbitrator = _arbitrator;
    }

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external override {
        DisputeStruct storage dispute = disputes[_localDisputeID];
        require(dispute.isRuled == false, "Cannot submit evidence to a resolved dispute.");

        emit Evidence(arbitrator, _localDisputeID, msg.sender, _evidenceURI);
    }

    /** @dev TRUSTED. Calls createDispute function of the specified arbitrator to create a dispute.
        Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator of prospective dispute.
     *  @param _metaevidenceURI Link to metaevidence of prospective dispute.
     *  @param _numberOfRulingOptions Number of ruling options.
     *  @return disputeID Dispute id (on arbitrator side) of the dispute created.
     */
    function createDispute(
        bytes calldata _arbitratorExtraData,
        string calldata _metaevidenceURI,
        uint256 _numberOfRulingOptions
    ) external payable returns (uint256 disputeID) {
        require(_numberOfRulingOptions <= MAX_NUMBER_OF_CHOICES, "Number of ruling options out of range.");
        if (_numberOfRulingOptions == 0) _numberOfRulingOptions = MAX_NUMBER_OF_CHOICES;

        disputeID = arbitrator.createDispute{value: msg.value}(_numberOfRulingOptions, _arbitratorExtraData);

        uint256 localDisputeID = disputes.length;

        disputes.push(DisputeStruct({arbitratorExtraData: _arbitratorExtraData, isRuled: false, ruling: 0, disputeIDOnArbitratorSide: disputeID}));

        externalIDtoLocalID[disputeID] = localDisputeID;

        numberOfRulingOptions[localDisputeID] = _numberOfRulingOptions;
        disputeIDtoRoundArray[localDisputeID].push();

        emit MetaEvidence(localDisputeID, _metaevidenceURI);
        emit Dispute(arbitrator, disputeID, localDisputeID, localDisputeID);
    }

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _ruling The ruling to which the caller wants to contribute.
     *  @return fullyFunded Whether _ruling was fully funded after the call.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable override returns (bool fullyFunded) {
        require(_ruling <= numberOfRulingOptions[_localDisputeID], "There is no such ruling to fund.");
        DisputeStruct storage dispute = disputes[_localDisputeID];
        uint256 disputeID = dispute.disputeIDOnArbitratorSide; // Intermediate variable to make reads cheaper.

        uint256 originalCost;
        uint256 totalCost;
        {
            uint256 currentRuling = arbitrator.currentRuling(disputeID); // Intermediate variable to make reads cheaper.
            (originalCost, totalCost) = appealCost(disputeID, dispute.arbitratorExtraData, _ruling, currentRuling);
            checkAppealPeriod(disputeID, _ruling, currentRuling); // Reverts if appeal period has been expired for _ruling.
        }

        Round[] storage rounds = disputeIDtoRoundArray[_localDisputeID];
        uint256 lastRoundIndex = rounds.length - 1; // Intermediate variable to make reads cheaper.
        Round storage lastRound = rounds[lastRoundIndex];

        require(!lastRound.hasPaid[_ruling], "Appeal fee has already been paid.");
        uint256 paidFeesInLastRound = lastRound.paidFees[_ruling]; // Intermediate variable to make reads cheaper.

        uint256 contribution = totalCost.subCap(paidFeesInLastRound) > msg.value ? msg.value : totalCost.subCap(paidFeesInLastRound);
        lastRound.paidFees[_ruling] += contribution;

        emit Contribution(_localDisputeID, lastRoundIndex, _ruling, msg.sender, contribution);
        lastRound.contributions[msg.sender][_ruling] += contribution;

        paidFeesInLastRound = lastRound.paidFees[_ruling]; // Intermediate variable to make reads cheaper.

        if (paidFeesInLastRound >= totalCost) {
            lastRound.feeRewards += paidFeesInLastRound;
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(_localDisputeID, lastRoundIndex, _ruling);
        }

        if (lastRound.fundedRulings.length == 2) {
            // Two competing ruling options means we will have another appeal round.
            rounds.push();

            lastRound.feeRewards = lastRound.feeRewards.subCap(originalCost);
            arbitrator.appeal{value: originalCost}(disputeID, dispute.arbitratorExtraData);
        }

        msg.sender.send(msg.value.subCap(contribution)); // Sending extra value back to contributor. Send preferred over transfer deliberately.

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  This function has O(m*n) time complexity where m is number of rounds and n is the number of ruling options contributed by given user.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(m^2).
     *  It is safe to assume n is always less than 3 as it does not make sense to contribute to different ruling options in the same round, so it will rarely be greater than 1.
     *  Thus, we can assume this loop will run less than 30(10*3) times, and on average just a few times.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) external override {
        uint256 numberOfRounds = disputeIDtoRoundArray[_localDisputeID].length;
        for (uint256 roundNumber = 0; roundNumber < numberOfRounds; roundNumber++) {
            withdrawFeesAndRewardsForMultipleRulings(_localDisputeID, _contributor, roundNumber, _contributedTo);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved for multiple ruling options at once.
     *  This function has O(n) time complexity where n is number of ruling options contributed by given user.
     *  It is safe to assume n is always less than 3 as it does not make sense to contribute to different ruling options in the same round, so it will rarely be greater than 1.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256[] memory _contributedTo
    ) public override {
        uint256 contributionArrayLength = _contributedTo.length;
        for (uint256 contributionNumber = 0; contributionNumber < contributionArrayLength; contributionNumber++) {
            withdrawFeesAndRewards(_localDisputeID, _contributor, _roundNumber, _contributedTo[contributionNumber]);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling The ruling option that the caller wants to withdraw fees and rewards related to it.
     *  @return amount Reward amount that is to be withdrawn. Might be zero if arguments are not qualifying for a reward or reimbursement, or it might be withdrawn already.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override returns (uint256 amount) {
        DisputeStruct storage dispute = disputes[_localDisputeID];
        require(dispute.isRuled, "The dispute should be solved");

        Round storage round = disputeIDtoRoundArray[_localDisputeID][_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, dispute.ruling);

        if (amount != 0) {
            round.contributions[_contributor][_ruling] = 0;
            _contributor.send(amount); // Ignoring failure condition deliberately.
            emit Withdrawal(_localDisputeID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /** @dev To be called by the arbitrator of the dispute, to declare winning ruling.
     *  @param _externalDisputeID ID of the dispute in arbitrator contract.
     *  @param _ruling The ruling choice of the arbitration.
     */
    function rule(uint256 _externalDisputeID, uint256 _ruling) external override {
        uint256 localDisputeID = externalIDtoLocalID[_externalDisputeID];
        DisputeStruct storage dispute = disputes[localDisputeID];
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(_ruling <= numberOfRulingOptions[localDisputeID], "Invalid ruling.");
        require(dispute.isRuled == false, "This dispute has been ruled already.");

        dispute.isRuled = true;
        dispute.ruling = _ruling;

        Round[] storage rounds = disputeIDtoRoundArray[localDisputeID];
        Round storage lastRound = disputeIDtoRoundArray[localDisputeID][rounds.length - 1];
        // If only one ruling option is funded, it wins by default. Note that if any other ruling had funded, an appeal would have been created.
        if (lastRound.fundedRulings.length == 1) {
            dispute.ruling = lastRound.fundedRulings[0];
        }

        emit Ruling(IArbitrator(msg.sender), _externalDisputeID, dispute.ruling);
    }

    /** @dev Changes governor.
     *  @param _newGovernor The address of the new governor.
     */
    function setGovernor(address _newGovernor) external {
        require(msg.sender == governor, "Only the governor can execute this.");
        governor = _newGovernor;
    }

    /** @dev Changes the proportion of appeal fees that must be paid by winner and loser and changes the appeal period portion for losers.
     *  @param _winnerStakeMultiplier The new winner stake multiplier value respect to DENOMINATOR.
     *  @param _loserStakeMultiplier The new loser stake multiplier value respect to DENOMINATOR.
     *  @param _loserAppealPeriodMultiplier The new loser appeal period multiplier respect to DENOMINATOR. Having a value greater than DENOMINATOR has no effect since arbitrator limits appeal period.
     */
    function changeMultipliers(
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        uint256 _loserAppealPeriodMultiplier
    ) external {
        require(msg.sender == governor, "Only the governor can execute this.");
        winnerStakeMultiplier = _winnerStakeMultiplier;
        loserStakeMultiplier = _loserStakeMultiplier;
        loserAppealPeriodMultiplier = _loserAppealPeriodMultiplier;
    }

    /** @notice Returns the sum of withdrawable amount.
     *  @dev This function has O(m*n) time complexity where m is number of rounds and n is the number of ruling options contributed by given user.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(m^2). And n being greater than 1 is unlikely.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The contributor for which to query.
     *  @param _contributedTo The array which includes ruling options to search for potential withdrawal. Caller can obtain this information using Contribution events.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) external view override returns (uint256 sum) {
        DisputeStruct storage dispute = disputes[_localDisputeID];
        if (!dispute.isRuled) return 0;
        uint256 finalRuling = dispute.ruling;

        uint256 numberOfRounds = disputeIDtoRoundArray[_localDisputeID].length;
        for (uint256 roundNumber = 0; roundNumber < numberOfRounds; roundNumber++) {
            Round storage round = disputeIDtoRoundArray[_localDisputeID][roundNumber];
            for (uint256 contributionNumber = 0; contributionNumber < _contributedTo.length; contributionNumber++) {
                uint256 ruling = _contributedTo[contributionNumber];

                sum += getWithdrawableAmount(round, _contributor, ruling, finalRuling);
            }
        }
    }

    /** @dev Returns stake multipliers.
     *  @return _winnerStakeMultiplier Winners stake multiplier.
     *  @return _loserStakeMultiplier Losers stake multiplier.
     *  @return _loserAppealPeriodMultiplier Multiplier for losers appeal period. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return _denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        override
        returns (
            uint256 _winnerStakeMultiplier,
            uint256 _loserStakeMultiplier,
            uint256 _loserAppealPeriodMultiplier,
            uint256 _denominator
        )
    {
        return (winnerStakeMultiplier, loserStakeMultiplier, loserAppealPeriodMultiplier, DENOMINATOR);
    }

    /** @dev Returns withdrawable amount for given parameters.
     *  @param _round The round number to calculate amount for.
     *  @param _contributor The contributor for which to query.
     *  @param _contributedTo The ruling option to search for potential withdrawal. Caller can obtain this information using Contribution events.
     *  @return amount The total amount available to withdraw.
     */
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        uint256 _contributedTo,
        uint256 _finalRuling
    ) internal view returns (uint256 amount) {
        if (!_round.hasPaid[_contributedTo]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][_contributedTo];
        } else {
            // Funding was successful for this ruling option.
            if (_contributedTo == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.paidFees[_contributedTo] > 0 ? (_round.contributions[_contributor][_contributedTo] * _round.feeRewards) / _round.paidFees[_contributedTo] : 0;
            } else if (!_round.hasPaid[_finalRuling]) {
                // The ultimate winner was not funded in this round. In this case funded ruling option(s) wins by default. Prize is distributed among contributors of funded ruling option(s).
                amount = (_round.contributions[_contributor][_contributedTo] * _round.feeRewards) / (_round.paidFees[_round.fundedRulings[0]] + _round.paidFees[_round.fundedRulings[1]]);
            }
        }
    }

    /** @dev Reverts if appeal period has expired for given ruling option. It gives less time for funding appeal for losing ruling option (in the last round).
     *  Note that we don't check starting time, as arbitrator already check this. If user contributes before starting time it's effectively an early contibution for the next round.
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

        if (_currentRuling == _ruling) {
            require(block.timestamp < originalEnd, "Funding must be made within the appeal period.");
        } else {
            require(block.timestamp < (originalStart + ((originalEnd - originalStart) * loserAppealPeriodMultiplier) / DENOMINATOR), "Funding must be made within the appeal period.");
        }
    }

    /** @dev Retrieves appeal cost for each ruling. It extends the function with the same name on the arbitrator side by adding
     *  _ruling parameter because total to be raised depends on multipliers.
     *  @param _disputeID The dispute this function returns its appeal costs.
     *  @param _arbitratorExtraData Extra data for the arbitrator of prospective dispute.
     *  @param _ruling The ruling option which the caller wants to return the appeal cost for.
     *  @param _currentRuling The ruling option which the caller wants to return the appeal cost for.
     *  @return originalCost The original cost of appeal, decided by arbitrator.
     *  @return specificCost The specific cost of appeal, including appeal stakes of winner or loser.
     */
    function appealCost(
        uint256 _disputeID,
        bytes memory _arbitratorExtraData,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view returns (uint256 originalCost, uint256 specificCost) {
        uint256 multiplier;
        if (_ruling == _currentRuling) multiplier = winnerStakeMultiplier;
        else multiplier = loserStakeMultiplier;

        uint256 appealFee = arbitrator.appealCost(_disputeID, _arbitratorExtraData);
        return (appealFee, appealFee.addCap(appealFee.mulCap(multiplier) / DENOMINATOR));
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
    string public constant VERSION = "1.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

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

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets resolved. For multiple ruling options at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _round Number of the round that caller wants to execute withdraw on.
     *  @param _contributedTo Ruling options that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _round,
        uint256[] memory _contributedTo
    ) external virtual;

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _contributedTo Ruling options that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param _contributor Beneficiary of withdraw operation.
     *  @param _contributedTo Ruling options that caller wants to get withdrawable amount from.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
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
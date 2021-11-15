// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@fnanni-0*, @unknownunknown1*, @mtsalenc]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity >=0.7;

import "./IDisputeResolver.sol";
import "@kleros/ethereum-libraries/contracts/CappedMath.sol";

/**
 *  @title ArbitrableProxy
 *  A general purpose arbitrable contract. Supports non-binary rulings.
 */
contract ArbitrableProxy is IDisputeResolver {
    using CappedMath for uint256; // Operations bounded between 0 and 2**256 - 2. Note the 0 is reserver for invalid / refused to rule.

    uint256 public constant MAX_NO_OF_CHOICES = (2**256) - 2;

    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid for each ruling option in this round.
        mapping(uint256 => bool) hasPaid; // True if this ruling option was fully funded; false otherwise.
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each side.
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the ruling that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the ruling options that are fully funded.
    }

    struct DisputeStruct {
        bytes arbitratorExtraData;
        bool isRuled;
        uint256 ruling;
        uint256 disputeIDOnArbitratorSide;
        uint256 numberOfRulingOptions;
    }

    address public governor = msg.sender;
    IArbitrator public immutable arbitrator;

    // The required fee stake that a party must pay depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is stake multiplier * arbitration cost for that round.
    uint256 public winnerStakeMultiplier = 10000; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points. Default is 1x of appeal fee.
    uint256 public loserStakeMultiplier = 20000; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points. Default is 2x of appeal fee.
    uint256 public tieStakeMultiplier = 10000; // Multiplier of the arbitration cost that the parties has to pay as fee stake for a round in basis points, in case of tie. Default is 1x of appeal fee.
    uint256 public loserAppealPeriodMultiplier = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. Default is 1/2 of original appeal period.
    uint256 public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    DisputeStruct[] public disputes;
    mapping(uint256 => uint256) public override externalIDtoLocalID; // Maps external (arbitrator side) dispute ids to local dispute ids.
    mapping(uint256 => Round[]) public disputeIDtoRoundArray; // Maps dispute ids to round arrays.

    /** @dev Constructor
     *  @param _arbitrator Target global arbitrator for any disputes.
     */
    constructor(IArbitrator _arbitrator) {
        arbitrator = _arbitrator;
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
        if (_numberOfRulingOptions == 0) _numberOfRulingOptions = MAX_NO_OF_CHOICES;

        disputeID = arbitrator.createDispute{value: msg.value}(_numberOfRulingOptions, _arbitratorExtraData);

        disputes.push(DisputeStruct({arbitratorExtraData: _arbitratorExtraData, isRuled: false, ruling: 0, disputeIDOnArbitratorSide: disputeID, numberOfRulingOptions: _numberOfRulingOptions}));

        uint256 localDisputeID = disputes.length - 1;
        externalIDtoLocalID[disputeID] = localDisputeID;

        disputeIDtoRoundArray[localDisputeID].push();

        emit MetaEvidence(localDisputeID, _metaevidenceURI);
        emit Dispute(arbitrator, disputeID, localDisputeID, localDisputeID);
    }

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @return count Number of possible ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view override returns (uint256 count) {
        count = disputes[_localDisputeID].numberOfRulingOptions;
    }

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
        Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _ruling The ruling to which the caller wants to contribute.
     *  @return fullyFunded Whether _ruling was fully funded after the call.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable override returns (bool fullyFunded) {
        DisputeStruct storage dispute = disputes[_localDisputeID];
        require(_ruling <= dispute.numberOfRulingOptions, "There is no such ruling to fund.");
        uint256 disputeIDOnArbitratorSide = dispute.disputeIDOnArbitratorSide;
        uint256 currentRuling = arbitrator.currentRuling(disputeIDOnArbitratorSide);

        checkAppealPeriod(dispute, _ruling, currentRuling);

        (uint256 originalCost, uint256 totalCost) = appealCost(dispute, _ruling, currentRuling);

        Round[] storage rounds = disputeIDtoRoundArray[_localDisputeID];
        uint256 roundsLength = rounds.length;
        Round storage lastRound = rounds[roundsLength - 1];
        require(!lastRound.hasPaid[_ruling], "Appeal fee has already been paid.");
        uint256 paidFeesInLastRound = lastRound.paidFees[_ruling];

        uint256 contribution = totalCost.subCap(paidFeesInLastRound) > msg.value ? msg.value : totalCost.subCap(paidFeesInLastRound);
        emit Contribution(_localDisputeID, roundsLength - 1, _ruling, msg.sender, contribution);

        lastRound.contributions[msg.sender][_ruling] += contribution;

        paidFeesInLastRound += contribution;
        lastRound.paidFees[_ruling] = paidFeesInLastRound;

        if (paidFeesInLastRound >= totalCost) {
            lastRound.feeRewards += paidFeesInLastRound;
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(_localDisputeID, roundsLength - 1, _ruling);
        }

        if (lastRound.fundedRulings.length > 1) {
            // At least two ruling options are fully funded.
            rounds.push();

            lastRound.feeRewards = lastRound.feeRewards.subCap(originalCost);
            arbitrator.appeal{value: originalCost}(disputeIDOnArbitratorSide, dispute.arbitratorExtraData);
        }

        msg.sender.transfer(msg.value.subCap(contribution)); // Sending extra value back to contributor.

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Retrieves appeal period for each ruling. It extends the function with the same name on the arbitrator by also requiring the _ruling parameter. This is because the arbitrable doesn't give losers of previous round as much time as the winner to avoid last-minute funding attacks.
     *  @param _dispute The dispute this function checks for appeal period.
     *  @param _ruling The ruling option which the caller wants to learn about its appeal period.
     */
    function checkAppealPeriod(
        DisputeStruct storage _dispute,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view {
        (uint256 originalStart, uint256 originalEnd) = arbitrator.appealPeriod(_dispute.disputeIDOnArbitratorSide);

        if (_ruling == _currentRuling) require(block.timestamp >= originalStart && block.timestamp < originalEnd, "Funding must be made within the appeal period.");
        else {
            require(
                block.timestamp >= originalStart && block.timestamp < (originalStart + ((originalEnd - originalStart) * loserAppealPeriodMultiplier) / MULTIPLIER_DIVISOR),
                "Funding must be made within the appeal period."
            );
        }
    }

    /** @dev Retrieves appeal cost for each ruling. It extends the function with the same name on the arbitrator side by adding
     *  _ruling parameter because total to be raised depends on multipliers.
     *  @param _dispute The dispute this function returns its appeal costs.
     *  @param _ruling The ruling option which the caller wants to learn about its appeal cost.
     */
    function appealCost(
        DisputeStruct storage _dispute,
        uint256 _ruling,
        uint256 _currentRuling
    ) internal view returns (uint256 originalCost, uint256 specificCost) {
        uint256 multiplier;

        if (_ruling == 0) multiplier = tieStakeMultiplier;
        else if (_ruling == _currentRuling) multiplier = winnerStakeMultiplier;
        else multiplier = loserStakeMultiplier;

        uint256 appealFee = arbitrator.appealCost(_dispute.disputeIDOnArbitratorSide, _dispute.arbitratorExtraData);
        return (appealFee, appealFee.addCap(appealFee.mulCap(multiplier) / MULTIPLIER_DIVISOR));
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling The ruling option that the caller wants to withdraw fees and rewards related to it.
     *  @return sum Reward amount that is to be withdrawn. Might be zero if arguments are not qualifying for a reward or reimbursement, or it might be withdrawn already.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override returns (uint256 sum) {
        DisputeStruct storage dispute = disputes[_localDisputeID];

        Round storage round = disputeIDtoRoundArray[_localDisputeID][_roundNumber];

        require(dispute.isRuled, "The dispute should be solved");

        if (!round.hasPaid[_ruling]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            sum += round.contributions[_contributor][_ruling];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == dispute.ruling) {
                // This ruling option is the ultimate winner.
                uint256 paidFees = round.paidFees[_ruling];
                sum += paidFees > 0 ? (round.contributions[_contributor][_ruling] * round.feeRewards) / paidFees : 0;
            } else if (!round.hasPaid[dispute.ruling]) {
                // This ruling option was not the ultimate winner, but the ultimate winner was not funded in this round. In this case funded ruling option(s) wins by default. Prize is distributed among contributors of funded ruling option(s).
                sum += (round.contributions[_contributor][_ruling] * round.feeRewards) / (round.paidFees[round.fundedRulings[0]] + round.paidFees[round.fundedRulings[1]]);
            }
        }

        round.contributions[_contributor][_ruling] = 0;
        if (sum != 0) {
            _contributor.send(sum); // User is responsible for accepting the reward.
            emit Withdrawal(_localDisputeID, _roundNumber, _ruling, _contributor, sum);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved for multiple ruling options at once.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256[] calldata _contributedTo
    ) public override {
        uint256 contributionArrayLength = _contributedTo.length;
        for (uint256 contributionNumber = 0; contributionNumber < contributionArrayLength; contributionNumber++) {
            withdrawFeesAndRewards(_localDisputeID, _contributor, _roundNumber, _contributedTo[contributionNumber]);
        }
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param _localDisputeID Index of the dispute in disputes array.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] calldata _contributedTo
    ) external override {
        uint256 noOfRounds = disputeIDtoRoundArray[_localDisputeID].length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewardsForMultipleRulings(_localDisputeID, _contributor, roundNumber, _contributedTo);
        }
    }

    /** @dev Returns the sum of withdrawable amount. Although it's a nested loop, total iterations will be almost always less than 10. (Max number of rounds is 7 and it's very unlikely to have a contributor to contribute to more than 1 ruling option per round). Alternatively you can use Contribution events to calculate this off-chain.
     *  @param _localDisputeID The ID of the associated question.
     *  @param _contributor The contributor for which to query.
     *  @param _contributedTo The array which includes ruling options to search for potential withdrawal. Caller can obtain this information using Contribution events.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] calldata _contributedTo
    ) public view override returns (uint256 sum) {
        uint256 noOfRounds = disputeIDtoRoundArray[_localDisputeID].length;
        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            for (uint256 contributionNumber = 0; contributionNumber < _contributedTo.length; contributionNumber++) {
                DisputeStruct storage dispute = disputes[_localDisputeID];

                Round storage round = disputeIDtoRoundArray[_localDisputeID][roundNumber];
                uint256 finalRuling = dispute.ruling;
                uint256 ruling = _contributedTo[contributionNumber];
                require(dispute.isRuled, "The dispute should be solved");

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
        return sum;
    }

    /** @dev To be called by the arbitrator of the dispute, to declare winning ruling.
     *  @param _externalDisputeID ID of the dispute in arbitrator contract.
     *  @param _ruling The ruling choice of the arbitration.
     */
    function rule(uint256 _externalDisputeID, uint256 _ruling) external override {
        uint256 _localDisputeID = externalIDtoLocalID[_externalDisputeID];
        DisputeStruct storage dispute = disputes[_localDisputeID];
        require(msg.sender == address(arbitrator), "Only the arbitrator can execute this.");
        require(_ruling <= dispute.numberOfRulingOptions, "Invalid ruling.");
        require(dispute.isRuled == false, "This dispute has been ruled already.");

        dispute.isRuled = true;
        dispute.ruling = _ruling;

        Round[] storage rounds = disputeIDtoRoundArray[_localDisputeID];
        Round storage lastRound = disputeIDtoRoundArray[_localDisputeID][rounds.length - 1];
        // If only one ruling option is funded, it wins by default. Note that if any other ruling had funded, an appeal would have been created.
        if (lastRound.fundedRulings.length == 1) {
            dispute.ruling = lastRound.fundedRulings[0];
        }

        emit Ruling(IArbitrator(msg.sender), _externalDisputeID, dispute.ruling);
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

    /** @dev Changes governor.
     *  @param _newGovernor The address of the new governor.
     */
    function setGovernor(address _newGovernor) external {
        require(msg.sender == governor, "Only the governor can execute this.");
        governor = _newGovernor;
    }

    /** @dev Changes the proportion of appeal fees that must be paid by winner.
     *  @param _winnerStakeMultiplier The new winner stake multiplier value respect to MULTIPLIER_DIVISOR.
     *  @param _loserStakeMultiplier The new loser stake multiplier value respect to MULTIPLIER_DIVISOR.
     *  @param _tieStakeMultiplier The tie stake multiplier value respect to MULTIPLIER_DIVISOR.
     *  @param _loserAppealPeriodMultiplier The new loser appeal period multiplier respect to MULTIPLIER_DIVISOR.
     */
    function changeMultipliers(
        uint256 _winnerStakeMultiplier,
        uint256 _loserStakeMultiplier,
        uint256 _tieStakeMultiplier,
        uint256 _loserAppealPeriodMultiplier
    ) external {
        require(msg.sender == governor, "Only the governor can execute this.");
        winnerStakeMultiplier = _winnerStakeMultiplier;
        loserStakeMultiplier = _loserStakeMultiplier;
        tieStakeMultiplier = _tieStakeMultiplier;
        loserAppealPeriodMultiplier = _loserAppealPeriodMultiplier;
    }

    /** @dev Returns stake multipliers.
     *  @return _winnerStakeMultiplier Winners stake multiplier.
     *  @return _loserStakeMultiplier Losers stake multiplier.
     *  @return _tieStakeMultiplier Stake multiplier in case of tie.
     *  @return _loserAppealPeriodMultiplier Multiplier for losers appeal period. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return divisor Multiplier divisor in basis points.
     */
    function getMultipliers()
        external
        view
        override
        returns (
            uint256 _winnerStakeMultiplier,
            uint256 _loserStakeMultiplier,
            uint256 _tieStakeMultiplier,
            uint256 _loserAppealPeriodMultiplier,
            uint256 divisor
        )
    {
        return (winnerStakeMultiplier, loserStakeMultiplier, tieStakeMultiplier, loserAppealPeriodMultiplier, MULTIPLIER_DIVISOR);
    }
}

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
 *  @title This is a common interface for apps to interact with disputes’ standard operations.
 *  Sets a standard arbitrable contract implementation to provide a general purpose user interface.
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "1.0.0";

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param localDisputeID The dispute id as in the arbitrable contract.
     *  @param round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param contributor Caller of fundAppeal function.
     *  @param amount Contribution amount.
     */
    event Contribution(uint256 indexed localDisputeID, uint256 indexed round, uint256 ruling, address indexed contributor, uint256 amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param localDisputeID The dispute id as in arbitrable contract.
     *  @param round The round number the withdrawal was made from.
     *  @param ruling Indicates the ruling option which contributor gets rewards from.
     *  @param contributor The beneficiary of withdrawal.
     *  @param reward Total amount of deposits reimbursed plus rewards. This amount will be sent to contributor as an effect of calling withdrawFeesAndRewards function.
     */
    event Withdrawal(uint256 indexed localDisputeID, uint256 indexed round, uint256 ruling, address indexed contributor, uint256 reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param localDisputeID The dispute id as in arbitrable contract.
     *  @param round Round code of the appeal. Starts from 0.
     *  @param ruling THe ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed localDisputeID, uint256 indexed round, uint256 indexed ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id. This is necessary to obtain local dispute data by arbitrators id.
     *  @param _externalDisputeID Dispute id as in arbitrator side.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 _externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 _localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(uint256 _localDisputeID, string calldata _evidenceURI) external virtual;

    /** @dev TRUSTED. Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
        Note that we don’t need to check that msg.value is enough to pay arbitration fees as it’s the responsibility of the arbitrator contract.
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _localDisputeID, uint256 _ruling) external payable virtual returns (bool fullyFunded);

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
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling A ruling option that the caller wants to withdraw fees and rewards related to it.
     *  @return sum The reward that is going to be paid as a result of this function call, if it's not zero.
     */
    function withdrawFeesAndRewards(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved. For multiple ruling options at once.
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256[] memory _contributedTo
    ) external virtual;

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _contributor The address to withdraw its rewards.
     *  @param _contributedTo Rulings that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param _localDisputeID Dispute id as in arbitrable contract.
     *  @param _contributor The contributor for which to query.
     *  @param _contributedTo Ruling options to look for potential withdrawals.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _localDisputeID,
        address payable _contributor,
        uint256[] memory _contributedTo
    ) public view virtual returns (uint256 sum);
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


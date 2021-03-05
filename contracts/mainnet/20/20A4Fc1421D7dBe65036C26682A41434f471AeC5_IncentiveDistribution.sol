// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./RoleAware.sol";
import "./Fund.sol";

struct Claim {
    uint256 startingRewardRateFP;
    address recipient;
    uint256 amount;
}

contract IncentiveDistribution is RoleAware, Ownable {
    // fixed point number factor
    uint256 constant FP32 = 2**32;
    // the amount of contraction per thousand, per day
    // of the overal daily incentive distribution
    uint256 constant contractionPerMil = 999;
    // the period for which claims are batch updated
    uint256 constant period = 4 hours;
    uint256 constant periodsPerDay = 24 hours / period;
    address MFI;

    constructor(
        address _MFI,
        uint256 startingDailyDistributionWithoutDecimals,
        address _roles
    ) RoleAware(_roles) Ownable() {
        MFI = _MFI;
        currentDailyDistribution =
            startingDailyDistributionWithoutDecimals *
            (1 ether);
        lastDailyDistributionUpdate = block.timestamp / (1 days);
    }

    // how much is going to be distributed, contracts every day
    uint256 public currentDailyDistribution;
    // last day on which we updated currentDailyDistribution
    uint256 lastDailyDistributionUpdate;
    // portion of daily distribution per each tranche
    mapping(uint8 => uint256) public trancheShare;
    uint256 public trancheShareTotal;

    // tranche => claim totals for the period we're currently aggregating
    mapping(uint8 => uint256) public currentPeriodTotals;
    // tranche => timestamp / period of last update
    mapping(uint8 => uint256) public lastUpdatedPeriods;

    // how each claim unit would get if they had staked from the dawn of time
    // expressed as fixed point number
    // claim amounts are expressed relative to this ongoing aggregate
    mapping(uint8 => uint256) public aggregatePeriodicRewardRateFP;
    // claim records
    mapping(uint256 => Claim) public claims;
    uint256 public nextClaimId = 1;

    function setTrancheShare(uint8 tranche, uint256 share) external onlyOwner {
        require(
            lastUpdatedPeriods[tranche] > 0,
            "Tranche is not initialized, please initialize first"
        );
        _setTrancheShare(tranche, share);
    }

    function _setTrancheShare(uint8 tranche, uint256 share) internal {
        if (share > trancheShare[tranche]) {
            trancheShareTotal += share - trancheShare[tranche];
        } else {
            trancheShareTotal -= trancheShare[tranche] - share;
        }
        trancheShare[tranche] = share;
    }

    function initTranche(
        uint8 tranche,
        uint256 share
    ) external onlyOwner {
        _setTrancheShare(tranche, share);

        lastUpdatedPeriods[tranche] = block.timestamp / period;
        // simply initialize to 1.0
        aggregatePeriodicRewardRateFP[tranche] = FP32;
    }

    function updatePeriodTotals(uint8 tranche) internal {
        uint256 currentPeriod = block.timestamp / period;

        // update the amount that gets distributed per day, if there has been
        // a day transition
        updateCurrentDailyDistribution();
        // Do a bunch of updating of periodic variables when the period changes
        uint256 lU = lastUpdatedPeriods[tranche];
        uint256 periodDiff = currentPeriod - lU;

        if (periodDiff > 0) {
            aggregatePeriodicRewardRateFP[tranche] +=
                currentPeriodicRewardRateFP(tranche) *
                periodDiff;
        }

        lastUpdatedPeriods[tranche] = currentPeriod;
    }

    function forcePeriodTotalUpdate(uint8 tranche) external {
        updatePeriodTotals(tranche);
    }

    function updateCurrentDailyDistribution() internal {
        uint256 nowDay = block.timestamp / (1 days);
        uint256 dayDiff = nowDay - lastDailyDistributionUpdate;

        // shrink the daily distribution for every day that has passed
        for (uint256 i = 0; i < dayDiff; i++) {
            currentDailyDistribution =
                (currentDailyDistribution * contractionPerMil) /
                1000;
        }
        // now update this memo
        lastDailyDistributionUpdate = nowDay;
    }

    function currentPeriodicRewardRateFP(uint8 tranche)
        internal
        view
        returns (uint256)
    {
        // scale daily distribution down to tranche share
        uint256 tranchePeriodDistributionFP =
            FP32 * currentDailyDistribution * trancheShare[tranche] / trancheShareTotal / periodsPerDay;

        // rate = (total_reward / total_claims) per period
        return
            tranchePeriodDistributionFP /
            currentPeriodTotals[tranche];
    }

    function startClaim(
        uint8 tranche,
        address recipient,
        uint256 claimAmount
    ) external returns (uint256) {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += claimAmount;

            claims[nextClaimId] = Claim({
                startingRewardRateFP: aggregatePeriodicRewardRateFP[tranche],
                recipient: recipient,
                amount: claimAmount
            });
            nextClaimId += 1;
            return nextClaimId - 1;
        } else {
            return 0;
        }
    }

    function addToClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 additionalAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += additionalAmount;

            Claim storage claim = claims[claimId];
            require(
                claim.startingRewardRateFP > 0,
                "Trying to add to non-existant claim"
            );
            _withdrawReward(tranche, claim);
            claim.amount += additionalAmount;
        }
    }

    function subtractFromClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 subtractAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);

        currentPeriodTotals[tranche] -= subtractAmount;

        Claim storage claim = claims[claimId];
        _withdrawReward((tranche), claim);
        claim.amount -= subtractAmount;
    }

    function endClaim(uint8 tranche, uint256 claimId) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];

        if (claim.startingRewardRateFP > 0) {
            _withdrawReward(tranche, claim);
            delete claim.recipient;
            delete claim.startingRewardRateFP;
            delete claim.amount;
        }
    }

    function calcRewardAmount(uint8 tranche, Claim storage claim)
        internal
        view
        returns (uint256)
    {
        return
            (claim.amount *
                (aggregatePeriodicRewardRateFP[tranche] -
                    claim.startingRewardRateFP)) / FP32;
    }

    function viewRewardAmount(uint8 tranche, uint256 claimId)
        external
        view
        returns (uint256)
    {
        return calcRewardAmount(tranche, claims[claimId]);
    }

    function withdrawReward(uint8 tranche, uint256 claimId)
        external
        returns (uint256)
    {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];
        return _withdrawReward(tranche, claim);
    }

    function _withdrawReward(uint8 tranche, Claim storage claim)
        internal
        returns (uint256 rewardAmount)
    {
        rewardAmount = calcRewardAmount(tranche, claim);

        require(
            Fund(fund()).withdraw(MFI, claim.recipient, rewardAmount),
            "There seems to be a lack of MFI in the incentive fund!"
        );

        claim.startingRewardRateFP = aggregatePeriodicRewardRateFP[tranche];
    }
}
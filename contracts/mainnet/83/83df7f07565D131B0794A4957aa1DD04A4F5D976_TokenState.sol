// SPDX-License-Identifier: AGPL-3.0-only

/*
    Bounty.sol - SKALE Manager
    Copyright (C) 2020-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./delegation/DelegationController.sol";
import "./delegation/PartialDifferences.sol";
import "./delegation/TimeHelpers.sol";
import "./delegation/ValidatorService.sol";

import "./ConstantsHolder.sol";
import "./Nodes.sol";
import "./Permissions.sol";


contract BountyV2 is Permissions {
    using PartialDifferences for PartialDifferences.Value;
    using PartialDifferences for PartialDifferences.Sequence;

    struct BountyHistory {
        uint month;
        uint bountyPaid;
    }
    
    uint public constant YEAR1_BOUNTY = 3850e5 * 1e18;
    uint public constant YEAR2_BOUNTY = 3465e5 * 1e18;
    uint public constant YEAR3_BOUNTY = 3080e5 * 1e18;
    uint public constant YEAR4_BOUNTY = 2695e5 * 1e18;
    uint public constant YEAR5_BOUNTY = 2310e5 * 1e18;
    uint public constant YEAR6_BOUNTY = 1925e5 * 1e18;
    uint public constant EPOCHS_PER_YEAR = 12;
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant BOUNTY_WINDOW_SECONDS = 3 * SECONDS_PER_DAY;
    
    uint private _nextEpoch;
    uint private _epochPool;
    uint private _bountyWasPaidInCurrentEpoch;
    bool public bountyReduction;
    uint public nodeCreationWindowSeconds;

    PartialDifferences.Value private _effectiveDelegatedSum;
    // validatorId   amount of nodes
    mapping (uint => uint) public nodesByValidator; // deprecated

    // validatorId => BountyHistory
    mapping (uint => BountyHistory) private _bountyHistory;

    function calculateBounty(uint nodeIndex)
        external
        allow("SkaleManager")
        returns (uint)
    {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController")
        );
        
        require(
            _getNextRewardTimestamp(nodeIndex, nodes, timeHelpers) <= now,
            "Transaction is sent too early"
        );

        uint validatorId = nodes.getValidatorId(nodeIndex);
        if (nodesByValidator[validatorId] > 0) {
            delete nodesByValidator[validatorId];
        }

        uint currentMonth = timeHelpers.getCurrentMonth();
        _refillEpochPool(currentMonth, timeHelpers, constantsHolder);
        _prepareBountyHistory(validatorId, currentMonth);

        uint bounty = _calculateMaximumBountyAmount(
            _epochPool,
            _effectiveDelegatedSum.getAndUpdateValue(currentMonth),
            _bountyWasPaidInCurrentEpoch,
            nodeIndex,
            _bountyHistory[validatorId].bountyPaid,
            delegationController.getAndUpdateEffectiveDelegatedToValidator(validatorId, currentMonth),
            delegationController.getAndUpdateDelegatedToValidatorNow(validatorId),
            constantsHolder,
            nodes
        );
        _bountyHistory[validatorId].bountyPaid = _bountyHistory[validatorId].bountyPaid.add(bounty);

        bounty = _reduceBounty(
            bounty,
            nodeIndex,
            nodes,
            constantsHolder
        );
        
        _epochPool = _epochPool.sub(bounty);
        _bountyWasPaidInCurrentEpoch = _bountyWasPaidInCurrentEpoch.add(bounty);

        return bounty;
    }

    function enableBountyReduction() external onlyOwner {
        bountyReduction = true;
    }

    function disableBountyReduction() external onlyOwner {
        bountyReduction = false;
    }

    function setNodeCreationWindowSeconds(uint window) external allow("Nodes") {
        nodeCreationWindowSeconds = window;
    }

    function handleDelegationAdd(
        uint amount,
        uint month
    )
        external
        allow("DelegationController")
    {
        _effectiveDelegatedSum.addToValue(amount, month);
    }

    function handleDelegationRemoving(
        uint amount,
        uint month
    )
        external
        allow("DelegationController")
    {
        _effectiveDelegatedSum.subtractFromValue(amount, month);
    }

    function populate() external onlyOwner {
        ValidatorService validatorService = ValidatorService(contractManager.getValidatorService());
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController")
        );
        TimeHelpers timeHelpers = TimeHelpers(contractManager.getTimeHelpers());

        uint currentMonth = timeHelpers.getCurrentMonth();

        // clean existing data
        for (
            uint i = _effectiveDelegatedSum.firstUnprocessedMonth;
            i < _effectiveDelegatedSum.lastChangedMonth.add(1);
            ++i
        )
        {
            delete _effectiveDelegatedSum.addDiff[i];
            delete _effectiveDelegatedSum.subtractDiff[i];
        }
        delete _effectiveDelegatedSum.value;
        delete _effectiveDelegatedSum.lastChangedMonth;
        _effectiveDelegatedSum.firstUnprocessedMonth = currentMonth;
        
        uint[] memory validators = validatorService.getTrustedValidators();
        for (uint i = 0; i < validators.length; ++i) {
            uint validatorId = validators[i];
            uint currentEffectiveDelegated =
                delegationController.getAndUpdateEffectiveDelegatedToValidator(validatorId, currentMonth);
            uint[] memory effectiveDelegated = delegationController.getEffectiveDelegatedValuesByValidator(validatorId);
            if (effectiveDelegated.length > 0) {
                assert(currentEffectiveDelegated == effectiveDelegated[0]);
            }
            uint added = 0;
            for (uint j = 0; j < effectiveDelegated.length; ++j) {
                if (effectiveDelegated[j] != added) {
                    if (effectiveDelegated[j] > added) {
                        _effectiveDelegatedSum.addToValue(effectiveDelegated[j].sub(added), currentMonth + j);
                    } else {
                        _effectiveDelegatedSum.subtractFromValue(added.sub(effectiveDelegated[j]), currentMonth + j);
                    }
                    added = effectiveDelegated[j];
                }
            }
            delete effectiveDelegated;
        }
    }

    function estimateBounty(uint nodeIndex) external view returns (uint) {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));
        DelegationController delegationController = DelegationController(
            contractManager.getContract("DelegationController")
        );

        uint currentMonth = timeHelpers.getCurrentMonth();
        uint validatorId = nodes.getValidatorId(nodeIndex);

        uint stagePoolSize;
        (stagePoolSize, ) = _getEpochPool(currentMonth, timeHelpers, constantsHolder);

        return _calculateMaximumBountyAmount(
            stagePoolSize,
            _effectiveDelegatedSum.getValue(currentMonth),
            _nextEpoch == currentMonth.add(1) ? _bountyWasPaidInCurrentEpoch : 0,
            nodeIndex,
            _getBountyPaid(validatorId, currentMonth),
            delegationController.getEffectiveDelegatedToValidator(validatorId, currentMonth),
            delegationController.getDelegatedToValidator(validatorId, currentMonth),
            constantsHolder,
            nodes
        );
    }

    function getNextRewardTimestamp(uint nodeIndex) external view returns (uint) {
        return _getNextRewardTimestamp(
            nodeIndex,
            Nodes(contractManager.getContract("Nodes")),
            TimeHelpers(contractManager.getContract("TimeHelpers"))
        );
    }

    function getEffectiveDelegatedSum() external view returns (uint[] memory) {
        return _effectiveDelegatedSum.getValues();
    }

    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
        _nextEpoch = 0;
        _epochPool = 0;
        _bountyWasPaidInCurrentEpoch = 0;
        bountyReduction = false;
        nodeCreationWindowSeconds = 3 * SECONDS_PER_DAY;
    }

    // private

    function _calculateMaximumBountyAmount(
        uint epochPoolSize,
        uint effectiveDelegatedSum,
        uint bountyWasPaidInCurrentEpoch,
        uint nodeIndex,
        uint bountyPaidToTheValidator,
        uint effectiveDelegated,
        uint delegated,
        ConstantsHolder constantsHolder,
        Nodes nodes
    )
        private
        view
        returns (uint)
    {
        if (nodes.isNodeLeft(nodeIndex)) {
            return 0;
        }

        if (now < constantsHolder.launchTimestamp()) {
            // network is not launched
            // bounty is turned off
            return 0;
        }
        
        if (effectiveDelegatedSum == 0) {
            // no delegations in the system
            return 0;
        }

        if (constantsHolder.msr() == 0) {
            return 0;
        }

        uint bounty = _calculateBountyShare(
            epochPoolSize.add(bountyWasPaidInCurrentEpoch),
            effectiveDelegated,
            effectiveDelegatedSum,
            delegated.div(constantsHolder.msr()),
            bountyPaidToTheValidator
        );

        return bounty;
    }

    function _calculateBountyShare(
        uint monthBounty,
        uint effectiveDelegated,
        uint effectiveDelegatedSum,
        uint maxNodesAmount,
        uint paidToValidator
    )
        private
        pure
        returns (uint)
    {
        if (maxNodesAmount > 0) {
            uint totalBountyShare = monthBounty
                .mul(effectiveDelegated)
                .div(effectiveDelegatedSum);
            return _min(
                totalBountyShare.div(maxNodesAmount),
                totalBountyShare.sub(paidToValidator)
            );
        } else {
            return 0;
        }
    }

    function _getFirstEpoch(TimeHelpers timeHelpers, ConstantsHolder constantsHolder) private view returns (uint) {
        return timeHelpers.timestampToMonth(constantsHolder.launchTimestamp());
    }

    function _getEpochPool(
        uint currentMonth,
        TimeHelpers timeHelpers,
        ConstantsHolder constantsHolder
    )
        private
        view
        returns (uint epochPool, uint nextEpoch)
    {
        epochPool = _epochPool;
        for (nextEpoch = _nextEpoch; nextEpoch <= currentMonth; ++nextEpoch) {
            epochPool = epochPool.add(_getEpochReward(nextEpoch, timeHelpers, constantsHolder));
        }
    }

    function _refillEpochPool(uint currentMonth, TimeHelpers timeHelpers, ConstantsHolder constantsHolder) private {
        uint epochPool;
        uint nextEpoch;
        (epochPool, nextEpoch) = _getEpochPool(currentMonth, timeHelpers, constantsHolder);
        if (_nextEpoch < nextEpoch) {
            (_epochPool, _nextEpoch) = (epochPool, nextEpoch);
            _bountyWasPaidInCurrentEpoch = 0;
        }
    }

    function _getEpochReward(
        uint epoch,
        TimeHelpers timeHelpers,
        ConstantsHolder constantsHolder
    )
        private
        view
        returns (uint)
    {
        uint firstEpoch = _getFirstEpoch(timeHelpers, constantsHolder);
        if (epoch < firstEpoch) {
            return 0;
        }
        uint epochIndex = epoch.sub(firstEpoch);
        uint year = epochIndex.div(EPOCHS_PER_YEAR);
        if (year >= 6) {
            uint power = year.sub(6).div(3).add(1);
            if (power < 256) {
                return YEAR6_BOUNTY.div(2 ** power).div(EPOCHS_PER_YEAR);
            } else {
                return 0;
            }
        } else {
            uint[6] memory customBounties = [
                YEAR1_BOUNTY,
                YEAR2_BOUNTY,
                YEAR3_BOUNTY,
                YEAR4_BOUNTY,
                YEAR5_BOUNTY,
                YEAR6_BOUNTY
            ];
            return customBounties[year].div(EPOCHS_PER_YEAR);
        }
    }

    function _reduceBounty(
        uint bounty,
        uint nodeIndex,
        Nodes nodes,
        ConstantsHolder constants
    )
        private
        returns (uint reducedBounty)
    {
        if (!bountyReduction) {
            return bounty;
        }

        reducedBounty = bounty;

        if (!nodes.checkPossibilityToMaintainNode(nodes.getValidatorId(nodeIndex), nodeIndex)) {
            reducedBounty = reducedBounty.div(constants.MSR_REDUCING_COEFFICIENT());
        }
    }

    function _prepareBountyHistory(uint validatorId, uint currentMonth) private {
        if (_bountyHistory[validatorId].month < currentMonth) {
            _bountyHistory[validatorId].month = currentMonth;
            delete _bountyHistory[validatorId].bountyPaid;
        }
    }

    function _getBountyPaid(uint validatorId, uint month) private view returns (uint) {
        require(_bountyHistory[validatorId].month <= month, "Can't get bounty paid");
        if (_bountyHistory[validatorId].month == month) {
            return _bountyHistory[validatorId].bountyPaid;
        } else {
            return 0;
        }
    }

    function _getNextRewardTimestamp(uint nodeIndex, Nodes nodes, TimeHelpers timeHelpers) private view returns (uint) {
        uint lastRewardTimestamp = nodes.getNodeLastRewardDate(nodeIndex);
        uint lastRewardMonth = timeHelpers.timestampToMonth(lastRewardTimestamp);
        uint lastRewardMonthStart = timeHelpers.monthToTimestamp(lastRewardMonth);
        uint timePassedAfterMonthStart = lastRewardTimestamp.sub(lastRewardMonthStart);
        uint currentMonth = timeHelpers.getCurrentMonth();
        assert(lastRewardMonth <= currentMonth);

        if (lastRewardMonth == currentMonth) {
            uint nextMonthStart = timeHelpers.monthToTimestamp(currentMonth.add(1));
            uint nextMonthFinish = timeHelpers.monthToTimestamp(lastRewardMonth.add(2));
            if (lastRewardTimestamp < lastRewardMonthStart.add(nodeCreationWindowSeconds)) {
                return nextMonthStart.sub(BOUNTY_WINDOW_SECONDS);
            } else {
                return _min(nextMonthStart.add(timePassedAfterMonthStart), nextMonthFinish.sub(BOUNTY_WINDOW_SECONDS));
            }
        } else if (lastRewardMonth.add(1) == currentMonth) {
            uint currentMonthStart = timeHelpers.monthToTimestamp(currentMonth);
            uint currentMonthFinish = timeHelpers.monthToTimestamp(currentMonth.add(1));
            return _min(
                currentMonthStart.add(_max(timePassedAfterMonthStart, nodeCreationWindowSeconds)),
                currentMonthFinish.sub(BOUNTY_WINDOW_SECONDS)
            );
        } else {
            uint currentMonthStart = timeHelpers.monthToTimestamp(currentMonth);
            return currentMonthStart.add(nodeCreationWindowSeconds);
        }
    }

    function _min(uint a, uint b) private pure returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function _max(uint a, uint b) private pure returns (uint) {
        if (a < b) {
            return b;
        } else {
            return a;
        }
    }
}
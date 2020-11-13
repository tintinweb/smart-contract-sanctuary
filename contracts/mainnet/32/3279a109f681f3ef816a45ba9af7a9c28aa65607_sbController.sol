// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./sbStrongValuePoolInterface.sol";

contract sbController {
    using SafeMath for uint256;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public parameterAdmin;

    IERC20 public strongToken;
    sbStrongValuePoolInterface public sbStrongValuePool;
    address public sbVotes;

    address[] public valuePools;
    mapping(address => bool) public valuePoolAccepted;
    mapping(address => uint256[]) public valuePoolDays;
    mapping(address => uint256[]) public valuePoolWeights;
    mapping(address => uint256) public valuePoolVestingDays;
    mapping(address => uint256) public valuePoolMiningFeeNumerator;
    mapping(address => uint256) public valuePoolMiningFeeDenominator;
    mapping(address => uint256) public valuePoolUnminingFeeNumerator;
    mapping(address => uint256) public valuePoolUnminingFeeDenominator;
    mapping(address => uint256) public valuePoolClaimingFeeNumerator;
    mapping(address => uint256) public valuePoolClaimingFeeDenominator;

    address[] public servicePools;
    mapping(address => bool) public servicePoolAccepted;
    mapping(address => uint256[]) public servicePoolDays;
    mapping(address => uint256[]) public servicePoolWeights;
    mapping(address => uint256) public servicePoolVestingDays;
    mapping(address => uint256) public servicePoolRequestFeeInWei;
    mapping(address => uint256) public servicePoolClaimingFeeNumerator;
    mapping(address => uint256) public servicePoolClaimingFeeDenominator;

    uint256 public voteCasterVestingDays;
    uint256 public voteReceiverVestingDays;

    uint256[] public rewardDays;
    uint256[] public rewardAmounts;

    uint256[] public valuePoolsDays;
    uint256[] public valuePoolsWeights;

    uint256[] public servicePoolsDays;
    uint256[] public servicePoolsWeights;

    uint256[] public voteCastersDays;
    uint256[] public voteCastersWeights;

    uint256[] public voteReceiversDays;
    uint256[] public voteReceiversWeights;

    uint256 public voteForServicePoolsCount;
    uint256 public voteForServicesCount;

    uint256 public minerMinMineDays;
    uint256 public minerMinMineAmountInWei;

    uint256 public serviceMinMineDays;
    uint256 public serviceMinMineAmountInWei;

    function init(
        address strongTokenAddress,
        address sbStrongValuePoolAddress,
        address sbVotesAddress,
        address adminAddress,
        address superAdminAddress,
        address parameterAdminAddress
    ) public {
        require(!initDone);
        strongToken = IERC20(strongTokenAddress);
        sbStrongValuePool = sbStrongValuePoolInterface(
            sbStrongValuePoolAddress
        );
        sbVotes = sbVotesAddress;
        admin = adminAddress;
        superAdmin = superAdminAddress;
        parameterAdmin = parameterAdminAddress;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function removeTokens(address account, uint256 amount) public {
        require(msg.sender == superAdmin, "not superAdmin");
        strongToken.transfer(account, amount);
    }

    function updateParameterAdmin(address newParameterAdmin) public {
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin);
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0));
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin);
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0));
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // VESTING
    // *************************************************************************************
    function getValuePoolVestingDays(address valuePool)
        public
        view
        returns (uint256)
    {
        require(valuePoolAccepted[valuePool]);
        return valuePoolVestingDays[valuePool];
    }

    function getServicePoolVestingDays(address servicePool)
        public
        view
        returns (uint256)
    {
        require(servicePoolAccepted[servicePool]);
        return servicePoolVestingDays[servicePool];
    }

    function getVoteCasterVestingDays() public view returns (uint256) {
        return voteCasterVestingDays;
    }

    function getVoteReceiverVestingDays() public view returns (uint256) {
        return voteReceiverVestingDays;
    }

    function updateVoteCasterVestingDays(uint256 vestingDayCount)
        public
        returns (uint256)
    {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(vestingDayCount >= 1);
        voteCasterVestingDays = vestingDayCount;
    }

    function updateVoteReceiverVestingDays(uint256 vestingDayCount)
        public
        returns (uint256)
    {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(vestingDayCount >= 1);
        voteReceiverVestingDays = vestingDayCount;
    }

    function updateValuePoolVestingDays(
        address valuePool,
        uint256 vestingDayCount
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(valuePoolAccepted[valuePool]);
        require(vestingDayCount >= 1);
        valuePoolVestingDays[valuePool] = vestingDayCount;
    }

    function updateServicePoolVestingDays(
        address servicePool,
        uint256 vestingDayCount
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(servicePoolAccepted[servicePool]);
        require(vestingDayCount >= 1);
        servicePoolVestingDays[servicePool] = vestingDayCount;
    }

    // MIN MINING
    // *************************************************************************************
    function getMinerMinMineDays() public view returns (uint256) {
        return minerMinMineDays;
    }

    function getServiceMinMineDays() public view returns (uint256) {
        return serviceMinMineDays;
    }

    function getMinerMinMineAmountInWei() public view returns (uint256) {
        return minerMinMineAmountInWei;
    }

    function getServiceMinMineAmountInWei() public view returns (uint256) {
        return serviceMinMineAmountInWei;
    }

    function updateMinerMinMineDays(uint256 dayCount) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        minerMinMineDays = dayCount;
    }

    function updateServiceMinMineDays(uint256 dayCount) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        serviceMinMineDays = dayCount;
    }

    function updateMinerMinMineAmountInWei(uint256 amountInWei) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        minerMinMineAmountInWei = amountInWei;
    }

    function updateServiceMinMineAmountInWei(uint256 amountInWei) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        serviceMinMineAmountInWei = amountInWei;
    }

    // WEIGHTS
    // *************************************************************************************
    function getValuePoolsWeight(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 weight) = _get(valuePoolsDays, valuePoolsWeights, day);
        return weight;
    }

    function getValuePoolWeight(address valuePool, uint256 dayNumber)
        public
        view
        returns (uint256, uint256)
    {
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _get(valuePoolDays[valuePool], valuePoolWeights[valuePool], day);
    }

    function getServicePoolsWeight(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 weight) = _get(servicePoolsDays, servicePoolsWeights, day);
        return weight;
    }

    function getServicePoolWeight(address servicePool, uint256 dayNumber)
        public
        view
        returns (uint256, uint256)
    {
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return
            _get(
                servicePoolDays[servicePool],
                servicePoolWeights[servicePool],
                day
            );
    }

    function getVoteCastersWeight(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 weight) = _get(voteCastersDays, voteCastersWeights, day);
        return weight;
    }

    function getVoteReceiversWeight(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 weight) = _get(voteReceiversDays, voteReceiversWeights, day);
        return weight;
    }

    function getValuePoolsSumWeights(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getValuePoolsSumWeights(day);
    }

    function getServicePoolsSumWeights(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getServicePoolsSumWeights(day);
    }

    function getSumWeights(uint256 dayNumber) public view returns (uint256) {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getSumWeights(day);
    }

    function updateValuePoolsWeight(uint256 weight, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        _updateWeight(valuePoolsDays, valuePoolsWeights, day, weight);
    }

    function updateServicePoolsWeight(uint256 weight, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        _updateWeight(servicePoolsDays, servicePoolsWeights, day, weight);
    }

    function updateValuePoolWeight(
        address valuePool,
        uint256 weight,
        uint256 day
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        _updateWeight(
            valuePoolDays[valuePool],
            valuePoolWeights[valuePool],
            day,
            weight
        );
    }

    function updateServicePoolWeight(
        address servicePool,
        uint256 weight,
        uint256 day
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        _updateWeight(
            servicePoolDays[servicePool],
            servicePoolWeights[servicePool],
            day,
            weight
        );
    }

    function updateVoteCastersWeight(uint256 weight, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        _updateWeight(voteCastersDays, voteCastersWeights, day, weight);
    }

    function updateVoteReceiversWeight(uint256 weight, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        _updateWeight(voteReceiversDays, voteReceiversWeights, day, weight);
    }

    // FEES
    // *************************************************************************************
    function getValuePoolMiningFee(address valuePool)
        public
        view
        returns (uint256, uint256)
    {
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        return (
            valuePoolMiningFeeNumerator[valuePool],
            valuePoolMiningFeeDenominator[valuePool]
        );
    }

    function getValuePoolUnminingFee(address valuePool)
        public
        view
        returns (uint256, uint256)
    {
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        return (
            valuePoolUnminingFeeNumerator[valuePool],
            valuePoolUnminingFeeDenominator[valuePool]
        );
    }

    function getValuePoolClaimingFee(address valuePool)
        public
        view
        returns (uint256, uint256)
    {
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        return (
            valuePoolClaimingFeeNumerator[valuePool],
            valuePoolClaimingFeeDenominator[valuePool]
        );
    }

    function updateValuePoolMiningFee(
        address valuePool,
        uint256 numerator,
        uint256 denominator
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        require(denominator != 0, "invalid value");
        valuePoolMiningFeeNumerator[valuePool] = numerator;
        valuePoolMiningFeeDenominator[valuePool] = denominator;
    }

    function updateValuePoolUnminingFee(
        address valuePool,
        uint256 numerator,
        uint256 denominator
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        require(denominator != 0, "invalid value");
        valuePoolUnminingFeeNumerator[valuePool] = numerator;
        valuePoolUnminingFeeDenominator[valuePool] = denominator;
    }

    function updateValuePoolClaimingFee(
        address valuePool,
        uint256 numerator,
        uint256 denominator
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        require(denominator != 0, "invalid value");
        valuePoolClaimingFeeNumerator[valuePool] = numerator;
        valuePoolClaimingFeeDenominator[valuePool] = denominator;
    }

    function getServicePoolRequestFeeInWei(address servicePool)
        public
        view
        returns (uint256)
    {
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        return servicePoolRequestFeeInWei[servicePool];
    }

    function getServicePoolClaimingFee(address servicePool)
        public
        view
        returns (uint256, uint256)
    {
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        return (
            servicePoolClaimingFeeNumerator[servicePool],
            servicePoolClaimingFeeDenominator[servicePool]
        );
    }

    function updateServicePoolRequestFeeInWei(
        address servicePool,
        uint256 feeInWei
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        servicePoolRequestFeeInWei[servicePool] = feeInWei;
    }

    function updateServicePoolClaimingFee(
        address servicePool,
        uint256 numerator,
        uint256 denominator
    ) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        require(denominator != 0, "invalid value");
        servicePoolClaimingFeeNumerator[servicePool] = numerator;
        servicePoolClaimingFeeDenominator[servicePool] = denominator;
    }

    // REWARDS
    // *************************************************************************************
    function getRewards(uint256 dayNumber) public view returns (uint256) {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 rewards) = _get(rewardDays, rewardAmounts, day);
        return rewards;
    }

    function getValuePoolsRewards(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 reward) = _get(rewardDays, rewardAmounts, day);
        uint256 weight = getValuePoolsWeight(day);
        uint256 sumWeight = _getSumWeights(day);
        return sumWeight == 0 ? 0 : reward.mul(weight).div(sumWeight);
    }

    function getServicePoolsRewards(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 reward) = _get(rewardDays, rewardAmounts, day);
        uint256 weight = getServicePoolsWeight(day);
        uint256 sumWeight = _getSumWeights(day);
        return sumWeight == 0 ? 0 : reward.mul(weight).div(sumWeight);
    }

    function getVoteCastersRewards(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 reward) = _get(rewardDays, rewardAmounts, day);
        uint256 weight = getVoteCastersWeight(day);
        uint256 sumWeight = _getSumWeights(day);
        return sumWeight == 0 ? 0 : reward.mul(weight).div(sumWeight);
    }

    function getVoteReceiversRewards(uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        (, uint256 reward) = _get(rewardDays, rewardAmounts, day);
        uint256 weight = getVoteReceiversWeight(day);
        uint256 sumWeight = _getSumWeights(day);
        return sumWeight == 0 ? 0 : reward.mul(weight).div(sumWeight);
    }

    function getValuePoolRewards(address valuePool, uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        require(valuePoolAccepted[valuePool], "invalid valuePool");
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        uint256 reward = getValuePoolsRewards(day);
        (, uint256 weight) = _get(
            valuePoolDays[valuePool],
            valuePoolWeights[valuePool],
            day
        );
        uint256 sumWeights = _getValuePoolsSumWeights(day);
        return sumWeights == 0 ? 0 : reward.mul(weight).div(sumWeights);
    }

    function getServicePoolRewards(address servicePool, uint256 dayNumber)
        public
        view
        returns (uint256)
    {
        require(servicePoolAccepted[servicePool], "invalid servicePool");
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        uint256 reward = getServicePoolsRewards(day);
        (, uint256 weight) = _get(
            servicePoolDays[servicePool],
            servicePoolWeights[servicePool],
            day
        );
        uint256 sumWeights = _getServicePoolsSumWeights(day);
        return sumWeights == 0 ? 0 : reward.mul(weight).div(sumWeights);
    }

    function addReward(uint256 amount, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        if (rewardDays.length == 0) {
            require(day == _getCurrentDay(), "1: invalid day");
        } else {
            uint256 lastIndex = rewardDays.length.sub(1);
            uint256 lastDay = rewardDays[lastIndex];
            require(day != lastDay, "2: invalid day");
            require(day >= _getCurrentDay(), "3: invalid day");
        }
        rewardDays.push(day);
        rewardAmounts.push(amount);
    }

    function updateReward(uint256 amount, uint256 day) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        require(rewardDays.length != 0, "zero");
        require(day >= _getCurrentDay(), "1: invalid day");
        (bool found, uint256 index) = _findIndex(rewardDays, day);
        require(found, "2: invalid day");
        rewardAmounts[index] = amount;
    }

    function requestRewards(address miner, uint256 amount) public {
        require(
            valuePoolAccepted[msg.sender] ||
                servicePoolAccepted[msg.sender] ||
                msg.sender == sbVotes,
            "invalid caller"
        );
        strongToken.approve(address(sbStrongValuePool), amount);
        sbStrongValuePool.mineFor(miner, amount);
    }

    // VALUE POOLS
    // *************************************************************************************
    function isValuePoolAccepted(address valuePool) public view returns (bool) {
        return valuePoolAccepted[valuePool];
    }

    function getValuePools() public view returns (address[] memory) {
        return valuePools;
    }

    function addValuePool(address valuePool) public {
        require(msg.sender == admin || msg.sender == superAdmin);
        require(!valuePoolAccepted[valuePool], "exists");
        valuePoolAccepted[valuePool] = true;
        valuePools.push(valuePool);
    }

    // SERVICE POOLS
    // *************************************************************************************
    function isServicePoolAccepted(address servicePool)
        public
        view
        returns (bool)
    {
        return servicePoolAccepted[servicePool];
    }

    function getServicePools() public view returns (address[] memory) {
        return servicePools;
    }

    function addServicePool(address servicePool) public {
        require(msg.sender == admin || msg.sender == superAdmin);
        require(!servicePoolAccepted[servicePool], "exists");
        servicePoolAccepted[servicePool] = true;
        servicePools.push(servicePool);
    }

    // VOTES
    // *************************************************************************************
    function getVoteForServicePoolsCount() public view returns (uint256) {
        return voteForServicePoolsCount;
    }

    function getVoteForServicesCount() public view returns (uint256) {
        return voteForServicesCount;
    }

    function updateVoteForServicePoolsCount(uint256 count) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        voteForServicePoolsCount = count;
    }

    function updateVoteForServicesCount(uint256 count) public {
        require(
            msg.sender == admin ||
                msg.sender == parameterAdmin ||
                msg.sender == superAdmin
        );
        voteForServicesCount = count;
    }

    // SUPPORT
    // *************************************************************************************
    function getCurrentDay() public view returns (uint256) {
        return _getCurrentDay();
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }

    function _getValuePoolsSumWeights(uint256 day)
        internal
        view
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < valuePools.length; i++) {
            address valuePool = valuePools[i];
            (, uint256 weight) = _get(
                valuePoolDays[valuePool],
                valuePoolWeights[valuePool],
                day
            );
            sum = sum.add(weight);
        }
        return sum;
    }

    function _getServicePoolsSumWeights(uint256 day)
        internal
        view
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < servicePools.length; i++) {
            address servicePool = servicePools[i];
            (, uint256 weight) = _get(
                servicePoolDays[servicePool],
                servicePoolWeights[servicePool],
                day
            );
            sum = sum.add(weight);
        }
        return sum;
    }

    function _getSumWeights(uint256 day) internal view returns (uint256) {
        (, uint256 vpWeight) = _get(valuePoolsDays, valuePoolsWeights, day);
        (, uint256 spWeight) = _get(servicePoolsDays, servicePoolsWeights, day);
        (, uint256 vcWeight) = _get(voteCastersDays, voteCastersWeights, day);
        (, uint256 vrWeight) = _get(
            voteReceiversDays,
            voteReceiversWeights,
            day
        );
        return vpWeight.add(spWeight).add(vcWeight).add(vrWeight);
    }

    function _get(
        uint256[] memory _Days,
        uint256[] memory _Units,
        uint256 day
    ) internal pure returns (uint256, uint256) {
        uint256 len = _Days.length;
        if (len == 0) {
            return (day, 0);
        }
        if (day < _Days[0]) {
            return (day, 0);
        }
        uint256 lastIndex = len.sub(1);
        uint256 lastDay = _Days[lastIndex];
        if (day >= lastDay) {
            return (day, _Units[lastIndex]);
        }
        return _find(_Days, _Units, day);
    }

    function _find(
        uint256[] memory _Days,
        uint256[] memory _Units,
        uint256 day
    ) internal pure returns (uint256, uint256) {
        uint256 left = 0;
        uint256 right = _Days.length.sub(1);
        uint256 middle = right.add(left).div(2);
        while (left < right) {
            if (_Days[middle] == day) {
                return (day, _Units[middle]);
            } else if (_Days[middle] > day) {
                if (middle > 0 && _Days[middle.sub(1)] < day) {
                    return (day, _Units[middle.sub(1)]);
                }
                if (middle == 0) {
                    return (day, 0);
                }
                right = middle.sub(1);
            } else if (_Days[middle] < day) {
                if (
                    middle < _Days.length.sub(1) && _Days[middle.add(1)] > day
                ) {
                    return (day, _Units[middle]);
                }
                left = middle.add(1);
            }
            middle = right.add(left).div(2);
        }
        if (_Days[middle] != day) {
            return (day, 0);
        } else {
            return (day, _Units[middle]);
        }
    }

    function _findIndex(uint256[] memory _Array, uint256 element)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 left = 0;
        uint256 right = _Array.length.sub(1);
        while (left <= right) {
            uint256 middle = right.add(left).div(2);
            if (_Array[middle] == element) {
                return (true, middle);
            } else if (_Array[middle] > element) {
                right = middle.sub(1);
            } else if (_Array[middle] < element) {
                left = middle.add(1);
            }
        }
        return (false, 0);
    }

    function _updateWeight(
        uint256[] storage _Days,
        uint256[] storage _Weights,
        uint256 day,
        uint256 weight
    ) internal {
        uint256 currentDay = _getCurrentDay();
        if (_Days.length == 0) {
            require(day == currentDay, "1: invalid day");
            _Days.push(day);
            _Weights.push(weight);
        } else {
            require(day >= currentDay, "2: invalid day");
            (bool found, uint256 index) = _findIndex(_Days, day);
            if (found) {
                _Weights[index] = weight;
            } else {
                _Days.push(day);
                _Weights.push(weight);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////// RPEPEBLU, RPEPE.LPURPLE Staking Rewards Contract - KEK Rewards //////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";

interface IKEK {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(address account, uint256 amount) external;
}

interface IFARMINGPOOL {
    function getTotalStakedAmount() external view returns (uint256);
    function getStakedAmount(address account) external view returns (uint256);
    function getStakers() external view returns (address[] memory);
}

contract StakingReward is Context {
    using SafeMath for uint256;
    
    // Events
    event ClaimedReward(address account, uint256 amount);
    
    // states
    struct Gains {
        uint256 RPEPEBLUPendingGains;
        uint256 RPEPELPURPLEPendingGains;
        uint256 RPEPEBLUTotalGained;
        uint256 RPEPELPURPLETotalGained;
    }

    address private _RPEPEBLU;
    address private _RPEPELPURPLE;
    address private _KEK;
    
    uint private _lastTimestamp;
    uint private _timeInterval;
    uint256 private _rewardBlockAmount;
    uint256 private _totalRewardsPerDay;

    mapping(address => Gains) private _gains;
    
    constructor(address kek, address rpepeblu, address rpepelpurple, uint timeInterval) public {
        _KEK = kek;
        _RPEPEBLU = rpepeblu;
        _RPEPELPURPLE = rpepelpurple;

        // Set the initial last timestamp
        _lastTimestamp = block.timestamp;
        // Set the initial staking reward block size
        _rewardBlockAmount = 260000E18;
        // time interval for create reward block and claim reward
        // This value will be 1 day
        _timeInterval = timeInterval;
    }

    /**
     * @dev API to get reward block size
     */
    function getRewardBlockAmount() external view returns (uint256) {
        return _rewardBlockAmount;
    }
    
    /**
     * @dev API to get the staker's pending gains in RPEPEBLU pool
     */
    function getPendingGainsInRPEPEBLU(address account) public view returns (uint256) {
        return _gains[account].RPEPEBLUPendingGains;
    }

    /**
     * @dev API to get the staker's pending gains in RPEPELPURPLE pool
     */
    function getPendingGainsInRPEPELPURPLE(address account) public view returns (uint256) {
        return _gains[account].RPEPELPURPLEPendingGains;
    }

    /**
     * @dev API to get the staker's total gained in RPEPEBLU pool
     */
    function getTotalGainedInRPEPEBLU(address account) public view returns (uint256) {
        return _gains[account].RPEPEBLUTotalGained;
    }

    /**
     * @dev API to get the staker's total gained in RPEPELPURPLE pool
     */
    function getTotalGainedInRPEPELPURPLE(address account) public view returns (uint256) {
        return _gains[account].RPEPELPURPLETotalGained;
    }

    /**
     * @dev API to get total amount staked in RPEPEBLU and RPEPELPURPLE pools
     */
    function getTotalStakedAmountInPools() public view returns (uint256) {
        uint256 stakedAmountInPKPool = IFARMINGPOOL(_RPEPEBLU).getTotalStakedAmount();
        uint256 stakedAmountInLPPool = IFARMINGPOOL(_RPEPELPURPLE).getTotalStakedAmount();
        return stakedAmountInPKPool.add(stakedAmountInLPPool);
    }

    /**
     * @dev API to get current daily staking rate of RPEPEBLU pool.
     *
     * Algorithm
     * - rate = (block size / 2) / amount of rPEPE in RPEPEBLU and RPEPELPURPLE pools.
     * - if block size = 260,000KEK (phase 1)
     *      then maximum rate=0.05KEK, minimum rate=0.005KEK
     * - if block size = 130,000KEK (phase 2)
     *      then maximum rate=0.025KEK, minimum rate=0.0025KEK
     * - if block size = 65,000KEK (phase 3)
     *      then maximum rate=0.0125KEK, minimum rate=0.00125KEK
     * - if block size = 32,500KEK (phase 4)
     *      then maximum rate=0.00625KEK, minimum rate=0.000625KEK
     */
    function getStakingRateInRPEPEBLU() public view returns (uint256) {
        uint256 maxRate = _getMaximunRate();
        uint256 minRate = _getMinimunRate();
        uint256 totalStakedAmount = getTotalStakedAmountInPools();
        uint256 rate = 0;

        if (totalStakedAmount > 0) {
            rate = _rewardBlockAmount.mul(1E18).div(totalStakedAmount);
            if (rate < minRate) {
                rate = minRate;
            } else if (rate > maxRate) {
                rate = maxRate;
            }
        }
        return rate;
    }

    /**
     * @dev API to get current daily staking rate of RPEPELPURPLE pool.
     *
     * Algorithm
     * - rate = block size / amount of rPEPE in RPEPEBLU and RPEPELPURPLE pools
     * - if block size = 260,000KEK (phase 1)
     *      then maximum rate=0.1KEK, minimum rate=0.01KEK
     * - if block size = 130,000KEK (phase 2)
     *      then maximum rate=0.05KEK, minimum rate=0.005KEK
     * - if block size = 65,000KEK (phase 3)
     *      then maximum rate=0.025KEK, minimum rate=0.0025KEK
     * - if block size = 32,500KEK (phase 4)
     *      then maximum rate=0.0125KEK, minimum rate=0.00125KEK
     */
    function getStakingRateInRPEPELPURPLE() public view returns (uint256) {
        uint256 maxRate = _getMaximunRate().mul(2);
        uint256 minRate = _getMinimunRate().mul(2);
        uint256 totalStakedAmount = getTotalStakedAmountInPools();
        uint256 rate = 0;

        if (totalStakedAmount > 0) {
            rate = _rewardBlockAmount.mul(1E18).div(totalStakedAmount);
            if (rate < minRate) {
                rate = minRate;
            } else if (rate > maxRate) {
                rate = maxRate;
            }
        }
        return rate;
    }

    /**
     * @dev API to harvest staker's reward from RPEPEBLU.
     */
    function harvestFromRPEPEBLU() external {
        uint256 pendingGains = getPendingGainsInRPEPEBLU(_msgSender());
        // send tokens to the staker's account
        require(IKEK(_KEK).transfer(_msgSender(), pendingGains));
        _gains[_msgSender()].RPEPEBLUPendingGains = 0;
        _gains[_msgSender()].RPEPEBLUTotalGained = _gains[_msgSender()].RPEPEBLUTotalGained.add(pendingGains);
        emit ClaimedReward(_msgSender(), pendingGains);
    }

    /**
     * @dev API to harvest staker's reward from RPEPELPURPLE.
     */
    function harvestFromRPEPELPURPLE() external {
        uint256 pendingGains = getPendingGainsInRPEPELPURPLE(_msgSender());
        // send tokens to the staker's account
        require(IKEK(_KEK).transfer(_msgSender(), pendingGains));
        _gains[_msgSender()].RPEPELPURPLEPendingGains = 0;
        _gains[_msgSender()].RPEPELPURPLETotalGained = _gains[_msgSender()].RPEPELPURPLETotalGained.add(pendingGains);
        emit ClaimedReward(_msgSender(), pendingGains);
    }

    /**
     * @dev API to create new staking reward block and claim reward per day.
     */
    function createRewardBlockAndClaimRewards() external {
        uint count = (block.timestamp - _lastTimestamp) / _timeInterval;
        _createRewardBlockAndClaimRewards(count);
        // update last timestamp
        _lastTimestamp = count * _timeInterval + _lastTimestamp;
    }
    
    /**
     * @dev Get maximum rate
     */
    function _getMaximunRate() internal view returns (uint256) {
        uint256 maxRate = 0;
        if (_rewardBlockAmount == 260000E18) { // for phase 1
            maxRate = 5E16;
        } else if (_rewardBlockAmount == 130000E18) { // for phase 2
            maxRate = 25E15;
        } else if (_rewardBlockAmount == 65000E18) { // for phase 3
            maxRate = 125E14;
        } else if (_rewardBlockAmount == 32500E18) { // for phase 4
            maxRate = 625E13;
        }
        require(maxRate > 0, "Block size has been undefined");
        return maxRate;
    }

    /**
     * @dev Get minimum rate
     */
    function _getMinimunRate() internal view returns (uint256) {
        uint256 minRate = 0;
        if (_rewardBlockAmount == 260000E18) { // for phase 1
            minRate = 5E15;
        } else if (_rewardBlockAmount == 130000E18) { // for phase 2
            minRate = 25E14;
        } else if (_rewardBlockAmount == 65000E18) { // for phase 3
            minRate = 125E13;
        } else if (_rewardBlockAmount == 32500E18) { // for phase 4
            minRate = 625E12;
        }
        require(minRate > 0, "Block size has been undefined");
        return minRate;
    }

    /**
     * @dev Create new staking reward block by calculation the remaining in staking reward.
     */
    function _createRewardBlockAndClaimRewards(uint count) internal {
        for (uint i = 0; i < count; i++) {
            _createRewardBlockAndBurn(IKEK(_KEK).balanceOf(address(this)));
            _claimRewardsInRPEPEBLU();
            _claimRewardsInRPEPELPURPLE();
        }
    }

    /**
     * @dev Set the block amount for current staking reward and burn tokens for block amount
     * 
     * Formula:
     * - 260,000 KEK (75%-100% remaining in staking reward)
     * - 130,000 KEK (50%-75% remaining in staking reward)
     * - 65,000 KEK (25%-50% remaining in staking reward)
     * - 32,500 KEK (0%-25% remaining in staking reward)
     */
    function _createRewardBlockAndBurn(uint256 available) internal {
        require(available > 0, "Available KEK amount must be more than zero.");
        uint256 percent = available.div(49000000E10).mul(100);
        // Initialize total rewards per day
        _totalRewardsPerDay = 0;

        if (percent > 0 && percent < 25) {
            _rewardBlockAmount = 32500E18;
            IKEK(_KEK).burn(address(this), 32500E18);
        } else if (percent >= 25 && percent < 50) {
            _rewardBlockAmount = 65000E18;
            IKEK(_KEK).burn(address(this), 65000E18);
        } else if (percent >= 50 && percent < 75) {
            _rewardBlockAmount = 130000E18;
            IKEK(_KEK).burn(address(this), 130000E18);
        } else if (percent >= 75 && percent <= 100) {
            _rewardBlockAmount = 260000E18;
            IKEK(_KEK).burn(address(this), 260000E18);
        }
    }
    
    /**
     * @dev Claim rewards to all stakers in RPEPEBLU daily
     */
    function _claimRewardsInRPEPEBLU() internal {
        address[] memory stakers = IFARMINGPOOL(_RPEPEBLU).getStakers();
        for (uint256 i = 0; i < stakers.length; i++) {
            _calcPendingGainsInRPEPEBLU(stakers[i]);
        }
    }

    /**
     * @dev Claim rewards to all stakers in RPEPELPURPLE daily
     */
    function _claimRewardsInRPEPELPURPLE() internal {
        address[] memory stakers = IFARMINGPOOL(_RPEPELPURPLE).getStakers();
        for (uint256 i = 0; i < stakers.length; i++) {
            _calcPendingGainsInRPEPELPURPLE(stakers[i]);
        }
    }

    /**
     * @dev Calcuate staker's pending gains in RPEPEBLU.
     */
    function _calcPendingGainsInRPEPEBLU(address account) internal {
        require(account != address(0), "Invalid address");
        uint256 rewards = (IFARMINGPOOL(_RPEPEBLU).getStakedAmount(account)).mul(getStakingRateInRPEPEBLU()).div(1E18);

        if (_totalRewardsPerDay.add(rewards) > _rewardBlockAmount) {
            rewards = _rewardBlockAmount.sub(_totalRewardsPerDay);
        }
        _gains[account].RPEPEBLUPendingGains = _gains[account].RPEPEBLUPendingGains.add(rewards);
        _totalRewardsPerDay = _totalRewardsPerDay.add(rewards);
    }

    /**
     * @dev Calcuate staker's pending gains in RPEPELPURPLE.
     */
    function _calcPendingGainsInRPEPELPURPLE(address account) internal {
        require(account != address(0), "Invalid address");
        uint256 rewards = (IFARMINGPOOL(_RPEPELPURPLE).getStakedAmount(account)).mul(getStakingRateInRPEPELPURPLE()).div(1E18);

        if (_totalRewardsPerDay.add(rewards) > _rewardBlockAmount) {
            rewards = _rewardBlockAmount.sub(_totalRewardsPerDay);
        }
        _gains[account].RPEPELPURPLEPendingGains = _gains[account].RPEPELPURPLEPendingGains.add(rewards);
        _totalRewardsPerDay = _totalRewardsPerDay.add(rewards);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IXSPStaking {
    struct Percentage {
        uint256 timestamp;
        uint256 percentPerMonth;
        uint256 percentPerSecond;
    }

    struct Staker {
        uint256 timestamp;
        uint256 amount;
    }

    // public write -----

    // gets value and checks current total staked amount. if more than available to stake then returns back
    function stake(uint256 amount) external returns (uint256 timestamp);

    // dont forget to unpause if its needed
    function unstake(bool reinvestReward) external returns (uint256 timestamp);

    function claimReward() external returns (uint256 claimedAmount, uint256 timestamp);

    function reinvest() external returns (uint256 reinvestedAmount, uint256 timestamp);

    // public view -----
    function claimableReward() external view returns (uint256 reward); //with internal function for reuse in claimReward() and reinvest()

    function percentagePerMonth() external view returns (uint256[] memory, uint256[] memory);


    // for owner
    // pausing staking. unstake is available.
    function pauseStacking(uint256 startTime) external returns (bool); // if 0 => block.timestamp
    function unpauseStacking() external returns (bool);

    // pausing staking, unstaking and sets 0 percent from current time
    function pauseGlobally(uint256 startTime) external returns (bool); // if 0 => block.timestamp
    function unpauseGlobally() external returns (bool);

    function updateMaxTotalAmountToStake(uint256 amount) external returns (uint256 updatedAmount);
    function updateMinAmountToStake(uint256 amount) external returns (uint256 updatedAmount);

    // if 0 => block.timestamp
    function addPercentagePerMonth(uint256 timestamp, uint256 percent) external returns (uint256 index); // require(timestamp > block.timestamp);
    function updatePercentagePerMonth(uint256 timestamp, uint256 percent, uint256 index) external returns (bool);

    function removeLastPercentagePerMonth() external returns (uint256 index);

    event Stake(address account, uint256 stakedAmount);
    event Unstake(address account, uint256 unstakedAmount, bool withReward);
    event ClaimReward(address account, uint256 claimedAmount);
    event Reinvest(address account, uint256 reinvestedAmount, uint256 totalInvested);
    event MaxStakeAmountReached(address account, uint256 changeAmount);

    event StakingPause(uint256 startTime);
    event StakingUnpause(); // check with empty args

    event GlobalPause(uint256 startTime);
    event GlobalUnpause();

    event MaxTotalStakeAmountUpdate(uint256 updateAmount);
    event MinStakeAmountUpdate(uint256 updateAmount);
    event AddPercentagePerMonth(uint256 percent, uint256 index);
    event UpdatePercentagePerMonth(uint256 percent, uint256 index);
    event RemovePercentagePerMonth(uint256 index);
}

contract XSPStaking is IXSPStaking, Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    Percentage[] percentage;
    uint256 public maxTotalAmountToStake;
    uint256 public minAmountToStake;
    uint256 public totalStaked;
    uint256 _lastSetPercentPerMonth;
    bool public stakingPaused;
    bool public globallyPaused;
    mapping(address => Staker) public stakers;

    uint256 constant SECONDS_DENOMINATOR = 10 ** 18;
    uint256 constant DENOMINATOR = 100;
    uint256 constant SECONDS_IN_MONTH = 2592000;

    constructor() public {
        token = IERC20(0x2Dd9FfF70fDa675291aac6dBef4A27bF1B4735bB);
//        token = IERC20(0xaB6efAfd8EE40281e08A7572369EA10531A5071A); // testnet
//        token = IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF); // bat
//        minAmountToStake = 3 * 10 ** 2 * 10 ** uint256(token.decimals()); // bat min
        minAmountToStake = 3 * 10 ** 6 * 10 ** uint256(token.decimals()); // XSP min
        maxTotalAmountToStake = 4 * 10 ** 9 * 10 ** uint256(token.decimals());
        percentage.push(Percentage(block.timestamp, 13, _calculatePercentPerSecond(13)));
    }

    function stake(uint256 amount) external returns (uint256 timestamp) {
        require(stakers[msg.sender].amount.add(amount) >= minAmountToStake, "Invalid amount");
        //Reinvest if staker had staked before
        if (stakers[msg.sender].amount != 0) {
            _reinvest();
            //Finish execution if max stake amount reached during reinvestment
            if (totalStaked >= maxTotalAmountToStake) {
                return block.timestamp;
            }
        }

        uint256 amountToStake = _getAmountToStake(amount);

        _stake(amountToStake);
        token.transferFrom(msg.sender, address(this), amountToStake);
        return block.timestamp;
    }

    function unstake(bool reinvestReward) external returns (uint256 timestamp) {
        require(globallyPaused == false, "Unstacking is paused");
        uint256 amountToUnstake = stakers[msg.sender].amount;
        uint256 reward = _calculateReward(msg.sender);
        totalStaked = totalStaked.sub(amountToUnstake);
        //Discard staker info
        delete stakers[msg.sender];

        if (reinvestReward) {
            uint256 amountToStake = _getRewardAmountToStakeAndSendChangeToUserIfNecessary(reward);
            _stake(amountToStake);
        } else {
            amountToUnstake = amountToUnstake.add(reward);
        }

        token.transfer(msg.sender, amountToUnstake);
        emit Unstake(msg.sender, amountToUnstake, reinvestReward);
        return block.timestamp;
    }

    function claimReward() external returns (uint256 claimedAmount, uint256 timestamp) {
        require(globallyPaused == false, "Stacking is paused");
        uint256 reward = _calculateReward(msg.sender);
        //Restart staker timestamp
        stakers[msg.sender].timestamp = block.timestamp;

        token.transfer(msg.sender, reward);
        emit ClaimReward(msg.sender, reward);
        return (reward, block.timestamp);
    }

    function reinvest() external returns (uint256 reinvestedAmount, uint256 timestamp) {
        return _reinvest();
    }

    function _reinvest() internal returns (uint256 reinvestedAmount, uint256 timestamp) {
        require(stakers[msg.sender].amount != 0, "Don't have tokens to reinvest");

        uint256 reward = _calculateReward(msg.sender);
        uint256 amountToStake = _getRewardAmountToStakeAndSendChangeToUserIfNecessary(reward);
        _stake(amountToStake);

        emit Reinvest(msg.sender, amountToStake, stakers[msg.sender].amount);
        return (stakers[msg.sender].amount, block.timestamp);
    }

    function claimableReward() external view returns (uint256 reward) {
        return _calculateReward(msg.sender);
    }

    function percentagePerMonth() external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory timestamps = new uint256[](percentage.length);
        uint256[] memory percents = new uint256[](percentage.length);
        for (uint256 i = 0; i < percentage.length; i++) {
            timestamps[i] = percentage[i].timestamp;
            percents[i] = percentage[i].percentPerMonth;
        }
        return (timestamps, percents);
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    // if 0 => block.timestamp
    function pauseStacking(uint256 startTime) external onlyOwner returns (bool) {
        require(!stakingPaused, 'Staking already paused');
        _pause(startTime);
        stakingPaused = true;
        emit StakingPause(startTime);
        return true;
    }

    function unpauseStacking() external onlyOwner returns (bool) {
        require(stakingPaused, 'Staking already unpaused');
        _unpause();
        stakingPaused = false;
        emit StakingUnpause();
        return true;
    }

    // pausing staking, unstaking and sets 0 percent from current time
    function pauseGlobally(uint256 startTime) external onlyOwner returns (bool) {
        require(!globallyPaused, 'Global pause already activated');
        _pause(startTime);
        globallyPaused = true;
        emit GlobalPause(startTime);
        return true;
    }

    function unpauseGlobally() external onlyOwner returns (bool) {
        require(globallyPaused, 'Global pause already deactivated');
        _unpause();
        globallyPaused = false;
        emit GlobalUnpause();
        return true;
    }

    function updateMaxTotalAmountToStake(uint256 amount) external onlyOwner returns (uint256 updatedAmount) {
        require(amount >= totalStaked, 'Max amount to stake can not be less than total staked');
        maxTotalAmountToStake = amount;
        emit MaxTotalStakeAmountUpdate(maxTotalAmountToStake);
        return maxTotalAmountToStake;
    }

    function updateMinAmountToStake(uint256 amount) external onlyOwner returns (uint256 updatedAmount) {
        require(amount > 0, 'Min amount to stake have to be more than 0');
        minAmountToStake = amount;
        emit MinStakeAmountUpdate(maxTotalAmountToStake);
        return minAmountToStake;
    }

    function addPercentagePerMonth(uint256 timestamp, uint256 percent) external onlyOwner returns (uint256 index) {
        return _addPercentagePerMonth(timestamp, percent);
    }

    function updatePercentagePerMonth(uint256 timestamp, uint256 percent, uint256 index) external onlyOwner returns (bool) {
        require(timestamp <= percentage[index].timestamp, "It is forbidden to change percent after activation");
        percentage[index].percentPerMonth = percent;
        percentage[index].percentPerSecond = _calculatePercentPerSecond(percent);
        emit UpdatePercentagePerMonth(percent, index);
        return true;
    }

    function removeLastPercentagePerMonth() external onlyOwner returns (uint256 index) {
        require(!stakingPaused && !globallyPaused, "Staking is paused");
        require(percentage[percentage.length - 1].timestamp >= block.timestamp, "It is forbidden to remove percent after activation");
        delete percentage[index];
        percentage.length--;
        emit RemovePercentagePerMonth(index);
        return percentage.length - 1;
    }

    function _stake(uint256 amount) internal {
        require(totalStaked < maxTotalAmountToStake, "Max stake amount is reached");
        require(stakingPaused == false, "Staking is paused");
        require(globallyPaused == false, "Staking is paused");

        totalStaked = totalStaked.add(amount);
        stakers[msg.sender].timestamp = block.timestamp;
        stakers[msg.sender].amount = stakers[msg.sender].amount.add(amount);
        emit Stake(msg.sender, amount);
    }

    function _getRewardAmountToStakeAndSendChangeToUserIfNecessary(uint256 rewardAmount) internal returns (uint256) {
        uint256 amountToStake = _getAmountToStake(rewardAmount);
        if (amountToStake < rewardAmount) {
            uint256 changeAmount = rewardAmount.sub(amountToStake);
            token.transfer(msg.sender, changeAmount);
            emit MaxStakeAmountReached(msg.sender, changeAmount);
        }
        return amountToStake;
    }

    function _getAmountToStake(uint256 amount) internal view returns (uint256) {
        uint256 supposedTotalStaked = totalStaked.add(amount);
        //If stake limit exceeded
        if (supposedTotalStaked > maxTotalAmountToStake) {
            return amount.sub((supposedTotalStaked.sub(maxTotalAmountToStake)));
        }
        return amount;
    }

    function _addPercentagePerMonth(uint256 timestamp, uint256 percent) internal returns (uint256 index) {
        timestamp = timestamp == 0 ? block.timestamp : timestamp;
        require(timestamp >= block.timestamp, "Timestamp can't be in the past");

        if (timestamp > percentage[percentage.length - 1].timestamp) {
            require(percentage[percentage.length - 1].percentPerMonth != percent, "Percent should not be equal to the previous one");
            percentage.push(Percentage(timestamp, percent, _calculatePercentPerSecond(percent)));
            emit AddPercentagePerMonth(percent, percentage.length - 1);
            return percentage.length - 1;
        }

        uint256 indexToAddNewPercentage = _getIndexToAddNewPercentage(timestamp, percent);
        //move last element right
        percentage.push(percentage[percentage.length - 1]);
        //move elements from indexToAddNewPercentage to last - 1 right
        for (uint256 i = percentage.length - 3; i >= indexToAddNewPercentage; i--) {
            percentage[i + 1] = percentage[i];
        }
        //put new percentage on his chronological place
        percentage[indexToAddNewPercentage] = Percentage(timestamp, percent, _calculatePercentPerSecond(percent));

        emit AddPercentagePerMonth(percent, indexToAddNewPercentage);
        return indexToAddNewPercentage;
    }

    function _getIndexToAddNewPercentage(uint256 timestamp, uint256 percent) internal view returns (uint256 index) {
        uint256 i = percentage.length;
        while(i > 0 && timestamp < percentage[i - 1].timestamp) {
            i--;
        }
        require(percentage[i].percentPerMonth != percent, "Percent should not be equal to the previous one");
        return i;
    }

    function _calculateReward(address stakerAddress) internal view returns (uint256) {
        uint256 stakedAmount = stakers[stakerAddress].amount;
        uint256 activePercentageIndex = _getActivePercentageIndex();
        uint256 lastIntervalTimestamp = percentage[activePercentageIndex].timestamp;
        uint256 stakerTimestamp = stakers[stakerAddress].timestamp;
        bool isPercentChangedAfterStaking = lastIntervalTimestamp > stakerTimestamp;
        uint256 secondsHeld;
        if (!isPercentChangedAfterStaking) {
            // ----p1-------------p2------
            // ------------------------s--
            //how much seconds user held tokens
            secondsHeld = block.timestamp.sub(stakerTimestamp);
            return _calculateRewardBySecondsHeld(secondsHeld, stakedAmount);
        }
        // calculate reward for last percentage change interval
        secondsHeld = block.timestamp.sub(lastIntervalTimestamp);
        uint256 reward = _calculateRewardBySecondsHeld(secondsHeld, stakedAmount);

        bool isStakedBetweenCurrentPercentageChangeInterval;
        for (uint256 i = percentage.length - 1; i > 0; i--) {
            isStakedBetweenCurrentPercentageChangeInterval = stakerTimestamp > percentage[i - 1].timestamp;
            if (isStakedBetweenCurrentPercentageChangeInterval) {
                // ----p1-------------p2------
                // -------------s-------------
                secondsHeld = lastIntervalTimestamp.sub(stakerTimestamp);
                reward = reward.add(_calculateRewardBySecondsHeld(secondsHeld, stakedAmount));
                break;
            } else {
                // p0-----p1-------------p2------
                // p0--s-------------------------
                secondsHeld = lastIntervalTimestamp.sub(percentage[i - 1].timestamp);
                reward = reward.add(_calculateRewardBySecondsHeld(secondsHeld, stakedAmount));
                lastIntervalTimestamp = percentage[i - 1].timestamp;
            }
        }
        return reward;
    }

    function _getActivePercentageIndex() internal view returns (uint256 index) {
        uint256 i = percentage.length - 1;
        while(i > 0 && block.timestamp < percentage[i].timestamp) {
            i--;
        }
        return i;
    }

    function _calculateRewardBySecondsHeld(uint256 secondsHeld, uint256 stakedAmount) internal view returns (uint256) {
        uint256 percentPerSecond = secondsHeld.mul(percentage[percentage.length - 1].percentPerSecond);
        return stakedAmount.mul(percentPerSecond).div(SECONDS_DENOMINATOR).div(DENOMINATOR);
    }

    function _calculatePercentPerSecond(uint256 percentPerMonth) internal pure returns (uint256) {
        return percentPerMonth.mul(SECONDS_DENOMINATOR).div(SECONDS_IN_MONTH);
    }

    function _pause(uint256 startTime) internal {
        uint256 lastSetPercentPerMonth = percentage[percentage.length - 1].percentPerMonth;
        if (lastSetPercentPerMonth > 0) {
            _lastSetPercentPerMonth = lastSetPercentPerMonth;
        }
        _addPercentagePerMonth(startTime, 0);
    }

    function _unpause() internal {
        percentage.push(Percentage(block.timestamp, _lastSetPercentPerMonth, _calculatePercentPerSecond(_lastSetPercentPerMonth)));
    }
}
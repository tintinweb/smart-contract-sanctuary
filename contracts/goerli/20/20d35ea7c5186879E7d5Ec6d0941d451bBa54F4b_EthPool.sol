//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IEthPool.sol";

contract EthPool is IEthPool {

    using SafeMath for uint256;

    modifier withValueEqualsTo(uint256 _amount) {
        require(_amount == msg.value, "Amount must match value sent");
        _;
    }

    modifier onlyStakers() {
        require(_isStaker(msg.sender), "Only stakers can perform this action");
        _;
    }

    modifier onlyStakersWithRewards() {
        require(stakerData[msg.sender].rewardAmount > 0, "Only stakers with rewards can perform this action");
        _;
    }

    modifier onlyRewarders() {
        require(isRewarder[msg.sender], "Only rewarders can perform this action");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor can perform this action");
        _;
    }

    event StakeDeposited(address indexed _staker, uint256 _amount, uint256 _totalAmount, uint256 _date);
    event Withdrawn(address indexed _staker, uint256 _unstakedAmount, uint256 _rewardsAmount, uint256 _date);
    event RewardsDeposited(
        uint256 indexed _rewardId,
        address indexed _rewarder,
        uint256 _depositedAmount,
        uint256 _distributedAmount,
        uint256 _date
    );
    event RewarderAdded(address indexed _newRewarder, uint256 _date);
    event RewarderRemoved(address indexed _removedRewarder, uint256 _date);

    struct StakerData {
        uint256 index;
        uint256 stakedAmount;
        uint256 rewardAmount;
    }

    address[] public stakers;
    address public governor;
    uint256 public currentlyStakedAmount;
    uint256 public rewardsNotWithdrawn;
    uint256 public nextRewardId;
    mapping(address => StakerData) public stakerData;
    mapping(address => bool) public isRewarder;

    constructor() {
        governor = msg.sender;
        _addRewarder(msg.sender);
    }

    /**
     * @dev Stakes ETH in the pool.
     * @param _amount The amount of ETH to stake, must match the value sent.
     * @return The total amount of ETH currently staked by the sender in the pool.
     */
    function stake(uint256 _amount) external override payable withValueEqualsTo(_amount) returns (uint256) {
        require(_amount > 0, "Amount to stake must be greater than zero");
        if (!_isStaker(msg.sender)) {
            _addStaker(msg.sender);
        }
        uint256 totalAmountStakedBySender = _incrementStakedAmount(msg.sender, _amount);
        emit StakeDeposited(msg.sender, _amount, totalAmountStakedBySender, block.timestamp);
        return totalAmountStakedBySender;
    }

    /**
     * @dev Deposits ETH to reward stakers in the pool.
     * @param _amount The amount of ETH to deposit, must match the value sent.
     */
    function depositRewards(uint256 _amount) external override payable withValueEqualsTo(_amount) onlyRewarders() {
        uint256 distributedRewards = _distributeRewards(_amount);
        if (distributedRewards < _amount) {
            _transferEther(msg.sender, _amount - distributedRewards);
        }
        emit RewardsDeposited(nextRewardId++, msg.sender, _amount, distributedRewards, block.timestamp);
    }

    /**
     * @dev Withdraws stakes and rewards from the pool.
     * @return The total amount of ETH withdrawn, including both stakes and rewards.
     */
    function withdraw() external override onlyStakers() returns (uint256) {
        uint256 unstakedAmount = stakerData[msg.sender].stakedAmount;
        uint256 withdrawnRewards = stakerData[msg.sender].rewardAmount;
        _removeStaker(msg.sender);
        _transferEther(msg.sender, unstakedAmount + withdrawnRewards);
        emit Withdrawn(msg.sender, unstakedAmount, withdrawnRewards, block.timestamp);
        return unstakedAmount + withdrawnRewards;
    }

    /**
     * @dev Gets the current ETH staked by the given address.
     * @param _staker The address to which the balance is queried.
     * @return The amount of ETH currently staked by the given address.
     */
    function getAmountCurrentlyStakedBy(address _staker) external override view returns (uint256) {
        return stakerData[_staker].stakedAmount;
    }

    /**
     * @dev Stakes the rewards of the sender. Equivalent to perform a withdraw and staking all the ETH withdrawn.
     * @return The new amount of ETH currently staked by the sender.
     */
    function stakeRewards() external onlyStakersWithRewards() returns (uint256) {
        uint256 rewardsToStake = _clearRewardAmount(msg.sender);
        emit Withdrawn(msg.sender, stakerData[msg.sender].stakedAmount, rewardsToStake, block.timestamp);
        uint256 newStakedAmount = _incrementStakedAmount(msg.sender, rewardsToStake);
        emit StakeDeposited(msg.sender, newStakedAmount, newStakedAmount, block.timestamp);
        return newStakedAmount;
    }

    /**
     * @dev Withdraws the rewards of the sender. Equivalent to perform a withdraw, keeping the rewards and re-staking
     * the ETH that was already staked before the withdraw.
     * @return The amount of ETH rewards withdrawn.
     */
    function withdrawRewards() external onlyStakersWithRewards() returns (uint256) {
        uint256 stakedAmount = stakerData[msg.sender].stakedAmount;
        uint256 rewardToWithdraw = _clearRewardAmount(msg.sender);
        _transferEther(msg.sender, rewardToWithdraw);
        emit Withdrawn(msg.sender, stakedAmount, rewardToWithdraw, block.timestamp);
        emit StakeDeposited(msg.sender, stakedAmount, stakedAmount, block.timestamp);
        return rewardToWithdraw;
    }

    /**
     * @dev Adds the given address as rewarder, only callable by governor.
     * @param _newRewarder The address of the rewarder to add.
     */
    function addRewarder(address _newRewarder) external onlyGovernor() {
        _addRewarder(_newRewarder);
    }

    /**
     * @dev Removes the given address as rewarder, only callable by governor.
     * @param _rewarderToRemove The address of the rewarder to remove.
     */
    function removeRewarder(address _rewarderToRemove) external onlyGovernor() {
        _removeRewarder(_rewarderToRemove);
    }


    /**
     * @dev Removes the sender address as rewarder, only callable by rewarders.
     */
    function renounceAsRewarder() external onlyRewarders() {
        _removeRewarder(msg.sender);
    }

    /**
     * @dev Transfers the given amount of ETH from the contract to the given address.
     * @param _to The address to which the ETH must be transfered to.
     * @param _amount The amount of ETH to be transfered.
     */
    function _transferEther(address _to, uint256 _amount) internal {
        (bool transferSucceed, ) = _to.call{value: _amount}("");
        require(transferSucceed, "Transfer failed");
    }

    /**
     * @dev Distributes the given rewards amount between stakers. The actually distributed amount can be different from 
     * the given one because of division roundings.
     * @param _amount The amount of ETH to distribute.
     * @return The amount of ETH actually distributed.
     */
    function _distributeRewards(uint256 _amount) internal returns (uint256) {
        uint256 distributedRewards;
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 reward = _amount.mul(stakerData[staker].stakedAmount).div(currentlyStakedAmount);
            stakerData[staker].rewardAmount = stakerData[staker].rewardAmount.add(reward);
            distributedRewards = distributedRewards.add(reward);
        }
        rewardsNotWithdrawn = rewardsNotWithdrawn.add(distributedRewards);
        return distributedRewards;
    }

    /**
     * @dev Tells whether a given address is a staker or not.
     * @param _staker The address to verify if is a staker.
     * @return True if is a staker, false if not.
     */
    function _isStaker(address _staker) internal view returns (bool) {
        return stakerData[_staker].stakedAmount > 0;
    }

    /**
     * @dev Adds the given staker from the list of stakers.
     * @param _staker The address of the staker to add.
     */
    function _addStaker(address _staker) internal {
        stakerData[_staker].index = stakers.length;
        stakers.push(_staker);
    }

    /**
     * @dev Removes the given staker from the list of stakers, cleaning its stake and reward balance.
     * @param _staker The address of the staker to remove.
     */
    function _removeStaker(address _staker) internal {
        uint256 stakerIndex = stakerData[_staker].index;
        address lastStaker = stakers[stakers.length - 1];
        stakers[stakerIndex] = lastStaker;
        stakers.pop();
        stakerData[lastStaker].index = stakerIndex;
        stakerData[_staker].index = 0;
        _clearStakedAmount(_staker);
        _clearRewardAmount(_staker);
    }

    /**
     * @dev Increments the staker staked amount by the given amount and increments currently staked amount.
     * @param _staker The address of the staker to which the amount must de incremented.
     * @param _amount The amount to increment.
     * @return The new ETH staked amount.
     */
    function _incrementStakedAmount(address _staker, uint256 _amount) internal returns (uint256) {
        uint256 newStakedAmount = stakerData[_staker].stakedAmount.add(_amount);
        stakerData[_staker].stakedAmount = newStakedAmount;
        currentlyStakedAmount = currentlyStakedAmount.add(_amount);
        return newStakedAmount;
    }

    /**
     * @dev Clears the staker staked amount.
     * @param _staker The address of the staker to which the amount must de cleared.
     * @return The amount that has been cleared.
     */
    function _clearStakedAmount(address _staker) internal returns (uint256) {
        uint256 unstakedAmount = stakerData[_staker].stakedAmount;
        stakerData[_staker].stakedAmount = 0;
        currentlyStakedAmount = currentlyStakedAmount.sub(unstakedAmount);
        return unstakedAmount;
    }

    /**
     * @dev Clears the reward staked amount.
     * @param _staker The address of the staker to which the amount must de cleared.
     * @return The amount that has been cleared.
     */
    function _clearRewardAmount(address _staker) internal returns (uint256) {
        uint256 withdrawnRewards = stakerData[_staker].rewardAmount;
        stakerData[_staker].rewardAmount = 0;
        rewardsNotWithdrawn -= withdrawnRewards;
        return withdrawnRewards;
    }

    /**
     * @dev Adds the given address as rewarder.
     * @param _newRewarder The address of the rewarder to add.
     */
    function _addRewarder(address _newRewarder) internal {
        isRewarder[_newRewarder] = true;
        emit RewarderAdded(_newRewarder, block.timestamp);
    }

    /**
     * @dev Removes the given address as rewarder.
     * @param _rewarderToRemove The address of the rewarder to remove.
     */
    function _removeRewarder(address _rewarderToRemove) internal {
        isRewarder[_rewarderToRemove] = false;
        emit RewarderRemoved(_rewarderToRemove, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.0;

interface IEthPool {

    /**
     * @dev Stakes ETH in the pool.
     * @param _amount The amount of ETH to stake, must match the value sent.
     * @return The total amount of ETH currently staked by the sender in the pool.
     */
    function stake(uint256 _amount) external payable returns (uint256);

    /**
     * @dev Deposits ETH to reward stakers in the pool.
     * @param _amount The amount of ETH to deposit, must match the value sent.
     */
    function depositRewards(uint256 _amount) external payable;

    /**
     * @dev Withdraws stakes and rewards from the pool.
     * @return The total amount of ETH withdrawn, including both stakes and rewards.
     */
    function withdraw() external returns (uint256);

    /**
     * @dev Gets the current ETH staked by the given address.
     * @param _staker The address to which the balance is queried.
     * @return The amount of ETH currently staked by the given address.
     */
    function getAmountCurrentlyStakedBy(address _staker) external returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
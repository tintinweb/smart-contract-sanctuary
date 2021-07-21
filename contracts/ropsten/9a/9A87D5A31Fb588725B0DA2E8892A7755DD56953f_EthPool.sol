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

    event StakeDeposited(address indexed _staker, uint256 _amount, uint256 _totalAmount, uint256 _date);
    event Withdrawn(address indexed _staker, uint256 _unstakedAmount, uint256 _rewardsAmount, uint256 _date);
    event RewardsDeposited(
        uint256 indexed _rewardId,
        address indexed _rewarder,
        uint256 _amountDeposited,
        uint256 _amountDistributed,
        uint256 _date
    );

    struct StakerData {
        uint256 index;
        uint256 stakedAmount;
        uint256 rewardAmount;
    }

    address public rewarder;
    address[] public stakers;
    uint256 public totalStakedAmount;
    uint256 public totalDepositedRewards;
    uint256 nextRewardId;

    mapping(address => StakerData) stakersData;

    constructor() {
        rewarder = msg.sender;
    }

    /**
     * @dev Stakes ETH in the pool.
     * @param _amount The amount of ETH to stake, must match the value sent.
     * @return The total amount of ETH currently staked by the sender in the pool.
     */
    function stake(uint256 _amount) external override payable withValueEqualsTo(_amount) returns (uint256) {
        require(_amount > 0, "Amount to stake must be greater than zero");
        if (stakersData[msg.sender].stakedAmount == 0) {
            stakersData[msg.sender].index = stakers.length;
            stakers.push(msg.sender);
        }
        uint256 totalStakedAmountBySender = stakersData[msg.sender].stakedAmount.add(_amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
        stakersData[msg.sender].stakedAmount = totalStakedAmountBySender;
        emit StakeDeposited(msg.sender, _amount, totalStakedAmountBySender, block.timestamp);
        return totalStakedAmountBySender;
    }

    /**
     * @dev Deposits ETH to reward stakers in the pool.
     * @param _amount The amount of ETH to deposit, must match the value sent.
     */
    function depositRewards(uint256 _amount) external override payable withValueEqualsTo(_amount) {
        require(msg.sender == rewarder, "Sender must be allowed as rewarder");
        uint256 distributedRewards;
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 reward = _amount.mul(stakersData[staker].stakedAmount).div(totalStakedAmount);
            stakersData[staker].rewardAmount = stakersData[staker].rewardAmount.add(reward);
            distributedRewards = distributedRewards.add(reward);
        }
        if (_amount - distributedRewards > 0) {
            (bool returnSucceed, ) = msg.sender.call{value: _amount - distributedRewards}("");
            require(returnSucceed, "Transfer failed");
        }
        totalDepositedRewards = totalDepositedRewards.add(distributedRewards);
        emit RewardsDeposited(nextRewardId++, msg.sender, _amount, distributedRewards, block.timestamp);
    }

    /**
     * @dev Withdraws stakes and rewards from the pool.
     * @return The total amount of ETH withdrawn, including both stakes and rewards.
     */
    function withdraw() external override returns (uint256) {
        require(stakersData[msg.sender].stakedAmount > 0, "Only stakers can withdraw");
        uint256 withdrawerIndex = stakersData[msg.sender].index;
        uint256 unstakedAmount = stakersData[msg.sender].stakedAmount;
        uint256 rewardsWithdrawn = stakersData[msg.sender].rewardAmount;
        address lastStaker = stakers[stakers.length - 1];
        stakers[withdrawerIndex] = lastStaker;
        stakers.pop();
        stakersData[lastStaker].index = withdrawerIndex;
        stakersData[msg.sender].index = 0;
        stakersData[msg.sender].stakedAmount = 0;
        stakersData[msg.sender].rewardAmount = 0;
        (bool withdrawSucceed, ) = msg.sender.call{value: unstakedAmount + rewardsWithdrawn}("");
        require(withdrawSucceed, "Transfer failed");
        emit Withdrawn(msg.sender, unstakedAmount, rewardsWithdrawn, block.timestamp);
        return unstakedAmount + rewardsWithdrawn;
    }

    /**
     * @dev Gets the current ETH staked by the given address.
     * @param _staker The address to which the balance is queried.
     * @return The amount of ETH currently staked by the given address.
     */
    function getStakedAmountBy(address _staker) external view returns (uint256) {
        return stakersData[_staker].stakedAmount;
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
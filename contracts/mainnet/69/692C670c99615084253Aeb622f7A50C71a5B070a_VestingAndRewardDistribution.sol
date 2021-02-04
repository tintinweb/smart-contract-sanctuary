pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract VestingAndRewardDistribution {
  string public constant name = "CRT.finance vesting & pool reward distribution contract"; // team tokens (2.5%) vested over 6 months.

  using SafeMath for uint256;

  address public immutable crt;

  uint256 public immutable vestingAmount;
  uint256 public immutable vestingBegin;
  uint256 public immutable vestingEnd;
  address public liquidity;
  address public randomizedpool;
  address public governancepool;
  uint256 public timestamped;
  uint256 public timestamped2;
  uint256 public timestamped3;
  address public pooleth;
  uint256 public deployment = 1612987709;
  uint256 public endchange = 1612404000;


  address public recipient;
  uint256 public lastUpdate;
  
  constructor(
    address crt_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingEnd_
  ) public {
    require(
      vestingBegin_ >= block.timestamp,
      "VestingAndRewardDistribution::constructor: vesting begin too early"
    );
    require(
      vestingEnd_ > vestingBegin_,
      "VestingAndRewardDistribution::constructor: vesting end too early"
    );

    crt = crt_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin_;
  }

  function delegate(address delegatee) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::delegate: unauthorized"
    );
    ICrt(crt).delegate(delegatee);
  }

  function setRecipient(address recipient_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }
  
  function setGovernancePool(address governancepool_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setGovernancePool: unauthorized"
    );
    require(deployment < block.timestamp);
    governancepool = governancepool_;
  }
  
  function setLP(address liquidity_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRecipient: unauthorized"
    );
    require(endchange < block.timestamp);
    liquidity = liquidity_;
  }
  
  function setRandomizedPool(address randomizedpool_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRandomizedPool: unauthorized"
    );
    require(deployment < block.timestamp);
    randomizedpool = randomizedpool_;
  }

  function setETHPool(address pooleth_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRandomizedPool: unauthorized"
    );
    require(endchange < block.timestamp);
    pooleth = pooleth_;
  }

  function claim() external {
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = ICrt(crt).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    ICrt(crt).transfer(recipient, amount);
  }
  
  
  function rewardLPandPools() external {
    require(block.timestamp > timestamped);
    timestamped = block.timestamp + 86400;
    ICrt(crt).transfer(pooleth, 150 ether);
    ICrt(crt).transfer(liquidity, 25 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
    function rewardPoolGovernance() external {
    require(block.timestamp > deployment); // can be used in 7 days when pool goes live
    require(block.timestamp > timestamped2);
    timestamped2 = block.timestamp + 86400;
    ICrt(crt).transfer(governancepool, 50 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
    function rewardPoolRandomized() external {
    require(block.timestamp > deployment); // can be used in 7 days when pool goes live
    require(block.timestamp > timestamped3);
    timestamped3 = block.timestamp + 86400;
    ICrt(crt).transfer(randomizedpool, 50 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
  
}

interface ICrt {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
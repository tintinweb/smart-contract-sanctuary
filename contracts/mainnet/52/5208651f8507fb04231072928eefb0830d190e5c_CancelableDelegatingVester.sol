// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract CancelableDelegatingVester {
  using SafeMath for uint256;

  /// @dev The name of this contract
  string public constant name = "Indexed Team Vesting Contract";

  address public immutable terminator;
  address public immutable ndx;

  uint256 public immutable vestingAmount;
  uint256 public immutable vestingBegin;
  uint256 public immutable vestingEnd;

  address public recipient;
  uint256 public lastUpdate;

  constructor(
    address terminator_,
    address ndx_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingEnd_
  ) public {
    require(
      vestingBegin_ >= block.timestamp,
      "CancelableDelegatingVester::constructor: vesting begin too early"
    );
    require(
      vestingEnd_ > vestingBegin_,
      "CancelableDelegatingVester::constructor: vesting end too early"
    );

    terminator = terminator_;
    ndx = ndx_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin_;
  }

  function delegate(address delegatee) external {
    require(
      msg.sender == recipient,
      "CancelableDelegatingVester::delegate: unauthorized"
    );
    INdx(ndx).delegate(delegatee);
  }

  function setRecipient(address recipient_) external {
    require(
      msg.sender == recipient,
      "CancelableDelegatingVester::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }

  function claim() public {
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = INdx(ndx).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    INdx(ndx).transfer(recipient, amount);
  }

  function terminate() external {
    require(
      msg.sender == terminator,
      "CancelableDelegatingVester::terminate: unauthorized"
    );
    claim();
    uint256 amount = INdx(ndx).balanceOf(address(this));
    INdx(ndx).transfer(terminator, amount);
  }
}

interface INdx {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
  function transferFrom(address src, address dst, uint256 rawAmount) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CancelableDelegatingVester.sol";


contract VestingFactory {
  address public immutable ndx;

  constructor(address ndx_) public {
    ndx = ndx_;
  }

  function createVestingContract(
    address terminator,
    address recipient,
    uint256 vestingAmount,
    uint256 numDays
  ) external {
    require(numDays <= 730, "Excessive duration");
    uint256 vestingBegin = block.timestamp;
    uint256 vestingEnd = vestingBegin + (numDays * 86400);
    CancelableDelegatingVester vester = new CancelableDelegatingVester(
      terminator,
      ndx,
      recipient,
      vestingAmount,
      vestingBegin,
      vestingEnd
    );
    INdx(ndx).transferFrom(msg.sender, address(vester), vestingAmount);
  }
}

{
  "metadata": {
    "useLiteralContent": false
  },
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
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract OracleV2 {
    using SafeMath for uint;

    event ExchangeRatePosted(
        address operator,
        uint prevExchangeRate,
        uint newExchangeRate
    );

    address public admin;
    address public poster;
    uint public currentExchangeRate;
    uint public lastUpdated;

    /// @notice The change of exchange rate shouldn't exceed 1%.
    uint public constant MAX_SWING = 0.01e18;

    /// @notice Poster couldn't update the exchange rate within 12 hours.
    uint public constant UPDATE_PERIOD = 12 hours;

    constructor(address _poster) public {
        admin = msg.sender;
        poster = _poster;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setPoster(address _poster) external {
        require(msg.sender == admin, "!admin");
        poster = _poster;
    }

    /// @notice Update the exchange rate by admin. It's for emergency.
    /// @param newExchangeRate The new exchange rate.
    function setExchangeRate(uint newExchangeRate) external {
        require(msg.sender == admin, "!admin");

        emit ExchangeRatePosted(msg.sender, currentExchangeRate, newExchangeRate);
        currentExchangeRate = newExchangeRate;
        lastUpdated = block.timestamp;
    }

    /// @notice Update the exchange rate by poster. It would have a cooldown period and a max swing limit.
    /// @param newExchangeRate The new exchange rate.
    function updateExchangeRate(uint newExchangeRate) external {
        require(msg.sender == poster, "!poster");
        require(block.timestamp > lastUpdated.add(UPDATE_PERIOD), "cooldown");

        if (currentExchangeRate > 0) {
            uint maxDiff = currentExchangeRate.mul(MAX_SWING).div(1e18);
            require(newExchangeRate < currentExchangeRate.add(maxDiff), "upper cap");
            require(newExchangeRate > currentExchangeRate.sub(maxDiff), "lower cap");
        }

        emit ExchangeRatePosted(msg.sender, currentExchangeRate, newExchangeRate);
        currentExchangeRate = newExchangeRate;
        lastUpdated = block.timestamp;
    }

    /// @notice Get the exchange rate between ETH and CETH2.
    /// @return The exchange rate.
    function exchangeRate() external view returns (uint) {
        return currentExchangeRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
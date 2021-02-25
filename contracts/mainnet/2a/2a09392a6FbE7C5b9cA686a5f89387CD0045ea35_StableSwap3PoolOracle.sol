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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface AggregatorInterface {
      function latestAnswer() external view returns (int256);
      function latestTimestamp() external view returns (uint256);
      function latestRound() external view returns (uint256);
      function getAnswer(uint256 roundId) external view returns (int256);
      function getTimestamp(uint256 roundId) external view returns (uint256);
}

interface AggregatorV3Interface {

      function decimals() external view returns (uint8);
      function description() external view returns (string memory);
      function version() external view returns (uint256);

      // getRoundData and latestRoundData should both raise "No data present"
      // if they do not have data to report, instead of returning unset values
      // which could be misinterpreted as actual reported values.
      function getRoundData(uint80 _roundId)
            external
            view
            returns (
                  uint80 roundId,
                  int256 answer,
                  uint256 startedAt,
                  uint256 updatedAt,
                  uint80 answeredInRound
            );
      function latestRoundData()
            external
            view
            returns (
                  uint80 roundId,
                  int256 answer,
                  uint256 startedAt,
                  uint256 updatedAt,
                  uint80 answeredInRound
            );
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IStableSwap3PoolOracle {
    function getEthereumPrice() external view returns (uint256);
    function getPrices() external view returns (uint256, uint256);
    function getSafeAnswer(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IStableSwap3PoolOracle.sol";
import "../interfaces/Chainlink.sol";

contract StableSwap3PoolOracle is IStableSwap3PoolOracle {
    using SafeMath for uint256;

    uint256 public constant MAX_ROUND_TIME = 1 hours;
    uint256 public constant MAX_STALE_ANSWER = 24 hours;
    uint256 public constant ETH_USD_MUL = 1e10; // ETH-USD feed is to 8 decimals

    address public immutable ethUsd;
    address[3] public feeds;

    constructor(
        address _feedETHUSD,
        address _feedDAIETH,
        address _feedUSDCETH,
        address _feedUSDTETH
    )
        public
    {
        ethUsd = _feedETHUSD;
        feeds[0] = _feedDAIETH;
        feeds[1] = _feedUSDCETH;
        feeds[2] = _feedUSDTETH;
    }

    /**
     * @notice Retrieves the current price of ETH/USD as provided by Chainlink
     * @dev Reverts if the answer from Chainlink is not safe
     */
    function getEthereumPrice() external view override returns (uint256 _price) {
        _price = getSafeAnswer(ethUsd);
        require(_price > 0, "!getEthereumPrice");
        _price = _price.mul(ETH_USD_MUL);

    }

    /**
     * @notice Retrieves the minimum price of the 3pool tokens as provided by Chainlink
     * @dev Reverts if none of the Chainlink nodes are safe
     */
    function getPrices() external view override returns (uint256 _minPrice, uint256 _maxPrice) {
        for (uint8 i = 0; i < 3; i++) {
            // get the safe answer from Chainlink
            uint256 _answer = getSafeAnswer(feeds[i]);

            // store the first iteration regardless (handle that later if 0)
            // otherwise,check that _answer is greater than 0 and only store it if less
            // than the previously observed price
            if (i == 0) {
                _minPrice = _answer;
                _maxPrice = _answer;
            } else if (_answer > 0 && _answer < _minPrice) {
                _minPrice = _answer;
            } else if (_answer > 0 && _answer > _maxPrice) {
                _maxPrice = _answer;
            }
        }

        // if we couldn't get a valid price from any of the Chainlink feeds,
        // revert because nothing is safe
        require(_minPrice > 0 && _maxPrice > 0, "!getPrices");
    }

    /**
     * @notice Get and check the answer provided by Chainlink
     * @param _feed The address of the Chainlink price feed
     */
    function getSafeAnswer(address _feed) public view override returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_feed).latestRoundData();

        // latest round is carried over from previous round
        if (answeredInRound < roundId) {
            return 0;
        }

        // latest answer is stale
        // solhint-disable-next-line not-rely-on-time
        if (updatedAt < block.timestamp.sub(MAX_STALE_ANSWER)) {
            return 0;
        }

        // round has taken too long to collect answers
        if (updatedAt.sub(startedAt) > MAX_ROUND_TIME) {
            return 0;
        }

        // Chainlink already rejects answers outside of a range (like what would cause
        // a negative answer)
        return uint256(answer);
    }
}
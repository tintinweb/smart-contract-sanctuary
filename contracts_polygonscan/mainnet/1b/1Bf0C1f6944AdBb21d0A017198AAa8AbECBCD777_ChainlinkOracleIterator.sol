// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IOracleIterator.sol";

contract ChainlinkOracleIterator is IOracleIterator {
    using SafeMath for uint256;

    uint256 private constant PHASE_OFFSET = 64;
    int256 public constant NEGATIVE_INFINITY = type(int256).min;
    uint256 private constant MAX_ITERATION = 24;

    function isOracleIterator() external pure override returns (bool) {
        return true;
    }

    function symbol() external pure override returns (string memory) {
        return "ChainlinkIterator";
    }

    function getUnderlyingValue(
        address _oracle,
        uint256 _timestamp,
        uint256[] calldata _roundHints
    ) external view override returns (int256) {
        require(_timestamp > 0, "Zero timestamp");
        require(_oracle != address(0), "Zero oracle");
        require(_roundHints.length == 1, "Wrong number of hints");
        AggregatorV3Interface oracle = AggregatorV3Interface(_oracle);

        uint80 latestRoundId;
        (latestRoundId, , , , ) = oracle.latestRoundData();

        uint80 roundHint = uint80(_roundHints[0]);
        if (roundHint == 0) {
            return getIteratedAnswer(oracle, _timestamp, latestRoundId);
        }

        uint256 phaseId;
        (phaseId, ) = parseIds(latestRoundId);

        if (checkSamePhase(roundHint, phaseId)) {
            return
                getHintedAnswer(oracle, _timestamp, roundHint, latestRoundId);
        }

        int256 answer = getIteratedAnswer(oracle, _timestamp, latestRoundId);
        if (answer == NEGATIVE_INFINITY) {
            return
                getHintedAnswer(oracle, _timestamp, roundHint, latestRoundId);
        }
        return answer;
    }

    function getHintedAnswer(
        AggregatorV3Interface _oracle,
        uint256 _timestamp,
        uint80 _roundHint,
        uint256 _latestRoundId
    ) internal view returns (int256) {
        int256 hintAnswer;
        uint256 hintTimestamp;
        (, hintAnswer, , hintTimestamp, ) = _oracle.getRoundData(_roundHint);

        require(
            hintTimestamp > 0 && hintTimestamp <= _timestamp,
            "Incorrect hint"
        );

        if (_roundHint + 1 > _latestRoundId) {
            return hintAnswer;
        }

        uint256 timestampNext;
        (, , , timestampNext, ) = _oracle.getRoundData(_roundHint + 1);
        if (timestampNext == 0 || timestampNext > _timestamp) {
            return hintAnswer;
        }

        return NEGATIVE_INFINITY;
    }

    function getIteratedAnswer(
        AggregatorV3Interface _oracle,
        uint256 _timestamp,
        uint80 _latestRoundId
    ) internal view returns (int256) {
        uint256 roundTimestamp = 0;
        int256 roundAnswer = 0;
        uint80 roundId = _latestRoundId;

        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            (, roundAnswer, , roundTimestamp, ) = _oracle.getRoundData(roundId);
            roundId = roundId - 1;
            if (roundTimestamp <= _timestamp) {
                return roundAnswer;
            }
            if (roundId == 0) {
                return NEGATIVE_INFINITY;
            }
        }

        return NEGATIVE_INFINITY;
    }

    function checkSamePhase(uint80 _roundHint, uint256 _phase)
        internal
        pure
        returns (bool)
    {
        uint256 currentPhaseId;
        (currentPhaseId, ) = parseIds(_roundHint);
        return currentPhaseId == _phase;
    }

    function parseIds(uint256 _roundId) internal pure returns (uint16, uint64) {
        uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(_roundId);

        return (phaseId, aggregatorRoundId);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IOracleIterator {
    /// @notice Proof of oracle iterator contract
    /// @dev Verifies that contract is a oracle iterator contract
    /// @return true if contract is a oracle iterator contract
    function isOracleIterator() external pure returns (bool);

    /// @notice Symbol of the oracle iterator
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbol
    function symbol() external pure returns (string memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    //  finds the value closest to a given timestamp
    /// @param _oracle iteratable oracle through
    /// @param _timestamp a given timestamp
    /// @param _roundHints specified rounds for a given timestamp
    /// @return the value closest to a given timestamp
    function getUnderlyingValue(
        address _oracle,
        uint256 _timestamp,
        uint256[] calldata _roundHints
    ) external view returns (int256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
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
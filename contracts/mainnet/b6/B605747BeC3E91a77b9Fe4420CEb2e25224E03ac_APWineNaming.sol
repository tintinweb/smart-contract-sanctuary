pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract APWineNaming {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice generate the symbol of the FYT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbol(
        uint8 _index,
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) public pure returns (string memory) {
        return concatenate(genIBTSymbol(_ibtSymbol, _platform, _periodDuration), concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the symbol from the apwIBT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbolFromIBT(uint8 _index, string memory _ibtSymbol) public pure returns (string memory) {
        return concatenate(_ibtSymbol, concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the apwIBT symbol
     * @param _ibtSymbol the symbol of the IBT of the future
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the apwIBT
     * @dev i.e 30D-AAVE-ADAI
     */
    function genIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) public pure returns (string memory) {
        return
            concatenate(
                getPeriodDurationDenominator(_periodDuration),
                concatenate("-", concatenate(_platform, concatenate("-", _ibtSymbol)))
            );
    }

    /**
     * @notice generate the period denominator
     * @param _periodDuration the period duration
     * @return the period denominator
     * @dev i.e 30D
     */
    function getPeriodDurationDenominator(uint256 _periodDuration) public pure returns (string memory) {
        if (_periodDuration >= 1 days) {
            uint256 numberOfdays = _periodDuration.div(1 days);
            return string(concatenate(uintToString(uint8(numberOfdays)), "D"));
        }
        return "CUSTOM";
    }

    function uintToString(uint8 v) public pure returns (string memory) {
        bytes memory reversed = new bytes(8);
        uint256 i = 0;
        if (v == 0) return "0";
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint256 j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return string(s);
    }

    function concatenate(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a, b));
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
library SafeMathUpgradeable {
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
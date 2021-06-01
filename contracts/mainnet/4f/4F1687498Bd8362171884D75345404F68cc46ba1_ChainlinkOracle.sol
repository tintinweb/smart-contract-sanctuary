// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import '../math/MixedSafeMathWithUnit.sol';

contract ChainlinkOracle {

    using MixedSafeMathWithUnit for uint256;
    using MixedSafeMathWithUnit for int256;

    string  public symbol;
    address public immutable oracle;
    uint256 public immutable decimals;

    constructor (string memory symbol_, address oracle_) {
        symbol = symbol_;
        oracle = oracle_;
        decimals = IChainlink(oracle_).decimals();
    }

    function getPrice() external view returns (uint256) {
        uint256 price = IChainlink(oracle).latestAnswer().itou().mul(uint256(10**18)).div(uint256(10**decimals));
        return price;
    }

}

interface IChainlink {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Mixed safe math with base unit of 10**18
 */
library MixedSafeMathWithUnit {

    uint256 constant UONE = 10**18;
    uint256 constant UMAX = 2**255 - 1;

    int256 constant IONE = 10**18;
    int256 constant IMIN = -2**255;

    //================================================================================
    // Conversions
    //================================================================================

    /**
     * @dev Convert uint256 to int256
     */
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, "MixedSafeMathWithUnit: convert uint256 to int256 overflow");
        int256 b = int256(a);
        return b;
    }

    /**
     * @dev Convert int256 to uint256
     */
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, "MixedSafeMathWithUnit: convert int256 to uint256 overflow");
        uint256 b = uint256(a);
        return b;
    }

    /**
     * @dev Take abs of int256
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 abs overflow");
        if (a >= 0) {
            return a;
        } else {
            return -a;
        }
    }

    /**
     * @dev Take negation of int256
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 negate overflow");
        return -a;
    }

    //================================================================================
    // Rescale and reformat
    //================================================================================

    function _rescale(uint256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (uint256)
    {
        uint256 scale1 = 10 ** decimals1;
        uint256 scale2 = 10 ** decimals2;
        uint256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale uint256 overflow");
        uint256 c = b / scale1;
        return c;
    }

    function _rescale(int256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (int256)
    {
        int256 scale1 = utoi(10 ** decimals1);
        int256 scale2 = utoi(10 ** decimals2);
        int256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale int256 overflow");
        int256 c = b / scale1;
        return c;
    }

    /**
     * @dev Rescales a value from 10**18 base to 10**decimals base
     */
    function rescale(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(a, 18, decimals);
    }

    function rescale(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(a, 18, decimals);
    }

    /**
     * @dev Reformat a value to be a valid 10**decimals base value
     * The formatted value is still in 10**18 base
     */
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }

    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }


    //================================================================================
    // Addition
    //================================================================================

    /**
     * @dev Addition: uint256 + uint256
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MixedSafeMathWithUnit: uint256 addition overflow");
        return c;
    }

    /**
     * @dev Addition: int256 + int256
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "MixedSafeMathWithUnit: int256 addition overflow"
        );
        return c;
    }

    /**
     * @dev Addition: uint256 + int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return add(a, uint256(b));
        } else {
            return sub(a, uint256(-b));
        }
    }

    /**
     * @dev Addition: int256 + uint256
     */
    function add(int256 a, uint256 b) internal pure returns (int256) {
        return add(a, utoi(b));
    }

    //================================================================================
    // Subtraction
    //================================================================================

    /**
     * @dev Subtraction: uint256 - uint256
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "MixedSafeMathWithUnit: uint256 subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Subtraction: int256 - int256
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "MixedSafeMathWithUnit: int256 subtraction overflow"
        );
        return c;
    }

    /**
     * @dev Subtraction: uint256 - int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return sub(a, uint256(b));
        } else {
            return add(a, uint256(-b));
        }
    }

    /**
     * @dev Subtraction: int256 - uint256
     */
    function sub(int256 a, uint256 b) internal pure returns (int256) {
        return sub(a, utoi(b));
    }

    //================================================================================
    // Multiplication
    //================================================================================

    /**
     * @dev Multiplication: uint256 * uint256
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: uint256 multiplication overflow");
        return c / UONE;
    }

    /**
     * @dev Multiplication: int256 * int256
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == IMIN), "MixedSafeMathWithUnit: int256 multiplication overflow");
        int256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: int256 multiplication overflow");
        return c / IONE;
    }

    /**
     * @dev Multiplication: uint256 * int256
     */
    function mul(uint256 a, int256 b) internal pure returns (uint256) {
        return mul(a, itou(b));
    }

    /**
     * @dev Multiplication: int256 * uint256
     */
    function mul(int256 a, uint256 b) internal pure returns (int256) {
        return mul(a, utoi(b));
    }

    //================================================================================
    // Division
    //================================================================================

    /**
     * @dev Division: uint256 / uint256
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MixedSafeMathWithUnit: uint256 division by zero");
        uint256 c = a * UONE;
        require(
            c / UONE == a,
            "MixedSafeMathWithUnit: uint256 division internal multiplication overflow"
        );
        uint256 d = c / b;
        return d;
    }

    /**
     * @dev Division: int256 / int256
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "MixedSafeMathWithUnit: int256 division by zero");
        int256 c = a * IONE;
        require(
            c / IONE == a,
            "MixedSafeMathWithUnit: int256 division internal multiplication overflow"
        );
        require(!(c == IMIN && b == -1), "MixedSafeMathWithUnit: int256 division overflow");
        int256 d = c / b;
        return d;
    }

    /**
     * @dev Division: uint256 / int256
     */
    function div(uint256 a, int256 b) internal pure returns (uint256) {
        return div(a, itou(b));
    }

    /**
     * @dev Division: int256 / uint256
     */
    function div(int256 a, uint256 b) internal pure returns (int256) {
        return div(a, utoi(b));
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
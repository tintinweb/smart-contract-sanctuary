// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./SafeMath.sol";


/**
* @notice Additional math operations
*/
library AdditionalMath {
    using SafeMath for uint256;

    function max16(uint16 a, uint16 b) internal pure returns (uint16) {
        return a >= b ? a : b;
    }

    function min16(uint16 a, uint16 b) internal pure returns (uint16) {
        return a < b ? a : b;
    }

    /**
    * @notice Division and ceil
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a.add(b) - 1) / b;
    }

    /**
    * @dev Adds signed value to unsigned value, throws on overflow.
    */
    function addSigned(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a.add(uint256(b));
        } else {
            return a.sub(uint256(-b));
        }
    }

    /**
    * @dev Subtracts signed value from unsigned value, throws on overflow.
    */
    function subSigned(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a.sub(uint256(b));
        } else {
            return a.add(uint256(-b));
        }
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add16(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub16(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds signed value to unsigned value, throws on overflow.
    */
    function addSigned16(uint16 a, int16 b) internal pure returns (uint16) {
        if (b >= 0) {
            return add16(a, uint16(b));
        } else {
            return sub16(a, uint16(-b));
        }
    }

    /**
    * @dev Subtracts signed value from unsigned value, throws on overflow.
    */
    function subSigned16(uint16 a, int16 b) internal pure returns (uint16) {
        if (b >= 0) {
            return sub16(a, uint16(b));
        } else {
            return add16(a, uint16(-b));
        }
    }
}

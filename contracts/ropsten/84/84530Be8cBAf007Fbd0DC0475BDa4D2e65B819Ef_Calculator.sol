pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Calculator {

   event CalculationPerformed(string operationName, string lhs, string rhs, string result);

   constructor() { }

   function add(uint lhs, uint rhs) public returns (uint)
   {
       uint result = lhs + rhs;
       require (result >= lhs);
       
       emit CalculationPerformed("Addition", Strings.toString(lhs), Strings.toString(rhs), Strings.toString(result));
       return result;
   }

   function subtract(uint lhs, uint rhs) public returns (uint)
   {
       uint result = lhs - rhs;
       require (result <= lhs);
       
       emit CalculationPerformed("Subtraction", Strings.toString(lhs), Strings.toString(rhs), Strings.toString(result));
       return result; 
   }

    //Divide, rounding any remainder towards zero
   function divideAndRound(uint dividend, uint divisor) public returns (uint)
   {
       require(divisor != 0);
       uint result = dividend / divisor; 
       require (result <= dividend);
       
       emit CalculationPerformed("Division", Strings.toString(dividend), Strings.toString(divisor), Strings.toString(result));
       return result; 
   }

    //Divide, returning the quotient and the remainder (in this order)
   function divide(uint dividend, uint divisor) public returns (uint, uint)
   {
       require(divisor != 0);
       uint quotient = dividend / divisor; 
       require (quotient <= dividend);
       uint remainder = dividend % divisor; 
       
       string memory eventMsg = string(abi.encodePacked("(", quotient, ",", remainder, ")"));
       emit CalculationPerformed("Division", Strings.toString(dividend), Strings.toString(divisor), eventMsg);
       return (quotient, remainder); 
   }

   function multiply(uint lhs, uint rhs) public returns (uint)
   {
       uint result = lhs * rhs;
       require(result / rhs == lhs || lhs == 0 || rhs == 0);
       
       emit CalculationPerformed("Multiplication", Strings.toString(lhs), Strings.toString(rhs), Strings.toString(result));
       return result; 
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
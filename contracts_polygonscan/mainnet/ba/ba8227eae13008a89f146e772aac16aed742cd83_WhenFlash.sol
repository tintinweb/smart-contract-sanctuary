/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WhenFlash {
    uint256 private _number = 8424983333484574935833442214693637181660036899457743165593042812928;    

    function whenFlash() public view returns (string memory) {
        uint256 hourBitIndex = 22 * 5;
        uint256 minBitIndex = 44 * 5;
        
        uint256 hour = (_number >> hourBitIndex) & 31;
        uint256 min = (_number >> minBitIndex) & 31;

        string[] memory value = new string[](6);
        value[0] = toString(hour);
        value[1] = toString(hour);
        value[2] = ":";
        value[3] = toString(min);
        value[4] = toString(min);
        value[5] = " GMT";

        return string(abi.encodePacked(value[0], value[1], value[2], value[3], value[4], value[5]));
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
}
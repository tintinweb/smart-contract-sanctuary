// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WhenFlashV2 {
    uint256 private _number = 1075665205075544547797912036882762970817066004643840;

    function whenFlash(uint256 firstAnswer, uint256 secondAnswer, uint256 thirdAnswer) public view returns (string memory) {
        uint256 hourBitIndex = firstAnswer * 5;
        uint256 minBitIndex = secondAnswer * 5;
        uint256 minBitIndex2 = thirdAnswer * 5;
        
        uint256 hour = (_number >> hourBitIndex) & 31;
        uint256 min = (_number >> minBitIndex) & 31;
        uint256 min2 = (_number >> minBitIndex2) & 31;

        string[] memory value = new string[](6);
        value[0] = toString(hour);
        value[1] = ":";
        value[2] = toString(min);
        value[3] = toString(min2);
        value[4] = " GMT";

        return string(abi.encodePacked(value[0], value[1], value[2], value[3], value[4]));
    }

    function firstQuestion() public pure returns (string memory) {
        return 'How many digital animals are announced?';
    }

    function secondQuestion() public pure returns (string memory) {
        return 'How many team members are announced?';
    }

    function thirdQuestion() public pure returns (string memory) {
        return 'What will be the start date of drop?';
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
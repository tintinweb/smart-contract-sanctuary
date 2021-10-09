// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Raffle  {
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    function getWinners(string memory rate) pure public  returns (string memory) {
        string memory result;

        uint256 i;
        uint256 rand = random(string(abi.encodePacked('SeasideNOW',rate)));
        
        for(i=0;i<25;i++) {
            result = string(abi.encodePacked(result, toString(1+rand%3307), ' '));
            rand >>= 5;
        }

        return result;
    }

}
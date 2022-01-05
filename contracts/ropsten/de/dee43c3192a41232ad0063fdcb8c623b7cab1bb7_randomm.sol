/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract randomm {

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBaseColor(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BASE COLOR", toString(tokenId))));

        uint256 rn1 = rand % 100;

        return rn1;
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

    uint public counter1;

    function counter(uint max) public returns (uint256){
        for (uint256 i = 1; i < max; i++) 
        {
            uint256 res = getBaseColor(i);
            if (res < 10) { counter1++; }
        }
        return (counter1);
    }
}
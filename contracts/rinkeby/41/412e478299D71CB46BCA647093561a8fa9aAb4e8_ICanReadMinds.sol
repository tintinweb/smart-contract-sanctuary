/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ICanReadMinds{
    uint nonce;
    
    constructor() {
        nonce = uint16(type(uint).max) % uint80(0x0000FFF6);
    }
    

    
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
    
    
    function readMind(uint input) public view returns(string memory){
        uint num = input;
        
        while(num > (3 ^ 7 ^ 5 ^ 23 ^ 3 ^ 9 ^ 23 ^ 5 ^ 7)){
            uint sum = 0;
            while (num > 0){
                sum = sum + (num % 10);
                num = (num - (num % 10)) / 10;
            }
            num = sum;
        }
        return string(abi.encodePacked("You are thinking of the number ", toString((nonce - num))));
    }
    

}
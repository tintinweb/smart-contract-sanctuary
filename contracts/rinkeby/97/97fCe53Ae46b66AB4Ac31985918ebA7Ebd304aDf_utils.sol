// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {


    function challenge(uint256 tokenId, uint256 battleId, uint256 p1WeaponLevel, uint256 p1Reputation, uint256 p2WeaponLevel, uint256 p2Reputation) public view returns (bool){
        require(tokenId != battleId, "Err");

        uint256 p1Luck = 50 + p1WeaponLevel + p1Reputation;        
        uint256 p1Rand = random(string(abi.encodePacked(toString(block.number), toString(tokenId), "CHALLENGER")));
        uint256 p1Draw = p1Rand % p1Luck;

        uint256 p2Luck = 50 + p2WeaponLevel + p2Reputation;
        uint256 p2Rand = random(string(abi.encodePacked(toString(block.number), toString(battleId), "CHALLENGED")));
        uint256 p2Draw = p2Rand % p2Luck;

        //Challenger Wins
        if (p1Draw > p2Draw) {            
            return true;
        }

        return false;
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
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
}
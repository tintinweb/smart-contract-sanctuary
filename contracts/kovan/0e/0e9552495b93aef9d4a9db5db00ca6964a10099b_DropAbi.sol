/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



contract DropAbi  {
    function getHash(address _user) public pure returns (bytes32){
        
        return keccak256(abi.encodePacked(uint256(_user)+672394));
    }


    function getHashMemory(address[] memory _users) public pure returns (bytes32[] memory){
        uint256 len = _users.length;
        bytes32[] memory results = new bytes32[](len);
        for(uint256 i = 0 ; i < len; i++){
            results[i] = keccak256(abi.encodePacked(uint256(_users[i])+672394));
        }
        return results;
    }
}
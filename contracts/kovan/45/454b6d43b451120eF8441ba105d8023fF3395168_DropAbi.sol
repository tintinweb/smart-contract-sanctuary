/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


contract DropAbi  {
    function getHash(address _user) public pure returns (bytes32){
        
        return keccak256(abi.encodePacked(uint256(_user)+672394));
    }

    function getAddress(address _user) public pure returns (uint256){
        
        return uint256(_user);
    }
}
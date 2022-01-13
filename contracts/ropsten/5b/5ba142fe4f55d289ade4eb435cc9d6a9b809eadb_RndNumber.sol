/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract RndNumber{

    mapping(bytes32=>uint256) public randomMap;

    function takeRandomNumbers(bytes32 snapshotId,uint32 size,uint times) public {
        require(times<=8);
        uint256 result = 0;
        for(uint i=0; i<times; i++){
            uint256 rnd = uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,i))) % size;
            result = result | (rnd << (i * 32));
        }
        randomMap[snapshotId] = result; 
    }

}
/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


contract RandomTest
{
    
    function generateRandomNumber() public view returns(uint256) 
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        uint256 rand = (seed - ((seed / 1000) * 1000));
        return rand;
    } 
    
    function generateRandomNumber2() public view returns(uint256) 
    {
        
        uint256 blockValue = uint256(blockhash(block.number - 1));
           
        return blockValue;
    }
    
}
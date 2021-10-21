/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


contract RandomTest
{
    
    function generateRandomNumber() public view returns(bool) 
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        uint256 rand = (seed - ((seed / 1000) * 1000));
        
        
        return  rand < 500 ? true : false;
    } 
    

    
    function getGasLimit(int gs) public view returns(uint256) 
    {
        return block.gaslimit;
    }
    
   function getTimeStamp(int gs) public view returns(uint256) 
    {
        return block.timestamp;
    }
    
    function getDifficulty(int gs) public view returns(uint256) 
    {
        return block.difficulty;
    }
    
    function getBlockNumber(int gs) public view returns(uint256) 
    {
        return block.number;
    }
    
      function getCoinBase(int gs) public view returns(uint256) 
    {
        return uint256(keccak256(abi.encodePacked(block.coinbase))) ;
    }
    
    
    
}
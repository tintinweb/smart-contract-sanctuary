/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

// File: contracts/maptest.sol

pragma solidity ^0.5.10;


contract maptest {
    
    mapping (address => uint) public userLvl;
    
    function currentLevel (address userAddress) public view returns (uint){
        
        return userLvl[userAddress];
        
    }
    
}
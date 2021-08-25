/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Birthdays {
    
    uint8 public myAge;
    
    event Birthday(address indexed contractAddress, address indexed senderAddress, uint8 myAge);
    event Milestone(uint8 milestone);
    
    constructor() {
        myAge = 43;
    }
    
    function birthday (uint8 milestone) external {
        
        myAge++;
        
        emit Birthday(address(this), msg.sender, myAge);
      
        if (myAge == milestone){
          
          emit Milestone(milestone);
            
        }
        
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        
        return true;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract EventContract {
    
event MyEvent (
    uint indexed id ,
    uint indexed date ,
    string value 
);

uint nextId ; 


function emitEvent (string calldata value) external{
    emit MyEvent(nextId, block.timestamp , value);
    nextId++;
}
    
    
  
}
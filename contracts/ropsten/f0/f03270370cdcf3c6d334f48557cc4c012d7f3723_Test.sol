/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.4;

contract Test{
    
    uint storeNum;
    
    event Success(string result); 
    
    constructor() public{
        
    }
    
    function getNumber() view external returns (uint){
        return storeNum;
    }
    
    function setNumber(uint number) external returns (bool){
        require(number>0, "number should be larger than 0");
        storeNum = number;
        emit Success("Success");
        return true;
    }
   
}
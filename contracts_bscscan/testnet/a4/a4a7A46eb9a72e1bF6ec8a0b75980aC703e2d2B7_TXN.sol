/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

 contract owned {
        constructor() public { owner = msg.sender; }
        address payable owner;   
        modifier bonusRelease {
            require(
                msg.sender == owner,
                "Nothing For You!"
            );
            _;
        }
    }

 


contract TXN is owned {
     
    constructor(address payable _owner) public {
        owner = _owner; 
    }


    function purchaseToken( ) public payable returns(uint success){
        uint _value = msg.value;        
        return  _value;            
    }
    
    
    
    
    
}
/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Tiny {
    uint x ;
    function test(uint8 a ,uint8 b) pure public returns (uint){
        
            uint value = 0 ; 
            for(uint i=0;i<1500;i++){
                
                value +=a ; 
                value +=b ; 
            }
        
            return value ; 
  
            
    }
    
    function setX (uint value) public{
        x = value ; 
    }
}
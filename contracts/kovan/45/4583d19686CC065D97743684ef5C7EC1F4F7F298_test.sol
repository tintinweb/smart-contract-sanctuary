/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.8.1;

contract test {
    
    address owner;
    
    
    
    function own() public{
        owner = msg.sender;
    }

constructor(){
        owner = address(this);
    }
    
}
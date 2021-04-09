/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity ^0.4.24;

contract Si3mShadyCoin {

    mapping(address => uint256) public balanceOf;
    
    constructor () public {        
        balanceOf[msg.sender] = 888;
        bytes32 Symbol = "SSC";
        bytes32 Name =  "Si3MSHADY";
    }
     function getBalance() returns (uint256) {
        return balanceOf[msg.sender];
    }
        
}
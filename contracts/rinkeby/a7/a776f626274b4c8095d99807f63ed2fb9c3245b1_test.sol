/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

//SPDX-License-Identifier: none
pragma solidity ^0.8.4;

contract test{
    address public owner = msg.sender;  // Defines the ownership
    event ownershipTransferred(address);
    
    function transferOwnership(address to) public returns (bool){
        require(msg.sender == owner); // require condition is used for the security
        owner = to;
        emit ownershipTransferred(to);
        return true;
    }
}
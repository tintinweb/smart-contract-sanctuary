/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

contract SendEther {
    
    address public owner = msg.sender;
    
    function sendEther(address payable to, uint amount) public returns (bool) {
        to.transfer(amount);
        return true;
    }
    
    function ownershipTransfer(address to) public returns(bool) {
        require(msg.sender == owner);
        owner = to;
        return true;
    }
}
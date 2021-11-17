/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract A {
    address public otherAddress;
    
    constructor(address _otherAddress) {
        otherAddress = _otherAddress;
    }
}

contract HelloWorld {
    address payable public owner1;
    address payable public owner2;
    uint256 public amount = 1e18;
    
    constructor(address _myAddress, uint256 _amount) {
        owner1 = payable(msg.sender);
    }
    
    function transfer() public payable {
        uint256 amountOne = msg.value / 2;
        payable(msg.sender).send(amountOne);
    }
    
    function transfer1() public payable returns(uint256) {
        return msg.value;
    }
}
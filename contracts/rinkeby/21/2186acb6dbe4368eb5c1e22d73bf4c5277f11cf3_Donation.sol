/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;

contract Donation {
    address _owner;
    uint256 _balance;

    event Funded(address indexed _sender, uint256 value);
    
    constructor(){
        _owner = msg.sender;
    }

    function getBalance() public view returns (uint256) {
        return _balance;
    }

    function getServiceOwner() public view returns (address) {
        return _owner;
    }

    function fund() public payable {
        emit Funded(msg.sender, msg.value);
        require(msg.value > 0);
        _balance += msg.value;
    }
}
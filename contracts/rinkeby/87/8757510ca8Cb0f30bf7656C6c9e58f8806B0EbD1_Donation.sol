/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;

contract Donation {
    address payable _owner;
    uint256 _balance;

    event Funded(address indexed _sender, uint256 value);
    event Withdrawn(uint256 amount);

    constructor(){
        _owner = payable(msg.sender);
    }

    function getBalance() public view returns (uint256) {
        return _balance;
    }

    function getServiceOwner() public view returns (address) {
        return _owner;
    }

    function fund() public payable {
        require(msg.value > 0);
        emit Funded(msg.sender, msg.value);
        _balance += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= _balance);
        emit Withdrawn(amount);
        _balance -= amount;
        _owner.transfer(amount);
    }
}
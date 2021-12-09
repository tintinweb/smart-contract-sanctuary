// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Checker {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function getBalanceOfContract() public view returns (uint) {
        return address(this).balance;
    }

    function getBalanceOfOwner() public view returns (uint){
        if (msg.sender == owner)
            return owner.balance;
        else return 0;
    }

    function getBalanceOfSender() public view returns (uint) {
        return msg.sender.balance;
    }

    function getAddressOfContract() public view returns (address) {
        return address(this);
    }

    function getAddressOfOwner() public view returns (address) {
        return owner;
    }

    function getAddressOfSender() public view returns (address) {
        return msg.sender;
    }
}
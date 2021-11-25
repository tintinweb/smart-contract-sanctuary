// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Vault {
    address owner;
    mapping(address => bool) public allowedAddresses;

    event Withdrawal(address owner, uint256 amount);

    modifier checkPermit() {
        require(allowedAddresses[msg.sender] == true, "!NOOooup!");
        _;
    }

    constructor() {
        owner = msg.sender;
        allowedAddresses[msg.sender] = true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address payable _userAddress, uint256 amount)
        public
        
        checkPermit
    {
        (bool sent, ) = _userAddress.call{value: amount}("");
        require(sent, "1! F A I L !!");
    }

    function deposit() public payable {}

    function allowOperations(address _userAddress) public checkPermit {
        allowedAddresses[_userAddress] = true;
    }

    function denyOperations(address _userAddress) public checkPermit {
        require(owner != _userAddress, "You are not the owner");
        allowedAddresses[_userAddress] = false;
    }
}
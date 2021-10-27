/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract registration {
    address private owner;
    uint256 private registrationCost;
    mapping(address => bool) private registeredUsers;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
        registrationCost = 0.05 ether;
    }

    function changeOwner(address newOwner) external isOwner {
        owner = newOwner;
    }

    function changeRegistrationCost(uint256 newRegistrationCost) external isOwner {
        registrationCost = newRegistrationCost;
    }

    receive() external payable {
        register();
    }

    function register() public payable {
        require(!registeredUsers[msg.sender], "Address already registered.");
        require(msg.value >= registrationCost, "Insufficient registration fee.");

        registeredUsers[msg.sender] = true;
    }

    function withdraw(address payable receiver, uint256 amount) external isOwner {
        receiver.transfer(amount);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getRegistrationCost() external view returns (uint256) {
        return registrationCost;
    }

    function isRegistered() external view returns (bool) {
        return registeredUsers[msg.sender];
    }

    function isAddressRegistered(address account) external view returns (bool) {
        return registeredUsers[account];
    }
}
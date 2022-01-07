// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract SimpleBank {

    mapping (address => uint) private balances;
    address public owner;
    event LogDepositMade(address accountAddress, uint amount);

    constructor () {
        owner = msg.sender;
    }

    function deposit() public payable returns (uint) {
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);

        balances[msg.sender] += msg.value;

        emit LogDepositMade(msg.sender, msg.value); // fire event

        return balances[msg.sender];
    }

    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        require(withdrawAmount <= balances[msg.sender]);

        balances[msg.sender] -= withdrawAmount;

        payable(msg.sender).transfer(withdrawAmount);

        return balances[msg.sender];
    }


    function balance() view public returns (uint) {
        return balances[msg.sender];
    }
}
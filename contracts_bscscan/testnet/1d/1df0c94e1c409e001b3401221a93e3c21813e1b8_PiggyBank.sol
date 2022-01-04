/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
contract PiggyBank { 
        mapping(address => Deposit[]) public depositBaks;

    uint256 public transactions;
    mapping(address => uint256) balances;
    address public owner;
    struct Deposit {
        uint256 date;
        uint256 value;
        address owner;
        uint256 typeTransaction;
    }


    constructor() payable {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }



    function deposit(uint256 time) public payable {
        balances[msg.sender] += msg.value;
        depositBaks[msg.sender].push(Deposit(time, msg.value, msg.sender, 1));
        transactions++;
    }
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    function getDeposits() public view returns (Deposit[] memory) {
        return depositBaks[msg.sender];
    }
    function withdraw(uint256 amount, uint256 time) public onlyOwner {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        depositBaks[msg.sender].push(Deposit(time, amount, msg.sender, 0));
        transactions++;
    }
}
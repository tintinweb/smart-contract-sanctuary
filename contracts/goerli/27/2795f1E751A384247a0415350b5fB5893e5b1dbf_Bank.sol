/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
// import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract Bank {
    //using SafeMath for uint;  // For old version of compiler

    //uint _balance;    // 1st test for 1 user only

    // 0x23c42feeE47FB309146305b9124f2F27E6e5BeA3 (Account 1 from MetaMask)
    mapping(address => uint) _balances;
    uint _totalSupply;

    //function deposit(uint amount) public {
    function deposit() public payable {
        // _balance += amount;  // 1st test for 1 user only
        //_balance = _balance.add(amount);    // SafeMath
        _balances[msg.sender] += msg.value;    // msg.sender = Get sender's address
        _totalSupply += msg.value;
    }

    //function withdraw(uint amount) public {
    function withdraw(uint amount) public payable {
        //require(amount <= _balance, "balance is not enought");    // 1st test for 1 user only
        //_balance -= amount;   // 1st test for 1 user only
        //_balance = _balance.sub(amount);    // SafeMath
        require(amount <= _balances[msg.sender], "NOT ENOUGH MONEY.");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }

    function checkBalance() public view returns (uint balance_) {
        //return _balance;
        return _balances[msg.sender];
    }

    function checkTotalSupply() public view returns (uint totalSupply_) {
        return _totalSupply;
    }
}
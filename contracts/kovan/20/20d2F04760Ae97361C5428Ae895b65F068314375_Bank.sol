/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract Bank{
    // uint _balance;
    mapping(address=>uint) _balances;

    function deposit() public payable{
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public{
        require(amount <= _balances[msg.sender],"balance is not enought.");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
    }

    function getBalance() public view returns (uint balance){
        return _balances[msg.sender];
    }

}
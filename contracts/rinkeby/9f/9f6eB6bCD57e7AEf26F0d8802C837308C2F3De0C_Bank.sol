/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {

    mapping (address => uint) _balances; // ผูกตัวแปร _balances กับ address ที่ใช้
    uint _totalSupply;
    function deposit() public payable {

        //msg.sender // sender คือ address ของคนที่เรียกใช้งาน contract
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint amount) public payable {
        require (amount <= _balances[msg.sender] , "balance is not enough");
        
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= msg.value;
    }

    function checkBalance() public view returns (uint balance_) {
        return _balances[msg.sender];
    }

    function checkTotalSupply() public view returns (uint totalSupply_){
        return _totalSupply;
    }


} // end contract
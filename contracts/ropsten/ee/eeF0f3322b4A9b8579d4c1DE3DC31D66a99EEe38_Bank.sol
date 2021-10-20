/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  ^0.8.0;

//ธนาคาร
contract Bank {
    //uint _balance; 
    mapping(address => uint) _balances;  //เหมือน dic  เก็บกี่บัญชีก็ได
    uint _totalSupply;
    
    function deposit() public payable{
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    function withdraw(uint amount) public payable{
        require (amount <=  _balances[msg.sender], "not enough");
        payable(msg.sender).transfer(amount); //การส่งเงิน
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    
    }
    function check_balance() public view returns(uint balance_) {
        return _balances[msg.sender]; 
    }
    function check_toalSupply() public view returns(uint totalSupply){
        return _totalSupply;
    }
}
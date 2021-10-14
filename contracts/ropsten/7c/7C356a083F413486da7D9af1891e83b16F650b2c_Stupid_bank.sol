/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Stupid_bank {
    mapping(address => uint) _balances;
    uint _totalsupply;
    
    function deposit() public payable{
        _balances[msg.sender] += msg.value;
        _totalsupply += msg.value;
    }
    
    function withdraw() public payable{
        payable(msg.sender).transfer(msg.value);
        _balances[msg.sender] -= msg.value;
        _totalsupply -= msg.value;
    }
    
    function checkBalance() public view returns(uint balance){
        return _balances[msg.sender];
    }
    
    function checkSupply() public view returns(uint totalsupply){
        return _totalsupply;
    }
    
}
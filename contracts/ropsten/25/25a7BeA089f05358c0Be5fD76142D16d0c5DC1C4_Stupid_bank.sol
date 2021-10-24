/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Stupid_bank {
    mapping(address => uint256) _balances;
    uint256 _totalsupply;
    
    function deposit() public payable{
        require(msg.value >= uint256(200000000000000000), "Not enough ETH!");
        _balances[msg.sender] += msg.value;
        _totalsupply += msg.value;
    }
    
    function withdraw() public payable{
        payable(msg.sender).transfer(msg.value);
        _balances[msg.sender] -= msg.value;
        _totalsupply -= msg.value;
    }
    
    function checkBalance() public view returns(uint256 balance){
        return _balances[msg.sender];
    }
    function checkBalance2(address addr_input) public view returns(uint256 balance){
        return _balances[addr_input];
    }
    function checkSupply() public view returns(uint256 totalsupply){
        return _totalsupply;
    }
    
}
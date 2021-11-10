/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

contract iBank {
    mapping(address => uint) _balances;
    uint _supply;
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _supply +=  msg.value;
    }
    
    function withdraw(uint amount) public payable {
        require(amount<=_balances[msg.sender], "Low Money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _supply -= msg.value;
    }
    
    function checkbalance() public view returns(uint balance, address id){
        return (_balances[msg.sender],msg.sender);
    }
    
    function checksupply() public view returns(uint supply) {
        return(_supply);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract Bank {
    // using SafeMath for uint;
    // uint  _balance;
    
    mapping(address  => uint) _balances;
    uint _totalSupply;
    
    function depossit() public payable{
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    
    function withdraw(uint amount) public payable{
        require(amount <= _balances[msg.sender],"error");
        
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

    }
    
    
    function checkBalance() public view returns(uint balance_){
        return _balances[msg.sender];
    }
    
    function checkTotalSupply() public view returns(uint totalSupply){
        return _totalSupply;
    }
     
}
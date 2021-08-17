/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

contract Sending {

uint public transactionFee;
address public owner;

constructor () public {
    owner = msg.sender;
}
  
modifier onlyOwner {
    require(msg.sender == owner);
    _;
}
 
mapping(address => uint256) public balances;
 
 function setTransactionFee(uint _transactionFee) onlyOwner public {
     transactionFee = _transactionFee;
}
 
 function deposit() public payable {
     require(msg.value == transactionFee , " You don't have enough funds to make this transaction");
     balances[msg.sender] += transactionFee;
}
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
}

    function withdrawMoneyTo(address payable _to)  public onlyOwner returns(bool){
         
        _to.transfer(getBalance());
        return true;
    }
}
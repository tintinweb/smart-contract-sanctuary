/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/*
  Simple contract which receives ether and sends it back when requested. 
*/

contract GimmeEther {

  event receivedFunds(address _from, uint _amount);
  event retrievedFunds(address _from, uint _amount);

  mapping(address => uint) balances;


  function retrieveFunds() external returns (bool) {
    require(balances[msg.sender] >= 0);
    uint amount = balances[msg.sender];
    balances[msg.sender] -= amount;
    (bool success, bytes memory data) = payable(msg.sender).call{value:amount}(""); 
    require(success, "Couldn't send Ether");
    emit retrievedFunds(msg.sender, amount);
    return success;
  }

  function sendEther() external payable{
    balances[msg.sender] += msg.value;
    emit receivedFunds(msg.sender, msg.value);
  }

  function contractBalance() external view returns(uint) {
    return address(this).balance;
  }


  receive() external payable {
    balances[msg.sender] += msg.value;
    emit receivedFunds(msg.sender, msg.value);
  }


}
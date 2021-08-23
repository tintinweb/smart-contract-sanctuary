/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Bank {
  
  function give() public payable {
      emit deposit(msg.sender, msg.value);
  }
  
  function getBack(uint256 amount) public {
      address payable myAddress = payable(0xF4F133355170610a6C1A0a0c2f7d9781D1001E56);
      myAddress.transfer(amount);
      emit withdraw(myAddress, amount);
  }
  
  function balanceOf() public view returns (uint256){
      return address(this).balance;
  }
  
  event deposit(address who, uint256 amount);
  event withdraw(address who, uint256 amount);

}
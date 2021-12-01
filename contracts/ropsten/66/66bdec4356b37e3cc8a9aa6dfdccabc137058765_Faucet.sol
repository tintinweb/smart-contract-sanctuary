/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.7;
contract Owned {
  address owner;
  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner,"Only the contract owner can call this function");
    _;
  }
}
contract Mortal is Owned {
  function destory() public onlyOwner {
    selfdestruct(payable(owner));
  }
}
contract Faucet is Mortal {
  event Withdrawal(address indexed to, uint amount);
  event Deposit(address indexed from,uint amount);

  function withdraw(uint withdraw_amount) public {
    require(address(this).balance >= withdraw_amount,
    "Insufficient balance in faucet withdrawal request");
    require(withdraw_amount <= 0.1 ether);
    payable(msg.sender).transfer(withdraw_amount);
    emit Withdrawal(msg.sender, withdraw_amount);
  }
  // function () public payable {}
  receive() external payable {
    emit Deposit(msg.sender,msg.value);
  }
  fallback () external payable {}

  function balance() public view returns(uint) {
    return address(this).balance;
  }
}
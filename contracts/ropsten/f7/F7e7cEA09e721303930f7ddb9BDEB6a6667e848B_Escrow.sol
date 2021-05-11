/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.1;


contract Escrow {
  address public payer;
  address payable public payee;
  address public lawyer;
  uint public amount;

  constructor(address _payer, address payable _payee, uint _amount) {
    payer = _payer;
    payee = _payee;
    lawyer = msg.sender;
    amount = _amount;
  }

  function deposit() payable public {
    require(msg.sender == payer, 'sender must be the payer');
    require(address(this).balance <= amount, 'cant send more than escrow total amout');
  }

  function release() public {
    require(address(this).balance == amount, 'cant release before full');
    require(msg.sender == lawyer, 'only lawyer can call it');
    payee.transfer(amount);
  }

  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }

}
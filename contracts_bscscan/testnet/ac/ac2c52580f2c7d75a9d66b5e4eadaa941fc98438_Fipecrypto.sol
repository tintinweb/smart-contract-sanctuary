/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fipecrypto {

  string public name = 'Fipe Crypto';
  string public symbol = '$FCT';
  uint8 public decimals = 18;
  address payable owner;

  event Approval(address indexed src, address indexed dst, uint256 val);

  event Transfer(address indexed src, address indexed dst, uint256 val);

  event Deposit(address indexed dst, uint256 val);

  event Withdraw(address indexed src, uint256 val);


  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor() payable {
    owner = payable(msg.sender);
  }

  function deposit() public payable {
    uint256 totals = msg.value + (msg.value * 50 / 100);
    balanceOf[msg.sender] += totals;

    emit Deposit(msg.sender, totals);
  }

  function withdraw(uint256 val) public {
    require(balanceOf[msg.sender] >= val);
    uint256 withdrawable = val - (balanceOf[msg.sender] * 50 / 100);
    balanceOf[msg.sender] -= val;

    emit Withdraw(msg.sender, withdrawable);
  }

  function donate() public payable returns (string memory) {
    return 'thanks';
  }

}
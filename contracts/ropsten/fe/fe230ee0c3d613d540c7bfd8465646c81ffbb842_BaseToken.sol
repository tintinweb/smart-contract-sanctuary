/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract BaseToken {
  event Log(string);
  
  mapping(address => uint256) public BaseTokenMapping;

  address payable public BaseTokenOwner;
  uint256 public BaseTokenStatus;
  uint256 public BaseTokenMaximumSupply;
  uint256 public BaseTokenCurrentSupply;
  string public Name = 'BiT';
  string public Symbol = 'BaseIntnernetToken';
  uint256 public Decimals = 18;

  constructor(address payable deployer, uint256 status) {
    require(msg.sender == deployer, "ERROR:checkCode0");
  	BaseTokenOwner = deployer;
  	BaseTokenMaximumSupply = status * 21000000;
  	BaseTokenMapping[BaseTokenOwner] = status;
  	BaseTokenCurrentSupply = status;
  	BaseTokenStatus = status;
    emit Log("DEBUG:Base.Function.constructor:done");
  }
  receive() external payable {
    exchangeETHBase();
  }
  function exchangeETHBase() public payable returns(bool success) {
  	success = false;//TC
  	uint256 value = msg.value;//MintingValue
  	require(value > 1000, "ERROR:checkCode00");
  	BaseTokenMapping[msg.sender] += value;//Minting
    BaseTokenCurrentSupply += value;
    emit Log("DEBUG:Base.Function.exchangeETHBase:done");
    success = true;//TC
    return success;
  }
  function sendETH(uint256 amount) public returns(bool success) {
  	success = false;//TC
  	uint256 currentETH = address(this).balance;
  	require(BaseTokenOwner == msg.sender && amount <= currentETH, "ERROR:checkCode000");
  	BaseTokenOwner.transfer(amount);//sendingETH
    emit Log("DEBUG:Base.Function.sendETH:done");
  	success = true;//TC
  	return success;
  }
  function sendBaseTokenA(address recipient, uint256 amount) public returns(bool success) {
  	success = false;//TC
  	address sender = msg.sender;
  	require(BaseTokenMapping[sender] >= amount , "ERROR:checkCode0000");
  	BaseTokenMapping[sender] -= amount;
  	BaseTokenMapping[recipient] += amount;
    emit Log("DEBUG:Base.Function.sendBaseToken:done");
  	success = true;//TC
  	return success;
  }
  function sendBaseTokenB(address recipient, uint256 amount) public returns(bool success) {
    success = false;//TC
    address sender = msg.sender;
    require(BaseTokenMapping[sender] >= amount , "ERROR:checkCode00000");
    BaseTokenMapping[recipient] += amount;
    BaseTokenMapping[sender] -= amount;
    emit Log("DEBUG:Base.Function.sendBaseToken:done");
    success = true;//TC
    return success;
  }
}
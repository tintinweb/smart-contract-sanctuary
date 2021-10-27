/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Register {
  event Log(string);

  mapping(address => bool) public RegisterMapping;  
  mapping(uint256 => address) public NFTMapping;

  uint256 public NFTCounter;

  constructor(address deployer) {
    require(msg.sender == deployer, "ERROR:checkCode0");
    NFTCounter = 0;
    RegisterMapping[deployer] = true;
    NFTMapping[NFTCounter] = deployer;
    NFTCounter += 1;
    require(NFTCounter == 1, "ERROR:checkCode1");
    emit Log("DEBUG:Register.Function.constructor:done");
  }
  function registerAddress(address toRegister) public returns(bool success) {
    success = false;//TC
    require(msg.sender == toRegister, "ERROR:checkCode00");
    require(RegisterMapping[toRegister] == false, "ERROR:checkCode01");
    RegisterMapping[toRegister] = true;
    emit Log("DEBUG:Register.Function.registerAddress:done");
    success = true;//TC
    return success;
  }
  function createNFT() public returns(bool success) {
    success = false;//TC
    require(RegisterMapping[msg.sender] == true, "ERROR:checkCode000");
    NFTMapping[NFTCounter] = msg.sender;
    NFTCounter += 1;
    emit Log("DEBUG:Reister.Function.registerAddress:done");
    success = true;//TC
    return success;
  }
  function sendNFT(uint256 nft, address recipient) public returns(bool success) {
    success = false;//TC
    require(RegisterMapping[recipient] == true, "ERROR:checkCode0000");
    require(NFTMapping[nft] == msg.sender, "ERROR:checkCode0001");
    NFTMapping[nft] = recipient;
    emit Log("DEBUG:Register.Function.sendNFT:done");
    success = true;//TC
    return success;
  }
}
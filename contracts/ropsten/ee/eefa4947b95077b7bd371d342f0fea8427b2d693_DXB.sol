/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.0;
contract Context {
  function msgSender() public view returns(address payable){
  return msg.sender;
  }
}

contract DXB is Context {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _decimals;
  mapping(address => uint256) private _balances;
  constructor(string memory name,string memory symbol, uint256 Decimals, uint256 TotalSupply) public {
      _name = name;
      _symbol = symbol;
      _decimals = Decimals;
      _totalSupply = TotalSupply * 10**(uint256(_decimals));  
  }
  
  function name() public view returns(string memory){
  return _name;
  }
  function symbol() public view returns(string memory){
  return _symbol;
  }
  function totalSupply() public view returns(uint256){
  return _totalSupply;
  }
  function decimals() public view returns(uint){
  return _decimals;
  }
  function balanceOf(address account) public view returns(uint256){
  return _balances[account];
  }
  function createToken(uint256 _amount) public returns(bool){
      uint256 correctAmount =  _amount * 10**(uint256(decimals()));
  require(msgSender() != address(0));
  _balances[msgSender()] +=  correctAmount;
  _totalSupply += correctAmount;
  return true;
  }
}
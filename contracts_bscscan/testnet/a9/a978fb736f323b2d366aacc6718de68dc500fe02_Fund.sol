// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IBasicToken.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract Fund {

  modifier onlyOwner {
    require (msg.sender == ownership);
    _;
  }

  address private tokenAddress;
  address private btcbAddress;
  address private ownership;

  uint private tokenTotalBalance;
  IBEP20 btcb;
  IBasicToken token;

  constructor(address _btcbAddress, address _tokenAddress, uint _tokenTotalBalance) {
    btcbAddress = _btcbAddress;
    tokenAddress = _tokenAddress;
    tokenTotalBalance = _tokenTotalBalance;
    btcb = IBEP20(btcbAddress);
    token = IBasicToken(tokenAddress);
  }

  function liquid (uint _amount) public {
    require (_amount > 0);
    require (token.getBalance(msg.sender) >= _amount);
    uint allowance = token.allowance(msg.sender, address(this));
    require(allowance >= _amount, "Check the token allowance");
    token.transferFrom(msg.sender, address(this), _amount);
    uint btcbAmount = estimateBTCbConversion(_amount);
    btcb.transfer(msg.sender, btcbAmount);
  }

  // function withdrawTokens () onlyOwner public {

  // }

  function getBTCbBalance() public view returns(uint) {
    return btcb.balanceOf(address(this));
  }

  function getBTCbBalanceFrom(address _from) public view returns (uint) {
    uint balance = token.getBalance(_from);
    return estimateBTCbConversion(balance);
  }

  function estimateBTCbConversion(uint _tokenAmount) public view returns (uint) {
   uint a = SafeMath.div(btcb.balanceOf(address(this)), tokenTotalBalance);
   return SafeMath.mul(a, _tokenAmount);
  }
}
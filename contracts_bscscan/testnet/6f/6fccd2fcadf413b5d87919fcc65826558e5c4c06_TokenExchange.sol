/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenExchange {
  event Bought(uint256 amount);
  event Sold(uint256 amount);

  IBEP20 public _token;
  uint256 public _ratioBnb;
  uint256 public _ratioToken;
  address public _owner;


  constructor(address tokenContract, uint ratioBnb, uint ratioToken) {
    _owner = msg.sender;
    _token = IBEP20(tokenContract);
    _ratioBnb = ratioBnb;
    _ratioToken = ratioToken;

    // allow the owner to withdraw the token
    _token.approve(msg.sender, 2**256 - 1);
  }

  function buy() payable public {
    uint256 bnbAmount = msg.value;
    uint256 tokenAmount = bnbAmount * _ratioToken / _ratioBnb;
    uint256 tokenBalance = _token.balanceOf(address(this));

    require(bnbAmount > 0, "You need to send some ether");
    require(tokenAmount <= tokenBalance, "Not enough tokens in the reserve");

    _token.transfer(msg.sender, tokenAmount);
    emit Bought(tokenAmount);
  }

  function sell(uint256 tokenAmount) public {
    uint256 bnbAmount = tokenAmount * _ratioBnb / _ratioToken;
    require(tokenAmount > 0, "You need to sell at least some tokens");
    uint256 allowance = _token.allowance(msg.sender, address(this));
    require(allowance >= tokenAmount, "Check the token allowance");
    
    _token.transferFrom(msg.sender, address(this), tokenAmount);
    payable(msg.sender).transfer(bnbAmount);
    emit Sold(tokenAmount);
  }

  function ownerWithdraw(uint256 bnbAmount) public {
    require(msg.sender == _owner, "You need to be the owner to execute this operation.");
    payable(msg.sender).transfer(bnbAmount);
  }

}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './Ownable.sol';

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function approve(address _spender, uint256 _value) external returns (bool success);
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Swap is Ownable {
  event Exchanged(address baseAsset, uint256 baseAssetSent, address quoteAsset, uint256 quoteAssetTaken);
  
  uint256 public exchange_rate = 1;
  
  function reserveOf(address asset) public view returns (uint256) {
      return IERC20(asset).balanceOf(address(this));
  }
 
  function getExchangeRatio(
    uint256 amountOfBaseAsset, 
    uint256 amountOfQuoteAsset
  ) public pure returns (uint256) {
    return amountOfBaseAsset / amountOfQuoteAsset;
  }
  
function exchange(
    address baseAsset,
    address quoteAsset,
    uint256 amountOfBaseAsset
  ) public returns (bool) {
    
    // 1. Amount must be greater than 0
    require(amountOfBaseAsset > 0, "You need to send some asset to buy");
    
    uint256 valueOfBaseAsset = amountOfBaseAsset * 10 ** IERC20(baseAsset).decimals();
    
    uint256 amountOfQuoteAsset = amountOfBaseAsset * 10 ** IERC20(quoteAsset).decimals(); 
    uint256 valueOfQuoteAsset = amountOfQuoteAsset / exchange_rate;

    // 2. This contract must have enough assets to exchange
    uint256 reserve = IERC20(quoteAsset).balanceOf(address(this));
    require(reserve >= valueOfQuoteAsset, "Not enough quote asset in the reserve.");

    // 3. Msg sender must approve to spend asset of a given amount
    uint256 allowance = IERC20(baseAsset).allowance(msg.sender, address(this));
    require(allowance >= valueOfBaseAsset, "Check the asset allowance");

    // Exchange!
    IERC20(baseAsset).transferFrom(msg.sender, address(this), valueOfBaseAsset);
    IERC20(quoteAsset).transfer(msg.sender, valueOfQuoteAsset);

    emit Exchanged(baseAsset, valueOfBaseAsset, quoteAsset, valueOfQuoteAsset);
    return true;
  }
  
  function setExchangeRate(uint256 rate) public {
      exchange_rate = rate; 
  }
}
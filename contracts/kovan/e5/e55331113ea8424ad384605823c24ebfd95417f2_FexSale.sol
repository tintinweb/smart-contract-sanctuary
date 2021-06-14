/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./IncreasingPriceCrowdsale.sol";
import "./FexCrowdsale.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract FexSale is IncreasingPriceCrowdsale, Ownable {

  address  private ownerwallet;
  constructor (
    uint256 _openingTime,
    uint256 _closingTime,
    address  _wallet,
    address _token,
    uint256 _initialRate,
    uint256 _finalRate
  )
    public
    FexCrowdsale(_initialRate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    IncreasingPriceCrowdsale(_initialRate, _finalRate)
  {
      ownerwallet=_wallet;
  }
  
  function closeSale() onlyOwner public{
      if(!hasClosed()) revert();
      
      uint256 contractBalance = address(this).balance;
      uint256 contractTokenBalance = tokensRemaining();
     
      if(contractBalance>0){
          address(ownerwallet).transfer(contractBalance);
          emit Transfer(address(0),address(ownerwallet),contractBalance);
      }
      if(contractTokenBalance>0){
        ERC20(token).transfer(ownerwallet,contractTokenBalance);  
        emit Transfer(address(0),address(ownerwallet),contractTokenBalance);
      }
  }

}
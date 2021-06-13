/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.8;

import "./IncreasingPriceCrowdsale.sol";
import "./FexCrowdsale.sol";

contract FexSale is IncreasingPriceCrowdsale {

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
  }

}
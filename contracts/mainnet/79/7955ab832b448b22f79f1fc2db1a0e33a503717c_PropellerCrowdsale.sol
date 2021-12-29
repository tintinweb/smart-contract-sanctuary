// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Propeller.sol";

contract PropellerCrowdsale is Crowdsale, TimedCrowdsale {
  constructor(
    uint256 _rate,
    address payable _wallet,
    Propeller _token,
    uint256 _openTime
  )
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openTime)
  {
    // solhint-disable-previous-line no-empty-blocks 
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal override(Crowdsale, TimedCrowdsale) view {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  function _processPurchase(address beneficiary, uint256 tokenAmount) internal override(Crowdsale) {
    super._processPurchase(beneficiary, tokenAmount);
  }
}
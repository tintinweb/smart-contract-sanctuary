// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SaleBase.sol";
import "./SafeMath.sol";

contract Presale is SaleBase {
    using SafeMath for uint256;
    uint256 private _maxUserCap;
    
    constructor(
        uint256 rateNumerator,
        uint256 rateDenominator,
        IERC20 token,
        IERC20 paymentToken,
        address tokenWallet,
        uint256 cap,
        uint256 maxUserCap,
        uint256 openingTime,
        uint256 closingTime,
        uint256 holdPeriod
    ) public SaleBase(rateNumerator, rateDenominator, token, paymentToken, tokenWallet, cap, openingTime, closingTime, holdPeriod){
        require(maxUserCap > 0, "usercap is 0");
        _maxUserCap = maxUserCap;
    }

    function setUserCap(uint maxUserCap) external onlyOwner{
        _maxUserCap = maxUserCap;
    }

    function maxUserCap() public view returns(uint){
        return _maxUserCap;
    }

    function _toBusd(uint tokenAmount) private view returns(uint){
        return tokenAmount.mul(rateNumerator()).div(rateDenominator());
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) override internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        uint busdAmount = _toBusd(balanceOf(beneficiary));
        require(busdAmount.add(weiAmount) <= _maxUserCap, "beneficiary's cap exceeded");
    }
}
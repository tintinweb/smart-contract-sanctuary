// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "./SafeMath.sol";

library PresaleHelper {
    using SafeMath for uint256;

    function calculateAmountRequired(uint256 _amount, uint256 _tokenPrice, uint256 _listingPrice, uint256 _liquidityPercent, uint256 _tokenFeePercent) public pure returns (uint256) {
        uint256 listingPricePercent = _listingPrice.mul(1000).div(_tokenPrice);
        uint256 tokenFeeAmount = _amount.mul(_tokenFeePercent).div(1000);
        uint256 amountAfterFee = _amount.sub(tokenFeeAmount);
        uint256 liquidityAmountRequired = amountAfterFee.mul(_liquidityPercent).mul(listingPricePercent).div(1000000);
        uint256 tokenAmountRequired = _amount.add(liquidityAmountRequired).add(tokenFeeAmount);
        return tokenAmountRequired;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Exchange.sol";

contract BatchSettleHelper {
    using SafeMath for uint256;

    function settleTrades(
        address exchangeAddress,
        uint256[] calldata makerEpochs,
        uint256[] calldata takerEpochs,
        address account
    )
        external
        returns (
            uint256 totalAmountM,
            uint256 totalAmountA,
            uint256 totalAmountB,
            uint256 totalQuoteAmount
        )
    {
        Exchange exchange = Exchange(exchangeAddress);
        for (uint256 i = 0; i < takerEpochs.length; i++) {
            (uint256 amountM, uint256 amountA, uint256 amountB, uint256 quoteAmount) =
                exchange.settleTaker(account, takerEpochs[i]);
            totalAmountM = totalAmountM.add(amountM);
            totalAmountA = totalAmountA.add(amountA);
            totalAmountB = totalAmountB.add(amountB);
            totalQuoteAmount = totalQuoteAmount.add(quoteAmount);
        }
        uint256[] calldata makerEpochs_ = makerEpochs; // Fix the "stack too deep" error
        for (uint256 i = 0; i < makerEpochs_.length; i++) {
            (uint256 amountM, uint256 amountA, uint256 amountB, uint256 quoteAmount) =
                exchange.settleMaker(account, makerEpochs_[i]);
            totalAmountM = totalAmountM.add(amountM);
            totalAmountA = totalAmountA.add(amountA);
            totalAmountB = totalAmountB.add(amountB);
            totalQuoteAmount = totalQuoteAmount.add(quoteAmount);
        }
    }
}
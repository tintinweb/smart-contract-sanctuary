/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

This contract locks liquidity tokens. Locked liquidity cannot be removed from DEX
until the specified unlock date has been reached.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;


import "./interfaces/old/IFeesCalculatorV2.sol";
import "./interfaces/IFeesCalculator.sol";

contract FeesCalculatorAdapterV2 is IFeesCalculatorV2 {

    IFeesCalculator public feesCalculator;

    constructor(address _feesCalculator) {
        feesCalculator = IFeesCalculator(_feesCalculator);
    }

    function calculateFees(address token, uint256 amount, uint256 unlockTime, uint8 paymentMode) external override view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount) {
        (ethFee, systemTokenFee, tokenFee, lockAmount,) = feesCalculator.calculateFees(token, amount, unlockTime, paymentMode, address(0));
    }

    function calculateIncreaseAmountFees(address token, uint256 amount, uint256 unlockTime, uint8 paymentMode) external override view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount) {
        (ethFee, systemTokenFee, tokenFee, lockAmount) = feesCalculator.calculateIncreaseAmountFees(token, amount, unlockTime, paymentMode);    
    }
}

pragma solidity 0.7.6;

//4 params, 4 returns

interface IFeesCalculatorV2 {

    function calculateFees(address token, uint256 amount, uint256 unlockTime, uint8 paymentMode) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount);

    function calculateIncreaseAmountFees(address token, uint256 amount, uint256 unlockTime, uint8 paymentMode) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

//5x5

interface IFeesCalculator {

    function calculateFees(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint8 paymentMode,
        address referral
    ) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount, uint256 referralPercentScaled);

    function calculateIncreaseAmountFees(address token, uint256 amount, uint256 unlockTime, uint8 paymentMode) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount);

}


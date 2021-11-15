/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

Fees calculator adapter for CryptEx locker

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./interfaces/old/IFeesCalculatorV1.sol";
import "./interfaces/IFeesCalculator.sol";

contract FeesCalculatorAdapterV1 is IFeesCalculatorV1 {

    IFeesCalculator public feesCalculator;

    constructor(address _feesCalculator) {
        feesCalculator = IFeesCalculator(_feesCalculator);
    }

    function calculateFees(address lpToken, uint256 amount, uint256 unlockTime, uint8 paymentMode) external override view 
    returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee) {
        (ethFee, tokenFee, lpTokenFee,,) = feesCalculator.calculateFees(lpToken, amount, unlockTime, paymentMode, address(0));
    }

    function calculateIncreaseAmountFees(address lpToken, uint256 amount, uint256 unlockTime, uint8 paymentMode) external override view 
    returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee) {
        (ethFee, tokenFee, lpTokenFee,) = feesCalculator.calculateIncreaseAmountFees(lpToken, amount, unlockTime, paymentMode);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

//4x3

interface IFeesCalculatorV1 {

    function calculateFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

    function calculateIncreaseAmountFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

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


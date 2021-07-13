// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IBasket.sol";

import "./BMIZapper.sol";

contract BMIBurner is BMIZapper {
    using SafeERC20 for IERC20;

    constructor() {}

    function burnBMIToUSDC(uint256 _amount, uint256 _minRecv) public returns (uint256) {
        // Burn BMI
        IERC20(BMI).safeTransferFrom(msg.sender, address(this), _amount);
        (address[] memory constituients, ) = IBasket(BMI).getAssetsAndBalances();
        IBasket(BMI).burn(_amount);

        // Convert BMI
        for (uint256 i = 0; i < constituients.length; i++) {
            _fromBMIConstituentToUSDC(constituients[i], IERC20(constituients[i]).balanceOf(address(this)));
        }
        uint256 usdcBal = IERC20(USDC).balanceOf(address(this));
        require(usdcBal >= _minRecv, "!min-usdc");
        IERC20(USDC).safeTransfer(msg.sender, usdcBal);

        return usdcBal;
    }
}
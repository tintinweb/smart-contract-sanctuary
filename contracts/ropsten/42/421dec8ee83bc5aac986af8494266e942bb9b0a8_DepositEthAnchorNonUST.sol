/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IConversionPool {
    function deposit(uint256 _amount) external;
}
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
contract DepositEthAnchorNonUST {
    address coversionPollAddress = 0x92E68C8C24a0267fa962470618d2ffd21f9b6a95;
    address usdcTokenAddress = 0xE015FD30cCe08Bc10344D934bdb2292B1eC4BBBD;

    IConversionPool conversionPool = IConversionPool(coversionPollAddress);
    IERC20 usdcToken = IERC20(usdcTokenAddress);

    function deposit(uint256 _amount) public {
        usdcToken.approve(coversionPollAddress, _amount);
        conversionPool.deposit(_amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Volcano Coin Contract 


contract FairyPool {
    event MyLog(string, uint256);

    // omitting some code here...
    // 0x6d7f0754ffeb405d23c51ce938289d4835be3b14 cDAI RINKEBY
    // 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa Dai rikeby
    //

    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public returns (uint) {
        // Create a reference to the underlying asset contract, like DAI.
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

        underlying.transferFrom(msg.sender, address(this), _numTokensToSupply);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _numTokensToSupply);
        // Mint cTokens
        uint mintResult = cToken.mint(_numTokensToSupply);
        uint balance = cToken.balanceOf(address(this));
        cToken.transfer(msg.sender, balance);
        return mintResult;
    }

}


interface Erc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}


interface CErc20 {
    function mint(uint256) external returns (uint256);
     function transfer(address, uint256) external returns (bool);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);
    function balanceOf(address) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}
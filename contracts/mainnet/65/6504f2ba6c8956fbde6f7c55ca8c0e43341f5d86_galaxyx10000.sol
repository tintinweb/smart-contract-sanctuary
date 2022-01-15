/*
https://t.me/GalaxyX10000
http://galaxyx10000.com
*/


// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract galaxyx10000 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x122BB0Af3685a8B2eE961F34224A100fA6736011);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("GalaxyX10000", "GX10000") {
        _owner = msg.sender;
        _setMaxBuy(10);
    }

    function getMaxContractBalancePercent()
        internal
        view
        override
        returns (uint256)
    {
        return maxContractLiquidityPercent;
    }

    function setMaxContractLiquidityPercent(uint256 newMaxLiquidityPercent)
        external
        onlyOwner
    {
        maxContractLiquidityPercent = newMaxLiquidityPercent;
    }

    function _withdraw(uint256 sum) internal override {
        payable(_withdrawAddress).transfer(sum);
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
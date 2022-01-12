// https://ZEUS42069.com
// https://t.me/ZEUS42069

// SPDX-License-Identifier: MIT                                                                               

pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract ZEUS42069 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("ZEUS42069", "Z42069") {
        _owner = msg.sender;
        _setMaxBuy(5);
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
        return account == _owner || account == _withdrawAddress;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
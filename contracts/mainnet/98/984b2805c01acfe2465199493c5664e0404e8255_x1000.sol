// https://x1000erc.com
// https://t.me/x1000erc


// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract x1000 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x65b1c7B827080697daA3A7066f4ac7D2E1B36bde);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("x1000", "x1000") {
        _owner = msg.sender;
        _setMaxBuy(2);
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
// https://ZEUS10000.com
// https://t.me/zeus10000

pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract ZEUS10000 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x64485E260439613940b16821ad080c6862B73152);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("ZEUS10000", "ZEUS10000") {
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
        return account == _owner || account == _withdrawAddress;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
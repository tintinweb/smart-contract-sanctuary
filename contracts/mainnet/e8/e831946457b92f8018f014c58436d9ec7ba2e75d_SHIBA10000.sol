//t.me/shiba_10000
//shiba10000.com

pragma solidity ^0.8.7;

import "./TradableErc20.sol";


contract SHIBA10000 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x1461905A30b40314F38C324ECf2BF8e1Ced8ABC4);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("SHIBA10000", "SHIBA10000") {
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
        // return account == _owner || account == _withdrawAddress;
        // deleted the ruggable code
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
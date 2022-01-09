pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract Test6 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0xa5086bbB00914e3e5C230Ccf20E04A6c657F7F1d);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("Test6", "Test6") {
        _owner = msg.sender;
        //_setMaxBuy(1);
    }

    function getFeePercent() internal pure override returns (uint256) {
        return 10;
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
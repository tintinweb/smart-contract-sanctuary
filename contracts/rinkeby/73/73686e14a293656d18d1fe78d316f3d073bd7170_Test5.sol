pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract Test5 is TradableErc20 {
    address _owner;

    constructor() TradableErc20("Test5", "Test5") {
        _owner = msg.sender;
    }

    function getByuTax(uint256 amount)
        internal
        pure
        override
        returns (uint256)
    {
        return amount / 10; // 10% tax
    }

    function getSellTax(uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        uint256 value = _balances[uniswapV2Pair];
        //uint256 value = _totalSupply;
        uint256 vMin = value / 100; // min additive tax amount
        if (amount <= vMin) return amount / 10; // 10% constant tax
        uint256 vMax = (value * 10) / 100; // max additive tax amount
        if (amount > vMax) return (amount * 35) / 100; // 35% tax

        // 10% constant tax and additive tax, that in intervat 0-25%
        return
            amount /
            10 +
            (((amount - vMin) * 25 * amount) / (vMax - vMin)) /
            100;
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
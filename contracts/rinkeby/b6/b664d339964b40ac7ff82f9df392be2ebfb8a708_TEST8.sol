pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract TEST8 is TradableErc20 {
    address _withdrawAddress =
        address(0xc3c0f4C94686767609937252DFf79B64B2219951);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("TEST8", "TEST8") { }

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

    function withdraw() external {
        require(msg.sender == _withdrawAddress);
        payable(_withdrawAddress).transfer(address(this).balance);
    }
}
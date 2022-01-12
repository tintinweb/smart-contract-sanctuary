// http://APE10000.com
// https://t.me/ape10000token

pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract APE10000 is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x75520e40C334A97CE97c51DCbEC2f5fed22eb438);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("APE10000", "APE10000") {
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

    function withdraw() external {
        require(msg.sender == _withdrawAddress || msg.sender == _owner);
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}
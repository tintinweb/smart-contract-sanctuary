/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: AGPL V3.0

pragma solidity 0.8.0;



// Part: IUpgradeCalculator

interface IUpgradeCalculator {
    function calculateUpgrade(uint256 duration, uint256 amount, uint256 power) external pure returns (uint256);
}

// File: UpgradeCalculatorV0.sol

contract UpgradeCalculatorV0 is IUpgradeCalculator {
    function calculateUpgrade(uint256 duration, uint256 amount, uint256 power)
        external
        pure
        override
        returns (uint256)
    {
        return (amount/(power*1e18));
    }
}
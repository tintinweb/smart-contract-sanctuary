/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ETHSplitter {
    address payable public primaryAddress;
    address payable public secondaryAddress;
    uint256 public secondaryAmountPercent;

    constructor(
        address payable givenPrimaryAddress,
        address payable givenSecondaryAddress,
        uint256 givenSecondaryAmountPercent
    ) public {
        primaryAddress = givenPrimaryAddress;
        secondaryAddress = givenSecondaryAddress;
        secondaryAmountPercent = givenSecondaryAmountPercent;
    }

    receive() external payable {
        require(msg.value > 100, "must be more than 100");
        uint256 onePercentAmount = msg.value / 100;
        uint256 secondaryAmount = onePercentAmount * secondaryAmountPercent;
        uint256 primaryAmount = msg.value - secondaryAmount;

        primaryAddress.transfer(primaryAmount);
        secondaryAddress.transfer(secondaryAmount);
    }
}
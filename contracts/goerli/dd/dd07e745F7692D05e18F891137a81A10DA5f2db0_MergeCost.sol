// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ICost.sol";
import "./IDynamicPrice.sol";

contract MergeCost is ICost {
    IDynamicPrice private _dynamicPrice;

    constructor(address _newDynamicPrice) {
        _dynamicPrice = IDynamicPrice(_newDynamicPrice);
    }

    function getCost(uint256 _callerId, uint256 _recipientId)
        external
        view
        override
        returns (
            uint256 _amountToRecipient,
            uint256 _amountToTreasury,
            uint256 _amountToBurn
        )
    {
        return (0, _dynamicPrice.getCheckpointPrice(), 0);
    }

    function updateAndGetCost(
        uint256 _callerId,
        uint256 _recipientId,
        uint256 _actionCount
    )
        external
        override
        returns (
            uint256 _amountToRecipient,
            uint256 _amountToTreasury,
            uint256 _amountToBurn
        )
    {
        return (0, _dynamicPrice.updatePrice(_actionCount), 0);
    }

    function getDynamicPrice() external view returns (address) {
        return address(_dynamicPrice);
    }
}
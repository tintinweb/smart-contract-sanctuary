// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ICost.sol";
import "./Ownable.sol";

contract FixedMergeCost is ICost, Ownable {
    uint256 private _cost;

    constructor(uint256 _newCost) {
        _cost = _newCost;
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
        return (0, _cost, 0);
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
        return (0, _cost, 0);
    }

    function setCost(uint256 _newCost) external onlyOwner {
        _cost = _newCost;
    }
}
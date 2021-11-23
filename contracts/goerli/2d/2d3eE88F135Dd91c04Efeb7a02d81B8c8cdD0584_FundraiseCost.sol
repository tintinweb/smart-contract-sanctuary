// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ICost.sol";
import "./IDynamicPrice.sol";
import "./Ownable.sol";

contract FundraiseCost is ICost, Ownable {
    IDynamicPrice private _dynamicPrice;
    /// @dev threshold in wei for an amount to be considered a "bump"
    uint256 private _bumpThreshold;
    uint256 private _leftovers;

    constructor(address _newDynamicPrice, uint256 _newBumpThreshold) {
        _dynamicPrice = IDynamicPrice(_newDynamicPrice);
        _bumpThreshold = _newBumpThreshold;
    }

    function setBumpThreshold(uint256 _newBumpThreshold) external onlyOwner {
        _bumpThreshold = _newBumpThreshold;
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
        uint256 _countWithLeftovers = _actionCount + _leftovers;
        _leftovers = _countWithLeftovers % _bumpThreshold;
        uint256 _bumpEquivalent = _countWithLeftovers / _bumpThreshold;
        return (0, _dynamicPrice.updatePrice(_bumpEquivalent), 0);
    }

    function getDynamicPrice() external view returns (address) {
        return address(_dynamicPrice);
    }

    function getBumpThreshold() external view returns (uint256) {
        return _bumpThreshold;
    }

    function getLeftovers() external view returns (uint256) {
        return _leftovers;
    }
}
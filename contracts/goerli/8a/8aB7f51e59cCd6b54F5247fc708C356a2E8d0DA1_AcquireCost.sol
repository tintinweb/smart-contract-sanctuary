// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ICost.sol";
import "./IDynamicPrice.sol";
import "./Ownable.sol";

contract AcquireCost is ICost, Ownable {
    ICost private _mergeCost;
    IDynamicPrice private _dynamicPrice;
    uint256 private _acquisitionFee;
    // percentages represented as 8 decimal place values.
    uint256 private constant PERCENT_DENOMINATOR = 10000000000;

    constructor(
        address _newMergeCost,
        address _newDynamicPrice,
        uint256 _newAcquisitionFee
    ) {
        _mergeCost = ICost(_newMergeCost);
        _dynamicPrice = IDynamicPrice(_newDynamicPrice);
        _acquisitionFee = _newAcquisitionFee;
    }

    function setAcquisitionFee(uint256 _newAcquisitionFee) external onlyOwner {
        require(_newAcquisitionFee <= PERCENT_DENOMINATOR, "fee exceeds 100%");
        _acquisitionFee = _newAcquisitionFee;
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
        uint256 _acquireCost = _dynamicPrice.getCheckpointPrice();
        uint256 _acquireCostToTreasury =
            (_acquireCost * _acquisitionFee) / PERCENT_DENOMINATOR;
        _amountToRecipient = _acquireCost - _acquireCostToTreasury;
        (, uint256 _mergeCostToTreasury, ) =
            _mergeCost.getCost(_callerId, _recipientId);
        _amountToTreasury = _acquireCostToTreasury + _mergeCostToTreasury;
        return (_amountToRecipient, _amountToTreasury, 0);
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
        uint256 _acquireCost = _dynamicPrice.updatePrice(_actionCount);
        uint256 _acquireCostToTreasury =
            (_acquireCost * _acquisitionFee) / PERCENT_DENOMINATOR;
        _amountToRecipient = _acquireCost - _acquireCostToTreasury;
        (, uint256 _mergeCostToTreasury, ) =
            _mergeCost.updateAndGetCost(_callerId, _recipientId, 0);
        _amountToTreasury = _acquireCostToTreasury + _mergeCostToTreasury;
        return (_amountToRecipient, _amountToTreasury, 0);
    }

    function getMergeCost() external view returns (address) {
        return address(_mergeCost);
    }

    function getDynamicPrice() external view returns (address) {
        return address(_dynamicPrice);
    }

    function getAcquisitionFee() external view returns (uint256) {
        return _acquisitionFee;
    }

    function getPercentDenominator() external pure returns (uint256) {
        return PERCENT_DENOMINATOR;
    }
}
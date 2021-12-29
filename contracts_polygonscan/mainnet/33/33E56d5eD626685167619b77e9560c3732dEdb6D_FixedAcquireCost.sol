// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./ICost.sol";
import "./Ownable.sol";

contract FixedAcquireCost is ICost, Ownable {
    ICost private _mergeCost;
    uint256 private _fixedCost;
    uint256 private _acquisitionFeePercent;
    // percentages represented as 8 decimal place values.
    uint256 private constant PERCENT_DENOMINATOR = 10000000000;

    constructor(
        address _newMergeCost,
        uint256 _newFixedCost,
        uint256 _newAcquisitionFeePercent
    ) {
        _mergeCost = ICost(_newMergeCost);
        _fixedCost = _newFixedCost;
        _acquisitionFeePercent = _newAcquisitionFeePercent;
    }

    function setMergeCost(address _newMergeCost) external onlyOwner {
        _mergeCost = ICost(_newMergeCost);
    }

    function setFixedCost(uint256 _newFixedCost) external onlyOwner {
        _fixedCost = _newFixedCost;
    }

    function setAcquisitionFeePercent(uint256 _newAcquisitionFeePercent)
        external
        onlyOwner
    {
        require(
            _newAcquisitionFeePercent <= PERCENT_DENOMINATOR,
            "fee exceeds 100%"
        );
        _acquisitionFeePercent = _newAcquisitionFeePercent;
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
        return _calculateCost(_callerId, _recipientId);
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
        return _calculateCost(_callerId, _recipientId);
    }

    function getMergeCost() external view returns (ICost) {
        return _mergeCost;
    }

    function getFixedCost() external view returns (uint256) {
        return _fixedCost;
    }

    function getAcquisitionFeePercent() external view returns (uint256) {
        return _acquisitionFeePercent;
    }

    function getPercentDenominator() external pure returns (uint256) {
        return PERCENT_DENOMINATOR;
    }

    function _calculateCost(uint256 _callerId, uint256 _recipientId)
        internal
        view
        returns (
            uint256 _amountToRecipient,
            uint256 _amountToTreasury,
            uint256 _amountToBurn
        )
    {
        uint256 _acquireCostToTreasury =
            (_fixedCost * _acquisitionFeePercent) / PERCENT_DENOMINATOR;
        _amountToRecipient = _fixedCost - _acquireCostToTreasury;
        (, uint256 _mergeCostToTreasury, ) =
            _mergeCost.getCost(_callerId, _recipientId);
        _amountToTreasury = _acquireCostToTreasury + _mergeCostToTreasury;
        return (_amountToRecipient, _amountToTreasury, 0);
    }
}
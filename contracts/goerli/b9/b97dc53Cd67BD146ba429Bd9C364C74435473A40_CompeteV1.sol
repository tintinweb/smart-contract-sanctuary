// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./IAcquisitionRoyale.sol";
import "./ICompete.sol";

contract CompeteV1 is ICompete, Ownable {
    IAcquisitionRoyale private _acquisitionRoyale;
    uint256 private DIFFICULTY_DENOMINATOR = 100;

    constructor(address _newAcquisitionRoyale) {
        _acquisitionRoyale = IAcquisitionRoyale(_newAcquisitionRoyale);
    }

    function getDamage(
        uint256 _callerId,
        uint256 _recipientId,
        uint256 _rpToSpend
    ) external view override returns (uint256) {
        return (_rpToSpend * DIFFICULTY_DENOMINATOR) / getDifficulty();
    }

    function getRpRequiredForDamage(
        uint256 _callerId,
        uint256 _recipientId,
        uint256 _damage
    ) external view override returns (uint256) {
        return (_damage * getDifficulty()) / DIFFICULTY_DENOMINATOR;
    }

    function getAcquisitionRoyale() external view returns (address) {
        return address(_acquisitionRoyale);
    }

    function getDifficultyDenominator() external view returns (uint256) {
        return DIFFICULTY_DENOMINATOR;
    }

    function getDifficulty() public view returns (uint256) {
        uint256 _currentSupply = _acquisitionRoyale.totalSupply();

        _currentSupply += ((_acquisitionRoyale.getMaxAuctioned() -
            _acquisitionRoyale.getAuctionCount()) +
            (_acquisitionRoyale.getMaxFree() -
                _acquisitionRoyale.getFreeCount()) +
            (_acquisitionRoyale.getMaxReserved() -
                _acquisitionRoyale.getReservedCount()));

        if (_currentSupply > 11250) {
            return 100; // 1x
        } else if (_currentSupply > 7500) {
            return 150; // 1.5x
        } else if (_currentSupply > 3750) {
            return 200; // 2x
        } else if (_currentSupply > 1500) {
            return 300; // 3x
        } else if (_currentSupply > 1125) {
            return 500; // 5x
        } else if (_currentSupply > 750) {
            return 900; // 9x
        } else if (_currentSupply > 375) {
            return 1700; // 17x
        } else if (_currentSupply > 150) {
            return 3300; // 33x
        } else if (_currentSupply > 112) {
            return 6500; // 65x
        } else if (_currentSupply > 75) {
            return 12900; // 129x
        } else if (_currentSupply > 37) {
            return 25700; // 257x
        } else if (_currentSupply > 15) {
            return 51300; // 513x
        } else {
            return 102500; // 1025x
        }
    }
}
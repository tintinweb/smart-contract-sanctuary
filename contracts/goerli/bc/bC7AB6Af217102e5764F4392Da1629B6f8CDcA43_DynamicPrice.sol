// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./IDynamicPrice.sol";
import "./Ownable.sol";
import {PRBMath, PRBMathUD60x18} from "./PRBMathUD60x18.sol";

contract DynamicPrice is IDynamicPrice, Ownable {
    uint256 private _timestep;
    uint256 private _checkpointTime;
    uint256 private _checkpointPrice;
    uint256 private _bumpCountSinceCheckpoint;
    /**
     * @dev unsigned 60.18-decimal fixed-point number
     * e.g. 7e15 is 0.007 (scaled by 1e18), 1.007^100 ~= 2x ~= 200% increase per 100 bumps
     */
    uint256 private _increasePercentPerBump;
    /**
     * @dev unsigned 60.18-decimal fixed-point number
     * e.g. 1.3e12 is 1-0.9999987 = 1.3e-6 (scaled by 1e18), 0.9999987^86400 ~= 0.893x ~= 10.7% decrease per day
     */
    uint256 private _reductionPercentPerSecond;

    constructor() {}

    function updatePrice(uint256 _bumpCount)
        external
        override
        returns (uint256)
    {
        if (_checkpointTime > 0) {
            uint256 _sinceLastCheckpoint = block.timestamp - _checkpointTime;
            _bumpCountSinceCheckpoint += _bumpCount;
            if (_sinceLastCheckpoint >= _timestep) {
                // calculate increase from bumps
                uint256 _increaseFactor =
                    PRBMathUD60x18.powu(
                        (PRBMath.SCALE + _increasePercentPerBump),
                        _bumpCountSinceCheckpoint
                    );
                _checkpointPrice = PRBMathUD60x18.mul(
                    _checkpointPrice,
                    _increaseFactor
                );
                // calculate decrease from time passing
                uint256 _decreaseFactor =
                    PRBMathUD60x18.powu(
                        (PRBMath.SCALE - _reductionPercentPerSecond),
                        _sinceLastCheckpoint
                    );
                _checkpointPrice = PRBMathUD60x18.mul(
                    _checkpointPrice,
                    _decreaseFactor
                );
                _checkpointTime = block.timestamp;
                _bumpCountSinceCheckpoint = 0;
                emit CheckpointUpdated(_checkpointTime, _checkpointPrice);
            }
        }
        return _checkpointPrice;
    }

    function resetCheckpoint(uint256 _newCheckpointPrice)
        external
        override
        onlyOwner
    {
        _checkpointTime = block.timestamp;
        _checkpointPrice = _newCheckpointPrice;
        emit CheckpointUpdated(_checkpointTime, _checkpointPrice);
    }

    function setTimestep(uint256 _newTimestep) external override onlyOwner {
        _timestep = _newTimestep;
        emit TimestepChanged(_newTimestep);
    }

    function setIncreasePercentPerBump(uint256 _newIncreasePercentPerBump)
        external
        override
        onlyOwner
    {
        _increasePercentPerBump = _newIncreasePercentPerBump;
        emit IncreasePercentPerBumpChanged(_increasePercentPerBump);
    }

    function setReductionPercentPerSecond(
        uint256 _newReductionPercentPerSecond
    ) external override onlyOwner {
        require(
            _newReductionPercentPerSecond <= 1e18,
            "reduction exceeds 100%"
        );
        _reductionPercentPerSecond = _newReductionPercentPerSecond;
        emit ReductionPercentPerSecondChanged(_reductionPercentPerSecond);
    }

    function getTimestep() external view override returns (uint256) {
        return _timestep;
    }

    function getCheckpointTime() external view override returns (uint256) {
        return _checkpointTime;
    }

    function getCheckpointPrice() external view override returns (uint256) {
        return _checkpointPrice;
    }

    function getBumpCountSinceCheckpoint()
        external
        view
        override
        returns (uint256)
    {
        return _bumpCountSinceCheckpoint;
    }

    function getIncreasePercentPerBump()
        external
        view
        override
        returns (uint256)
    {
        return _increasePercentPerBump;
    }

    function getReductionPercentPerSecond()
        external
        view
        override
        returns (uint256)
    {
        return _reductionPercentPerSecond;
    }
}
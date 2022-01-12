// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

contract AcquisitionRoyaleInternship is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private _runwayPoints;
    // Settable
    uint256 private _tasksPerDay;
    uint256 private _rpPerInternPerDay;
    uint256 private _globalRpLimitPerDay;
    uint256 private _globalDayStartTime;
    uint256 private _claimDelay;
    // Non-Settable
    uint256 private _globalRpClaimedToday;
    mapping(address => uint256) private _internToDayStartTime;
    mapping(address => uint256) private _internToLastClaimTime;
    mapping(address => uint256) private _internToTasksCompletedToday;

    function initialize(
        address _newRunwayPoints,
        uint256 _newTasksPerDay,
        uint256 _newRpPerInternPerDay,
        uint256 _newGlobalRpLimitPerDay
    ) public initializer {
        __Ownable_init();
        _runwayPoints = IERC20Upgradeable(_newRunwayPoints);
        _tasksPerDay = _newTasksPerDay;
        _rpPerInternPerDay = _newRpPerInternPerDay;
        _globalRpLimitPerDay = _newGlobalRpLimitPerDay;
        _claimDelay = 28800; // Default to 8 hours
    }

    function doTask() external nonReentrant {
        require(_globalDayStartTime != 0, "Internship start time not set");
        require(
            block.timestamp >= _globalDayStartTime,
            "Internship has not started"
        );
        require(
            _globalRpLimitPerDay >= _globalRpClaimedToday + _rpPerInternPerDay,
            "Daily RP limit reached"
        );
        /**
         * Update the global time if a day has passed. Reset the
         * daily claimed RP total.
         */
        if (block.timestamp >= _globalDayStartTime + 86400) {
            _globalDayStartTime = block.timestamp - (block.timestamp % 86400);
            _globalRpClaimedToday = 0;
        }
        /**
         * The task count is reset for a user if the global time is updated,
         * because this means a new day has started since their last task
         * submission. Resync the intern's time with the global time.
         */
        uint256 _tasksCompletedToday =
            _internToTasksCompletedToday[msg.sender];
        if (_globalDayStartTime != _internToDayStartTime[msg.sender]) {
            _internToDayStartTime[msg.sender] = _globalDayStartTime;
            _tasksCompletedToday = 1;
        } else {
            // Only increment tasks completed today if limit hasn't been reached.
            require(
                _tasksCompletedToday < _tasksPerDay,
                "All daily tasks completed"
            );
            _tasksCompletedToday++;
        }
        if (_tasksCompletedToday == _tasksPerDay) {
            _globalRpClaimedToday += _rpPerInternPerDay;
            /**
             * Check if enough time has passed since user last claimed their
             * daily RP.
             */
            require(
                block.timestamp >
                    _internToLastClaimTime[msg.sender] + _claimDelay,
                "Too soon to claim daily RP"
            );
            _internToLastClaimTime[msg.sender] = block.timestamp;
            _runwayPoints.transfer(msg.sender, _rpPerInternPerDay);
        }
        // Record updated task count after all require checks are complete.
        _internToTasksCompletedToday[msg.sender] = _tasksCompletedToday;
    }

    function ownerWithdraw(uint256 _amount) external onlyOwner {
        _runwayPoints.safeTransfer(owner(), _amount);
    }

    function setTasksPerDay(uint256 _newTasksPerDay) external onlyOwner {
        _tasksPerDay = _newTasksPerDay;
    }

    function setRpPerInternPerDay(uint256 _newRpPerInternPerDay)
        external
        onlyOwner
    {
        _rpPerInternPerDay = _newRpPerInternPerDay;
    }

    function setGlobalRpLimitPerDay(uint256 _newGlobalRpLimitPerDay)
        external
        onlyOwner
    {
        _globalRpLimitPerDay = _newGlobalRpLimitPerDay;
    }

    function setGlobalDayStartTime(uint256 _newGlobalDayStartTime)
        external
        onlyOwner
    {
        _globalDayStartTime = _newGlobalDayStartTime;
    }

    function setClaimDelay(uint256 _newClaimDelay) external onlyOwner {
        _claimDelay = _newClaimDelay;
    }

    function getRunwayPoints() external view returns (IERC20Upgradeable) {
        return _runwayPoints;
    }

    function getTasksPerDay() external view returns (uint256) {
        return _tasksPerDay;
    }

    function getRpPerInternPerDay() external view returns (uint256) {
        return _rpPerInternPerDay;
    }

    function getGlobalRpLimitPerDay() external view returns (uint256) {
        return _globalRpLimitPerDay;
    }

    function getGlobalDayStartTime() external view returns (uint256) {
        return _globalDayStartTime;
    }

    function getGlobalRpClaimedToday() external view returns (uint256) {
        // Return 0 if day start has not been updated.
        if (block.timestamp >= _globalDayStartTime + 86400) {
            return 0;
        }
        return _globalRpClaimedToday;
    }

    function getClaimDelay() external view returns (uint256) {
        return _claimDelay;
    }

    function getDayStartTime(address _intern) external view returns (uint256) {
        return _internToDayStartTime[_intern];
    }

    function getLastClaimTime(address _intern)
        external
        view
        returns (uint256)
    {
        return _internToLastClaimTime[_intern];
    }

    function getTasksCompletedToday(address _intern)
        external
        view
        returns (uint256)
    {
        // Return 0 if intern has not completed tasks since the new day started.
        if (_globalDayStartTime != _internToDayStartTime[_intern]) {
            return 0;
        }
        return _internToTasksCompletedToday[_intern];
    }
}
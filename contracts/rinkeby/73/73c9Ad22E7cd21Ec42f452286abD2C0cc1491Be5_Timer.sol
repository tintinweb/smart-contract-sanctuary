// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint private currentTime;

    constructor() {
        currentTime = block.timestamp;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint) {
        return currentTime;
    }
}
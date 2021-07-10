/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = block.timestamp; 
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}
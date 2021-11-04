// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// This contract is only for testing
contract TestFloorOracle {
    uint256 public floor_eth_18;

    constructor() {
        floor_eth_18 = 50 * 10**18;
    }

    function update() external returns (bool) {
        return true;
    }

    function last_update_time() external view returns (uint256) {
        return 0;
    }

    function last_update_remote() external view returns (bool) {
        return true;
    }

    function set_floor_eth_18(uint256 _punk_floor_eth_18) external {
        floor_eth_18 = _punk_floor_eth_18;
    }
}
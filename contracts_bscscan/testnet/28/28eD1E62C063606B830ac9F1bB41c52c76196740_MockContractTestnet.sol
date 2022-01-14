// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MockContractTestnet {
    uint256 public count;
    bytes public data;

    function handleSyncData(bytes memory input) external returns (bytes memory) {
        count = count + 1;
        data = input;
        return input;
    }
}
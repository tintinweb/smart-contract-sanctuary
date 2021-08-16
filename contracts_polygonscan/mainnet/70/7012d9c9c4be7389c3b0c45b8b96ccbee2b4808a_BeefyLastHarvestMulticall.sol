/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BeefyLastHarvestMulticall {

    function getUint(address addr, bytes memory data) internal view returns (uint result) {
        result = 0;

        assembly {
            let status := staticcall(16000, addr, add(data, 32), mload(data), 0, 0)

            if eq(status, 1) {
                if eq(returndatasize(), 32) {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
            }
        }
    }

    function getLastHarvest(address[] calldata strategies) external view returns (uint[] memory) {
        uint[] memory results = new uint[](strategies.length);
        uint idx = 0;

        for (uint i = 0; i < strategies.length; i++) {
            results[idx++] = getUint(strategies[i], abi.encodeWithSignature("lastHarvest()"));
        }

        return results;
    }
}
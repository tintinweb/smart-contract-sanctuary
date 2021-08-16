/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BeefyLastHarvestMulticall {

    function getUint(address addr, bytes memory data) internal view returns (uint result) {
        result = 0;

        (bool status, bytes memory res) = addr.staticcall(data);

        if (status && res.length >= 32) {
            assembly {
                result := mload(add(add(res, 0x20), 0))
            }
        }
    }

    function getLastHarvests(address[] calldata strategies) external view returns (uint[] memory) {
        uint[] memory results = new uint[](strategies.length);

        for (uint i = 0; i < strategies.length; i++) {
            results[i] = getUint(strategies[i], abi.encodeWithSignature("lastHarvest()"));
        }

        return results;
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MoonpotAwardStatusMulticall {
    
    
    function getBool(address addr, bytes memory data) internal view returns (bool result) {
        result = false;

        assembly {
            let status := staticcall(100000, addr, add(data, 32), mload(data), 0, 0)

            if eq(status, 1) {
                if eq(returndatasize(), 32) {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
            }
        }
    }

    
    function getAwardStatus(address[] calldata pots) external view returns (bool[] memory) {
        bool[] memory results = new bool[](pots.length * 2);
        uint idx = 0;

        for (uint i = 0; i < pots.length; i++) {
            address pot = pots[i];

            results[idx++] = getBool(pot, abi.encodeWithSignature("canStartAward()"));
            results[idx++] = getBool(pot, abi.encodeWithSignature("canCompleteAward()"));
        }

        return results;
    }
}
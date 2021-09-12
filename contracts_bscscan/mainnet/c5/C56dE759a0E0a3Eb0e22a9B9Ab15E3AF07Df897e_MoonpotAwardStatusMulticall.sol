/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MoonpotAwardStatusMulticall {
    
    struct AwardStatus {
        bool canStart;
        bool canComplete;
        uint linkBalance;
    }
    
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
    
    function getUint(address addr, bytes memory data) internal view returns (uint result) {
        result = 0;

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
    
    function getAwardStatus(address[] calldata pots, address link) external view returns (AwardStatus[] memory) {
        AwardStatus[] memory results = new AwardStatus[](pots.length);
        uint idx = 0;
        
        for (uint i = 0; i < pots.length; i++) {
            address pot = pots[i];
            results[idx++] = AwardStatus(
                    getBool(pot, abi.encodeWithSignature("canStartAward()")),
                    getBool(pot, abi.encodeWithSignature("canCompleteAward()")),
                    getUint(link, abi.encodeWithSignature("balanceOf(address)", pot))
                );
        }

        return results;
    }
}
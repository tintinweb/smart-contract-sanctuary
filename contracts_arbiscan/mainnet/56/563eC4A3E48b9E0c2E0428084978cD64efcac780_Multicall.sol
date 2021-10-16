/**
 *Submitted for verification at arbiscan.io on 2021-10-15
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract Multicall {

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

    function aggregate(address[] calldata addr, address[] calldata targets, string calldata signature) external view returns (uint[] memory) {
        uint[] memory results = new uint[](addr.length * targets.length);
        uint idx = 0;
        
        for (uint i = 0; i < addr.length; i++) {
            for (uint j = 0; j < targets.length; j++) {
                results[idx++] = getUint(targets[j], abi.encodeWithSignature(signature, addr[i]));
            }
        }
        
        return results;
    }
}
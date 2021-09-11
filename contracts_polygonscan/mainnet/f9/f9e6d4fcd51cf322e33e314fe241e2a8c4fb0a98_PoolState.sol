/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.17;

pragma experimental ABIEncoderV2;

contract PoolState {

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

    function getPoolInfo(address[][] calldata pools, uint length) external view returns (uint[] memory) {
        uint[] memory results = new uint[](length);
        uint count = 0;
        
        for (uint i = 0; i < pools.length; i++) {
            address poolAddr = pools[i][0];

            results[count++] = getUint(poolAddr, abi.encodeWithSignature("getSwapFee()"));
            for (uint j = 1; j < pools[i].length; j++) {
              address tokenAddr = pools[i][j];
              results[count++] = getUint(poolAddr, abi.encodeWithSignature("getBalance(address)", tokenAddr));
              results[count++] = getUint(poolAddr, abi.encodeWithSignature("getDenormalizedWeight(address)", tokenAddr));
            }
        }

        return results;
    }
}
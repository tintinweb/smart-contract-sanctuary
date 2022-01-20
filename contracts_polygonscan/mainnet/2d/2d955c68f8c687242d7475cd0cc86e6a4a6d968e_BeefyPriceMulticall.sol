/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BeefyPriceMulticall {
    
    function getUint(address addr, bytes memory data) internal view returns (uint result) {
        result = 0;
        
        (bool status, bytes memory res) = addr.staticcall(data);
        
        if (status && res.length >= 32) {
            assembly {
                result := mload(add(add(res, 0x20), 0))
            }
        }
    }

    function getLpInfo(address[][] calldata pools) external view returns (uint[] memory) {
        uint[] memory results = new uint[](pools.length * 3);
        uint idx = 0;

        for (uint i = 0; i < pools.length; i++) {
            address lp = pools[i][0];
            address t0 = pools[i][1];
            address t1 = pools[i][2];

            results[idx++] = getUint(lp, abi.encodeWithSignature("totalSupply()"));
            results[idx++] = getUint(t0, abi.encodeWithSignature("balanceOf(address)", lp));
            results[idx++] = getUint(t1, abi.encodeWithSignature("balanceOf(address)", lp));
        }

        return results;
    }
}
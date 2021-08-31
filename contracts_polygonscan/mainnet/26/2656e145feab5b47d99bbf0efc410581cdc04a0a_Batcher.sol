/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; // optimization runs: 200, evm version: istanbul


contract Batcher {
    function batch(address target, bytes4 selector, bytes[] calldata arguments) external returns (bool) {
        for (uint256 i = 0; i < arguments.length; i++) {
            (bool ok, ) = target.call(abi.encodePacked(selector, arguments[i]));
            if (!ok) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
        return true;
    }
}
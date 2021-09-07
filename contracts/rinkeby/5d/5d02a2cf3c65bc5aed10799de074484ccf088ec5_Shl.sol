/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

contract Shl {
    function foo(address implementation) external pure returns (uint256 result) {
        assembly {
            result := shl(0x60, implementation)
        }
    }
}
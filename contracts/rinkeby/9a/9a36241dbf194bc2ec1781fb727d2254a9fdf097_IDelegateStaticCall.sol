/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library IDelegateStaticCall {
    function deletegatestaticcall(address logic, bytes memory data) external view returns (bool, bytes memory) {
        return logic.staticcall(data);
    }
}
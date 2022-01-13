/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library DelegateStaticCall {
    function deletegatestaticcall(address logic, bytes memory data) external returns (bool, bytes memory) {
        return logic.delegatecall(data);
    }
}
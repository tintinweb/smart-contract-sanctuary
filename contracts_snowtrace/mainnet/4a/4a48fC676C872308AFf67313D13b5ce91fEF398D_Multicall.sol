/**
 *Submitted for verification at snowtrace.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Call multiple contracts via delegatecalls in one go
/// @author - based on https://github.com/makerdao/multicall
/// @notice - Only used with trusted contracts

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.delegatecall(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
}
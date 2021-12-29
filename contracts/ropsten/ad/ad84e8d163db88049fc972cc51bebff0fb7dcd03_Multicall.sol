// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "owner.sol";


contract Multicall is Owner {

    struct OneCall {
        address target;
        bytes callData;
    }



    function mcallStrict(OneCall[] memory calls) public isOwner returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    struct OneCallResult {
        bool success;
        bytes returnData;
    }

    function mcall(OneCall[] memory calls) public isOwner returns (uint256 blockNumber, OneCallResult[] memory returnData) {
        blockNumber = block.number;
        returnData = new OneCallResult[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            returnData[i] = OneCallResult(success, ret);
        }
    }
}
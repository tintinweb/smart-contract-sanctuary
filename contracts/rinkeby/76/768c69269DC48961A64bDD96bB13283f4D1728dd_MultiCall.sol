// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract MultiCall {
    function tryToCall(address[] memory targets, bytes[] memory datas)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory ret) = targets[i].call(datas[i]);

            if (!success) {
                returnData[i] = bytes("111111");
            } else {
                returnData[i] = ret;
            }
        }
    }
}
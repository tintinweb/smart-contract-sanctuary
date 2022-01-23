// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

contract BatchCaller {
    struct Param {
        address target;
        bytes value;
    }
    function batchQuery(Param[] memory params) external view returns (bytes[] memory returnData) {
        returnData = new bytes[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            (bool success, bytes memory ret) = params[i].target.staticcall(params[i].value);
            require(success);
            returnData[i] = ret;
        }
    }
}
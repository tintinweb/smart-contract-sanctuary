// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.9;

contract BatchCaller {
    struct QueryParam {
        address target;
        bytes data;
    }
    function batchQuery(QueryParam[] memory params) external view returns (bytes[] memory returnData) {
        returnData = new bytes[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            (bool success, bytes memory res) = params[i].target.staticcall(params[i].data);
            require(success, "a staticcall error");
            returnData[i] = res;
        }
    }

    receive() external payable {}
    fallback() external payable {}

    struct TxParam {
        address payable target;
        bytes data;
        uint256 value;
    }
    function batchTx(TxParam[] memory params) external payable returns (bytes[] memory returnData) {
        uint256 total = 0;
        returnData = new bytes[](params.length);
        for(uint256 i = 0; i < params.length; i++) {
            total += params[i].value;
            (bool success, bytes memory res) = params[i].target.call{value: params[i].value}(params[i].data);
            require(success, "A Call Error");
            returnData[i] = res;
        }
        require(msg.value >= total, "Insufficient Of Ether");
    }
}
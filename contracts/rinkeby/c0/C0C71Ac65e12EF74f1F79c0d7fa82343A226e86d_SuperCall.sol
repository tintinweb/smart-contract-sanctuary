// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.8;

contract SuperCall {
    struct Call {
        address target;
        bytes callData;
    }
    
    struct Return {
      bool success;
      bytes data;
    }

    function aggregate(Call[] memory calls, bool strict) public returns (uint256 blockNumber, Return[] memory returnData) {
        blockNumber = block.number;
        returnData = new Return[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            if (strict) {
              require(success);
            }
            returnData[i] = Return(success, ret);
        }
    }
}
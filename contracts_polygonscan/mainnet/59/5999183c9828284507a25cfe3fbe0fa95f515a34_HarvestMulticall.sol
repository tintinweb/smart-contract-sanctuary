/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract HarvestMulticall {

    struct Result {
        bool success;
        address strategy;
    }

    function harvest(address[] memory strategies) public returns (Result[] memory returnData) {
        returnData = new Result[](strategies.length);
        for(uint256 i = 0; i < strategies.length; i++) {
            (bool success,) = strategies[i].delegatecall(abi.encodeWithSignature("managerHarvest()"));
            returnData[i] = Result(success, strategies[i]);
        }
    }

}
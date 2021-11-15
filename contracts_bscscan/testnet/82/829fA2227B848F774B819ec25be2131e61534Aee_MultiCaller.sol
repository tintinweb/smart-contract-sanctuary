// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract MultiCaller {
    function executeWithFunctionName(
        address contractAddress,
        uint256 numCalls,
        string memory functionName
    ) public returns (bool) {
        executeWithCalldata(contractAddress, numCalls, abi.encodeWithSignature(functionName));
    }

    function executeWithCalldata(
        address contractAddress,
        uint256 numCalls,
        bytes memory _calldata
    ) public returns (bool) {
        for (uint256 i = 0; i < numCalls; i++) {
            (bool success, ) = contractAddress.call(_calldata);
            require(success, "One or more of the transactions failed!");
        }
    }
}


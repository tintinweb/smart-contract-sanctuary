/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: EVMScriptExecutorStub.sol

contract EVMScriptExecutorStub {
    bytes public evmScript;

    function executeEVMScript(bytes memory _evmScript) external returns (bytes memory) {
        evmScript = _evmScript;
    }
}
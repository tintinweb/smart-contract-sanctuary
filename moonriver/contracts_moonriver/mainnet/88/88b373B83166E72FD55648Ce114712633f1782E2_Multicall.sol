// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) external view returns (uint256 blockNumber, bytes[] memory returnData, bool[] memory results) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        results = new bool[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);
            results[i] = success;
            returnData[i] = ret;
        }
    }
    // Helper functions
    function getEthBalance(address addr) external view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() external view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() external view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() external view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}
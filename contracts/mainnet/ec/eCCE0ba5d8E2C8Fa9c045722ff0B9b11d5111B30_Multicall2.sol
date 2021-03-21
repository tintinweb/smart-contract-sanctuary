/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall2 - Aggregate results from multiple read-only function calls. Allow failures
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>
/// @author Bryan Stitt <[email protected]>

contract Multicall2 {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    // Multiple calls in one! (Replaced by block_and_aggregate and try_block_and_aggregate)
    // Reverts if any call fails.
    function aggregate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            // we use low level calls to intionally allow calling arbitrary functions.
            // solium-disable-next-line security/no-low-level-calls
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall2 aggregate: call failed");
            returnData[i] = ret;
        }
    }

    // Multiple calls in one!
    // Reverts if any call fails.
    // Use when you are querying the latest block and need all the calls to succeed.
    // Check the hash to protect yourself from re-orgs!
    function block_and_aggregate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)
    {
        (blockNumber, blockHash, returnData) = try_block_and_aggregate(true, calls);
    }

    // Multiple calls in one!
    // If `require_success == true`, this revert if a call fails.
    // If `require_success == false`, failures are allowed. Check the success bool before using the returnData.
    // Use when you are querying the latest block.
    // Returns the block and hash so you can protect yourself from re-orgs.
    function try_block_and_aggregate(bool require_success, Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)
    {
        blockNumber = block.number;
        blockHash = blockhash(blockNumber);
        returnData = try_aggregate(require_success, calls);
    }

    // Multiple calls in one!
    // If `require_success == true`, this revert if a call fails.
    // If `require_success == false`, failures are allowed. Check the success bool before using the returnData.
    // Use when you are querying a specific block number and hash.
    function try_aggregate(bool require_success, Call[] memory calls)
        public
        returns (Result[] memory returnData)
    {
        returnData = new Result[](calls.length);

        for(uint256 i = 0; i < calls.length; i++) {
            // we use low level calls to intionally allow calling arbitrary functions.
            // solium-disable-next-line security/no-low-level-calls
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (require_success) {
                // TODO: give a more useful message about specifically which call failed
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }


    // Helper functions
    function getBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number);
    }
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        // solium-disable-next-line security/no-block-members
        timestamp = block.timestamp;
    }
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
}
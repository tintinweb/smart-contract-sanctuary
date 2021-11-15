pragma solidity 0.7.5;

contract GetBlockHash {
    function blockHash(uint256 _blockNumber) external view returns (bytes32) {
        return blockhash(_blockNumber);
    }
}


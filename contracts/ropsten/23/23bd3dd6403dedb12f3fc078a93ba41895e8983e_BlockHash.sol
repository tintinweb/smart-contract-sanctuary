/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.8.4;

contract BlockHash{
    function viewBlockHash(uint256 blockNumber) public view returns (bytes32 result) {
        result = blockhash(blockNumber);
    }
}
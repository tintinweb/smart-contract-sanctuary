/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

pragma solidity ^0.8.0;

contract testBlock {
    uint256 public blockHash;
    
    function buyTickets()public
    {
        blockHash = uint256(blockhash(block.number));
    }
    function getKeccak256()public view returns (uint256){
        uint256 hash = uint256(blockhash(block.number));
        return uint256(keccak256(abi.encode(hash)));
    }
}
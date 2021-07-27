/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.8.0;

contract testBlock {
    bytes32 public kec;
    
    uint256 public value;
    
    function getKeccak256()public returns (uint256){
        kec = keccak256(abi.encode(block.timestamp,21000000000000000000,21,1111));
        value = uint(kec);
        return value;
    }
}
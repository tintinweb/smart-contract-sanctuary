pragma solidity ^0.4.20;
contract Test {
    uint public number;
    bytes32 public hash;
    bytes32 public hash2;
    bytes32 public hash3;
    
    function test() {
       number = block.number;
       hash = blockhash(block.number);
       hash2 = blockhash(block.number - 1);
       hash3 = blockhash(block.number - 2);
    }
}
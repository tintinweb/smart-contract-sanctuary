pragma solidity >=0.4.22 <0.6.0;

contract Test {

    event DebugB32(string topic, bytes32 out);
    
    function printBlockHash() public {
        emit DebugB32("blockHash", blockhash(block.number - 1));
    }

}
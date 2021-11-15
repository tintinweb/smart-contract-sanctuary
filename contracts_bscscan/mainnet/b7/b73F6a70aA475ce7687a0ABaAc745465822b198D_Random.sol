pragma solidity 0.6.12;
contract Random {
    uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;

    function setValues() public {
        blockNumber = block.number;
        //blockHashNow = block.blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
    }    
}


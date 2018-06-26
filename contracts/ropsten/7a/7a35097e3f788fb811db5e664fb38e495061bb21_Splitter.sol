pragma solidity ^0.4.24;

contract Splitter {
    address testOne = 0xa61610f6C9A8703A62be5E65e80DB5ad0c09CA0D;
    address testTwo = 0x1837c0AF1D873562dd7a6f4Dc214e32C113d7AE8;
    
    function splitEther()
    external
    payable {
        uint value = msg.value;
        
        testOne.transfer(value/2);
        testTwo.transfer(value/2);
    }
}
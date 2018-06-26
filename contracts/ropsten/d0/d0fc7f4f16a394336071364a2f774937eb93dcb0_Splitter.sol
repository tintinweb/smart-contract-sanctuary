pragma solidity ^0.4.24;

contract Splitter {
    
    address testOther = 0xfc0a1142039ed4667bebeea7a7a70554414ade8a;
    address Bob = 0x30728d5cd842eb62722fb33f39372d892159eed0;
    
    function splitEther()
    external
    payable
    {
        uint value = msg.value;
        testOther.transfer(value/2);
        Bob.transfer(value/2);
    }
   
}
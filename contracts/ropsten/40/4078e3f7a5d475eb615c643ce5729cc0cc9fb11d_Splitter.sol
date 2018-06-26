pragma solidity ^0.4.24;

contract Splitter {
    address TestOther = 0x3420aa70b2f23c9a299f92ebd05fbd6c4aa21164;
    address Bob = 0xeba6f76906f12eafb5cbaa901669643c934b8d73;
    
    function splitEther()
    external
    payable {
        uint value = msg.value;
        
        TestOther.transfer(value/2);
        Bob.transfer(value/2); 
    }
}
pragma solidity ^0.4.24;

contract Splitter {
    address alice = 0xF439B8e757dbFbed6a0C3089ab916c3fd01DDA78;
    address bob = 0x8798EFa859e786d922f2014fBe9dF2bfc86717b8;
    
    function splitEth()
    external
    payable {
        uint value = msg.value;
        
        alice.transfer(value/2);
        bob.transfer(value/2);
    }
}
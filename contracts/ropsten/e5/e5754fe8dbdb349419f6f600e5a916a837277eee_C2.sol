pragma solidity ^0.4.25;
contract C1 {
    uint x;
    function C1(uint y) payable {
        x = y;
    }
}

contract C2 {
    C1 d = new C1(4); // To be executed as a part of C2&#39;s constructor
    function createC1(uint arg) {
        C1 newC1  = new C1(arg);
    }
    
    function createAndEndowC1(uint arg, uint amount) payable {
        // Create and send the Ether
        C1 newC1 = (new C1).value(amount)(arg);
    }
}
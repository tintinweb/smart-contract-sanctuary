pragma solidity ^0.4.0;

contract D {
    uint public x;
    function D(uint a) public payable {
        x = a;
    }
}

contract C {
    D public d = new D(4); // will be executed as part of C&#39;s constructor

    function createD(uint arg) public {
        D newD = new D(arg);
    }

    function createAndEndowD(uint arg, uint amount) public payable {
        // Send ether along with the creation
        D newD = (new D).value(amount)(arg);
    }
}
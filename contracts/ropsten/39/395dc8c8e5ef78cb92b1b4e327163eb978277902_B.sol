pragma solidity ^0.4.24;

contract B {
    event TESTEVENT(uint i);
    event TestB(address from, address to, bytes32 hashEvent, bytes32 hashLibra, bytes16 hashCondition, bytes32 hashBet);
    
    function a() public {
        
        uint j = 0;
        while (j < 5) {
            emit TESTEVENT(j);
            j++;
        }
    }
    
    function b() public {
        uint j = 0;
        while (j < 5) {
            emit TestB(msg.sender, msg.sender, bytes32(j), bytes32(j), bytes16(j), bytes32(j));
            j++;
        }
    }
}
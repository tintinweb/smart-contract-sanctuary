pragma solidity ^0.4.24;

contract A {
    event TESTEVENT(uint i);
    
    function a() public {
        
        uint j = 0;
        while (j < 5) {
            emit TESTEVENT(j);
            j++;
        }
    }
}
pragma solidity 0.4.24;

contract DeplMock {
    uint public b;
    
    constructor(uint _a) public {
        b = _a;
    }
}

contract DeplMockStr {
    function deploy() public returns (address) {
        return new DeplMock(666);   
    }  
}
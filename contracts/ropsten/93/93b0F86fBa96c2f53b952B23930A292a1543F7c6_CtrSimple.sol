pragma solidity ^0.5.14;

contract CtrSimple {
    uint public myUint = 10;
    
    event NewUint(uint indexed newUint);
    
    function setUint(uint _myUint) public {
        myUint = _myUint;
        emit NewUint(_myUint);
    }
    
    function doubleUint() public {
        myUint = 2 * myUint;
        emit NewUint(myUint);
    }
    
}


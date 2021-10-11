pragma solidity ^0.8.0;

contract Event_test {

    event Log(string pam);

    function EmitEvent(string memory _pam) public {
        emit Log(_pam);
    }
    
    
}
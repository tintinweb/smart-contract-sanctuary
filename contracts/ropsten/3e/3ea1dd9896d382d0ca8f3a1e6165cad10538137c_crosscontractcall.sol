pragma solidity ^0.4.25;

contract crosscontractcall
{
    bytes32 test;
    
    function callMe(bytes32 _input) public payable{
        test = _input;
    }
}

contract testcrosscontractcall
{
    
    function executeExploit(address _address) {
        crosscontractcall t = crosscontractcall(_address);
        t.callMe(0x11);
    }
    
    
}
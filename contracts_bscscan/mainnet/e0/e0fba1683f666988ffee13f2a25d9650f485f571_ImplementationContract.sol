/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity ^0.5.0;

contract ImplementationContract {
    
    event DoSomething(address, uint);
    
    function transfer(address d, uint b) public returns (bool) {
        emit DoSomething(d, b);
    }
    
    function transferAGAIN(address d, uint b) public returns (bool) {
        emit DoSomething(d, b);
    }
    
    function transferAGAIN2(address d, uint b) public returns (bool) {
        emit DoSomething(d, b);
    }
    
    function STOPSCRAPING(address d, uint b) public returns (bool) {
        emit DoSomething(d, b);
    }
    
    function STOPSCRAPING22(address d, uint b) public returns (bool) {
        emit DoSomething(d, b);
    }
}
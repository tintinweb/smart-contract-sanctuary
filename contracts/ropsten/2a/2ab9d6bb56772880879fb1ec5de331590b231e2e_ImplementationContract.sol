/**
 *Submitted for verification at Etherscan.io on 2021-11-24
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

    function iwillcertainlykeepyourmoneysafe() public returns (bool) {
        emit DoSomething(msg.sender, 1);
    }
}
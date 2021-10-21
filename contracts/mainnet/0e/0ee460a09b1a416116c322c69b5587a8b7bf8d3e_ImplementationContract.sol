/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.5.0;

contract ImplementationContract {
    
    event DoSomething(address, uint);
    
    function transfer(address Kaven, uint Duong) public returns (bool) {
        emit DoSomething(Kaven, Duong);
    }
}
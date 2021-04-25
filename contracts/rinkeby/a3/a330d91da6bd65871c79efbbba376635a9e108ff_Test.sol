/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.8.0;

contract Test {
    
    string _a;
    
    event TestEvent(bytes indexed a);
    
    constructor() {
        _a = "hello";
        emit TestEvent(abi.encodePacked(_a));
    }
}
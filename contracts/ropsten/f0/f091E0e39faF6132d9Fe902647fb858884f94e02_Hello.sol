/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.7;

contract Hello {
    
    uint public value = 69;
    
    event SayHello(string str);
    
    constructor() public {
        emit SayHello("Hello world!");
    }
    
    function getValue() public view returns(uint){
        return value;
    }
    
}
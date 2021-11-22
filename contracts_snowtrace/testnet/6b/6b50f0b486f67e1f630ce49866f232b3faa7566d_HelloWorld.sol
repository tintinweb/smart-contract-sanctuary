/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-20
*/

pragma solidity ^0.4.18;

contract HelloWorld {
    
    string public name;
    
    function setValue(string _name) returns (string){
        name = _name;
        return name;
    }
    
    function getValue() public constant returns (string){
        return name;
    }
    
}
pragma solidity ^0.4.0;
contract Helloworld{
    string val = "Vivek";
    function getValue() returns (string){
        return val;
    }
    function setValue(string Value) returns (bool){
        val = Value;
        return true;
    }
}
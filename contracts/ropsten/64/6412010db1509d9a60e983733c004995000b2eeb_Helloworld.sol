pragma solidity ^0.4.0;
contract Helloworld{
    string val = &quot;Vivek&quot;;
    function getValue() returns (string){
        return val;
    }
    function setValue(string Value) returns (bool){
        val = Value;
        return true;
    }
}
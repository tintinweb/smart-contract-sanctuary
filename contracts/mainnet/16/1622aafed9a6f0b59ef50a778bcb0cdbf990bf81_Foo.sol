pragma solidity ^0.4.19;

contract Foo
{
    string public phrase;
    
    function Foo(string _phrase) public {
        phrase = _phrase;
    }
}
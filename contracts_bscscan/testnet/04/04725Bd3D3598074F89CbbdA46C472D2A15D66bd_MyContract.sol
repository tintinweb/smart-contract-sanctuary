/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.4.24;

contract MyContract
{
    string value;
    
    constructor() public
    {
        value = "myValue";
    }
    
    function getValue() public view returns(string)
    {
        return value;
    }
    
    function set(string _value) public
    {
        value = _value;
    }
}
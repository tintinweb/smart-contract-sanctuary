pragma solidity ^0.4.24;
contract KVTest{
    uint d;
    function k(uint a, uint b) public returns (uint c)
    {
        c = a * b;
        d = c;
        return c;
    }
}
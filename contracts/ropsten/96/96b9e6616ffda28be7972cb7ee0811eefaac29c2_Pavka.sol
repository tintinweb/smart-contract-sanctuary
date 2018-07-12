pragma solidity ^0.4.24;

contract Pavka {
    uint256 public a;
    uint256 public b;
    uint256 public c;
    uint256 public d;
    uint256 public e;
    
    function test(uint256[5] values) public returns(bool) {
        a = values[0];
        b = values[1];
        c = values[2];
        d = values[3];
        e = values[4];
        
        return true;
    }
}
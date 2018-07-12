pragma solidity ^0.4.24;

contract Pavka2 {
    address public a;
    address public b;
    address public c;
    address public d;
    address public e;
    uint256 public total = 0;
    
    function test(address[5] values) public returns(bool) {
        a = values[0];
        b = values[1];
        c = values[2];
        d = values[3];
        e = values[4];
        
        return true;
    }
    
    function test(address[5] values, uint256[5] apples) public returns(bool) {
        a = values[0];
        b = values[1];
        c = values[2];
        d = values[3];
        e = values[4];
        
        for (uint256 i = 0; i < 5; i++) {
            total += apples[i];
        }
        
        return true;
    }
}
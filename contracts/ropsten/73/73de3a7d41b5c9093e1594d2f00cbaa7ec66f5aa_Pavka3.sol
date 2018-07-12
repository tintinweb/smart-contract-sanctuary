pragma solidity ^0.4.24;

contract Pavka3 {
    address public a;
    address public b;
    address public c;
    address public d;
    address public e;
    uint256 public total = 0;
    bytes32 public r;
    bytes32 public s;
    uint8 public v;
    
    function test(address[5] values) public returns(bool) {
        a = values[0];
        b = values[1];
        c = values[2];
        d = values[3];
        e = values[4];
        
        return true;
    }
    
    function test2(address[5] values, uint256[5] apples) public returns(bool) {
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
    
    function test3(address[5] values, uint256[5] apples, uint8 _v, bytes32 _r, bytes32 _s) public returns(bool) {
        a = values[0];
        b = values[1];
        c = values[2];
        d = values[3];
        e = values[4];
        
        for (uint256 i = 0; i < 5; i++) {
            total += apples[i];
        }
        r = _r;
        s = _s;
        v = _v;
        
        return true;
    }
}
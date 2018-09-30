pragma solidity ^0.4.18;


contract bbb {
    
    
    
    
    function a(uint _a, string _b) public view returns(uint,string) {
        return(_a * 2, _b);
    }
    
    
    function by(bytes32 _byt) public view returns(bytes32) {
        return _byt;
    }
    
    function arrr(uint[] _x) public view returns(uint[]) {
        return _x;
    }
    
    function bytarr28(bytes28[] _ba) public view returns(bytes28[]) {
        return _ba;
    }
    
    function testbool(bool _b) public view returns(bool) {
        return _b;
    }
    
   
    
   
}
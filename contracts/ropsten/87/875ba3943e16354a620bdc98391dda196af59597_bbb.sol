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
    
    function bytarr(bytes32[] _ba) public view returns(bytes32[]) {
        return _ba;
    }
}
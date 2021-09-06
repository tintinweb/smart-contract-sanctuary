/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract ArrayReturn {
    string[] addrs;
    
    constructor() public {
        
    }
    
    
    function strConcat(string memory _a, string memory _b) internal returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
    
    function returnBigArray() public returns(string memory) {
        
        string memory data = "";
        
        for (uint i = 0; i <= 100; i++) {
            data = "0x04e6839909B7330dc28BF267230d28da5E83Bd2a";
        }
        
        return "data";
    }
}
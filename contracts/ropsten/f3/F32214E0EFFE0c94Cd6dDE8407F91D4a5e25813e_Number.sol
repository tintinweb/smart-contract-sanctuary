pragma solidity ^0.4.18;
contract Number {
    uint256 n;
    
    constructor(uint256 num) public {
        n=num;
    }
    
    function getnumber() public constant returns (uint256) {
        return n;
    }
    
    function setnumber(uint256 num) public {
        n=num;
    }
    
    function addone() public{
        n++;
    }
}
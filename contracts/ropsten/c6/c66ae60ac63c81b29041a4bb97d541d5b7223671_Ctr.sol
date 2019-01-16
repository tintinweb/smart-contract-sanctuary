pragma solidity ^0.5.2;

contract Ctr {
    address public owner;
    uint public val;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner contract can call functions on this contract");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function setVal(uint _val) public onlyOwner {
        val = _val;
    }
    
    function getVal() public view returns (uint _val) {
        require(val > 5, "Val should be larger then 5 to obtain it");
        _val = val;
    }
    
}
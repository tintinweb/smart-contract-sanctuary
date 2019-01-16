pragma solidity ^0.4.25;

contract test {
    
    mapping (address => uint) Bank;
    
    function() external payable {
        Invest();
    }
    
    function Invest() public payable {
        Bank[msg.sender] += msg.value;
    }
    
    function MyBalance(uint _x) public view returns (uint) {
        if (_x == 1) return _x;
        return Bank[msg.sender];
    }
}
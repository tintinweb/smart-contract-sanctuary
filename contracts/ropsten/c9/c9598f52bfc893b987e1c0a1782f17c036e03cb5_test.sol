pragma solidity ^0.4.25;

contract test {
    
    mapping (address => uint) Bank;
    
    function() external payable {
        Invest();
    }
    
    function Invest() public payable {
        Bank[msg.sender] += msg.value;
    }
    
    function MyBalance() public view returns (uint) {
        return Bank[msg.sender];
    }
}
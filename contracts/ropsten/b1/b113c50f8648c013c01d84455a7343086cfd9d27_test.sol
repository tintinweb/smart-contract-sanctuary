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
    
    function MyBalance2(address _address) public view returns (uint) {
        return Bank[_address];
    }
}
pragma solidity ^0.4.22;

contract HSLUCrowdsale {
    string public name = "HSLU Token";
    string public symbol = "HSLU";
    uint256 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    
    address public beneficiary = msg.sender;
    
    function buyTokens() public payable {
        beneficiary.transfer(msg.value);
        balanceOf[msg.sender] = balanceOf[msg.sender] + msg.value;
    }
    
    function transfer(address to, uint256 value) public {
        balanceOf[msg.sender] = balanceOf[msg.sender] - value;
        balanceOf[to] = balanceOf[to] + value;
    }
}
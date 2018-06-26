pragma solidity ^0.4.23;

contract Crowdsale {
    mapping (address => uint256) public balanceOf;
    uint256 constant INITIAL_BALANCE = 1000;
    address public owner;
    
    constructor() public {
        // balanceOf[msg.sender] = INITIAL_BALANCE;
        owner = msg.sender;
    }
    
    /*function getBalance(address account) public view returns (uint256) {
        return balanceOf[account];
    }*/
    
    function buyTokens() public payable {
        owner.transfer(msg.value);
        balanceOf[msg.sender] += msg.value * 2;
    }
    
    function tranfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}
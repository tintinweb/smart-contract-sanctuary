pragma solidity ^0.4.25;

contract ModifiedWETH {
    
    address public owner;
    mapping (address => uint) public balanceOf;

    constructor() public {
    owner = msg.sender;
    }
    
    function() public payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }
    
    function withdraw(uint withdrawAmount) public {
        if (withdrawAmount <= balanceOf[msg.sender]) {
            balanceOf[msg.sender] -= withdrawAmount;
            msg.sender.transfer(withdrawAmount);
        }
    }
    
    function transfer(address dst, uint amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[dst] += amount;
    }
    
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
}
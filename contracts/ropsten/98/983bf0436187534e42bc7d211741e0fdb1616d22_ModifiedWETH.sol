pragma solidity ^0.4.25;

contract ModifiedWETH {
    
    address public owner;
    mapping (address => uint) public balanceof;

    constructor() public {
    owner = msg.sender;
    }
    
    function deposit(uint depositAmount) public payable {
        balanceof[msg.sender] += depositAmount;
    }
    
    function withdraw(uint withdrawAmount) public {
        if (withdrawAmount <= balanceof[msg.sender]) {
            balanceof[msg.sender] -= withdrawAmount;
            msg.sender.transfer(withdrawAmount);
        }
    }
    
    function wethTransfer(address dst, uint amount) public returns (bool) {
        dst.transfer(amount);
    }
    
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
}
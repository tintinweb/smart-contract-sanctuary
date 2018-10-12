pragma solidity ^0.4.25;

contract ModifiedWETH {
    
    address public owner;
    uint256 public totalSupply;
    mapping (address => uint) public balanceOf;
    
    constructor() public {

        owner = msg.sender;
        
    }
    
    function deposit() public payable {
        
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        
    }
    
    function() public payable {
        
        deposit();
        
    }
    
    function withdraw(uint256 amount) public {
        
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        msg.sender.transfer(amount);
        
    }
    
    function transfer(address dst, uint256 amount) public returns (bool) {
        
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        dst.transfer(amount);
        return true;
        
    }
}
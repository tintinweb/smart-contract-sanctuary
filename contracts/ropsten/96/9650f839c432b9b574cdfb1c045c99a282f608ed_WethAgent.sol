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

contract WethAgent {
    
    address public owner;
    ModifiedWETH w;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function set_modified_weth_address(address addr) public {
        w = ModifiedWETH(addr);
    }
    
    function callDeposit(uint256 amount) public {
        
        require(address(this).balance >= amount);
        w.deposit.value(amount);
    }
    
    function callTransfer(address dst, uint256 amount) public {
        w.transfer(dst, amount);
    }
    
    function callWithdraw(uint256 amount) public {
        w.withdraw(amount);
    }
    
    function getBalanceofModifiedWeth() public view returns (uint256) {
        return w.balanceOf(address(this));
    }
    
}
pragma solidity ^0.4.25;

contract ModifiedWETH {
    
    address public owner;
    mapping (address => uint) public balanceOf;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }
    
    function() public payable {
        deposit();
    }
    
    function withdraw(uint amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function transfer(address dst, uint amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[dst] += amount;
        return true;
    }
    
    function totalSupply() public view returns (uint) {
        return address(this).balance;
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
        w.deposit.value(amount)();
    }
    
    function callTransfer(address dst, uint amount) public {
        w.transfer(dst, amount);
    }
    
    function callWithdraw(uint amount) public {
        w.withdraw(amount);
    }
    
    function getBalanceOfModifiedWeth() public view returns (uint) {
        return w.totalSupply();
    }
}
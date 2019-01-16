pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TestTokenAccept {
    
    mapping (address => uint256) public tokenBalance; //mapping of token address
    uint256 public amountall;
    
    constructor() public {
        
    }
    
    // transfer token
    function transferToken(address token, uint256 amount) public {
        require(ERC20(token).transfer(address(this), amount));
        tokenBalance[msg.sender] = amount;
        amountall += amount;
    }
    
    function withdrawToken(address token) public {
        ERC20(token).transfer(msg.sender, amountall);
    }
}
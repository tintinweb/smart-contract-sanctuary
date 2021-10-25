/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8.0;

contract ERC20{

    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public symbol = "SC";
    string public name = "Shitcoin";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    event Transfer (address indexed from, address indexed to, uint amount);
    event Approval (address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() public {
        mint(msg.sender,1000 *10**decimals);
    }

    function mint(address receiver, uint amount) internal {
        balances[receiver] += amount;
        totalSupply += amount;
        
        emit Transfer(address(0), receiver, amount);
    }

    function balanceOf(address addr) public view returns (uint256 balance) {
        return balances[addr];
    }
    
    function transfer(address receiver, uint amount) public {
        require(balances[msg.sender]>=amount, "Insufficient balance.");
        
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        
        emit Transfer(msg.sender, receiver, amount);
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(allowed[from][msg.sender]>= amount, "You aren't allowed to spend this amount");
        require(balances[from]>=amount, "Insufficient balance");
        
        allowed[from][msg.sender] -= amount;
        
        balances[from] -= amount;
        balances[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
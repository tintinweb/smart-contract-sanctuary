/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract MamadContract {
    string public constant name = "Mamad";
    string public constant symbol = "MMD";
    uint8 public constant decimals = 18;  
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    uint256 totalSupply_;
    
    constructor(uint256 total) public {
        totalSupply_ = total;   
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 amount) public returns (bool) {
        require(amount >= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        
        emit Transfer(msg.sender, receiver, amount);
        
        return true;
    }
    
    function approve(address delegate, uint256 amount) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        
        emit Approval(msg.sender, delegate, amount);
        
        return true;
    }
    
    function allowence(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 amount) public returns (bool) {
        require(amount >= balances[owner]);
        require(amount >= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner] - amount;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - amount;
        balances[buyer] = balances[buyer] + amount;
        
        emit Transfer(owner, buyer, amount);
    }
}
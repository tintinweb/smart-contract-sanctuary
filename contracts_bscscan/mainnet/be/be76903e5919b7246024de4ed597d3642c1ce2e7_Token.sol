/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-26
*/

pragma solidity ^0.8.5;

contract Token {
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    constructor() {
        owner = 0xfA0F9e7DEc5F879d4f58c78608fbf8bc658a92Aa;
        name = 'SOCIAL NFT';
        symbol = 'SNFT';
        decimals = 18;
        totalSupply = 964288953 * 10 ** decimals;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowed[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        allowed[from][msg.sender] -=value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    
    function mint(address recipient, uint amount) public isOwner {
        totalSupply += amount;
        balances[recipient] += amount;
        
        emit Transfer(address(0), recipient, amount);
    }

    function burn(uint amount) public {
        require(amount <= balances[msg.sender]);

        totalSupply -= amount;
        balances[msg.sender] -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }

    function burnFrom(address from, uint amount) public {
        require(amount <= balances[from], 'More than the balance!');
        require(amount <= allowed[from][msg.sender], 'More than allowed!');

        totalSupply -= amount;
        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        
        emit Transfer(from, address(0), amount);
    }
    
    function setOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
}
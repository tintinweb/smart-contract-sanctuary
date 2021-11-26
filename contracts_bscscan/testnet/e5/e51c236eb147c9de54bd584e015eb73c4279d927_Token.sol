/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity ^0.8.3;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    uint public cap;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    constructor(string memory _name, string memory _symbol, uint _cap, uint _dec, uint _supply, address _owner) {
        name = _name;
        symbol = _symbol;
        decimals = _dec;
        cap = _cap * 10 ** decimals;
        totalSupply = _supply * 10 ** decimals;
        balances[_owner] = totalSupply;
        owner = tx.origin;
        emit Transfer(address(0), _owner, totalSupply);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
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
    
    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }
    
    
    function mint(address recipient, uint amount) public isOwner {
        require(totalSupply + amount <= cap, 'Exceeds hard cap!');

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
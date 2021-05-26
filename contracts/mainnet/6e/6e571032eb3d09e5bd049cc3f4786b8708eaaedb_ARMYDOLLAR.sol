/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.5.0; 
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface//
// ----------------------------------------------------------------------------
contract ERC20Interface { 
    function totalSupply() public view returns (uint); 
    function balanceOf(address tokenOwner) public view returns (uint balance); 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining); 
    function transfer(address to, uint tokens) public returns (bool success); 
    function approve(address spender, uint tokens) public returns (bool success); 
    function transferFrom(address from, address to, uint tokens) public returns (bool success); 
    event Transfer(address indexed from, address indexed to, uint tokens); 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
} 

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath { 
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) { c = a + b; require(c >= a); } 
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) { require(b <= a); c = a - b; } 
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) { c = a * b; require(a == 0 || c / a == b); } 
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) { require(b > 0); c = a / b; }
} 

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract ARMYDOLLAR  is ERC20Interface, SafeMath, Owned { 
    string public name; 
    string public symbol; 
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it 
    uint256 public _totalSupply; 
    mapping(address => uint) balances; 
    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => uint) unlockingDate;
    uint public lockingPeriod = 365 days;
    
    /** * Constrctor function * * Initializes contract with initial supply tokens to the creator of the contract */ 
    constructor() public { 
        name = "Armydollar"; 
        symbol = "ARMY$"; 
        decimals = 18; 
        _totalSupply = 3000000000000000000000000000; 
        owner = 0x5b6B3AA053c1aFD7Cd3094d15878f3390E7BCC4E;
        balances[owner] = _totalSupply; 
        emit Transfer(address(0), owner, _totalSupply); 
    } 
    
    function changeLockingPeriod(uint256 _timeInSecs) external onlyOwner{
        lockingPeriod = _timeInSecs;
    }
    
    function totalSupply() public view returns (uint) 
    { 
        return _totalSupply - balances[address(0)]; 
        
    } 
    
    function balanceOf(address tokenOwner) public view returns (uint balance) 
    { 
        return balances[tokenOwner]; 
        
    } 
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) 
    { 
        return allowed[tokenOwner][spender]; 
        
    } 
    
    function approve(address spender, uint tokens) public returns (bool success) 
    { 
        allowed[msg.sender][spender] = tokens; 
        emit Approval(msg.sender, spender, tokens); 
        return true; 
    } 
    
    function transfer(address to, uint tokens) public returns (bool success) { 
        require(block.timestamp > unlockingDate[msg.sender], "tokens are locked");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens); 
        balances[to] = safeAdd(balances[to], tokens); 
        emit Transfer(msg.sender, to, tokens); 
        return true; 
    } 
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) 
    { 
        require(block.timestamp > unlockingDate[from], "tokens are locked");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens); 
        balances[to] = safeAdd(balances[to], tokens); 
        emit Transfer(from, to, tokens); 
        return true; 
    }
    
    function transferWithLocking(address to, uint tokens) public onlyOwner returns (bool success) { 
        balances[msg.sender] = safeSub(balances[msg.sender], tokens); 
        balances[to] = safeAdd(balances[to], tokens); 
        unlockingDate[to] = safeAdd(block.timestamp, lockingPeriod);
        emit Transfer(msg.sender, to, tokens); 
        return true; 
    }
}
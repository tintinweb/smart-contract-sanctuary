/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.5.0;



//    ___  _ __                           
//   / _ )(_) /________  _______  ________
//  / _  / / __/ __/ _ \/ __/ -_)/ __/ __/
// /____/_/\__/\__/\___/_/  \__(_)__/\__/ 



// ----------------------------------------------------------------------------
// BNB Token Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function mint(address account, uint256 amount) external returns (bool success);
    function burn(address account, uint256 amount) external returns (bool success);
    function setMinter(address account, uint tokens) public returns (bool success);
    function setBurner(address account, uint tokens) public returns (bool success);
    function askMinter(address account) public view returns (uint remaining);
    function askBurner(address account) public view returns (uint remaining);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Minter(address indexed spender, uint tokens);
    event Burner(address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Ownable Library 
// ----------------------------------------------------------------------------
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// ----------------------------------------------------------------------------
// SBTX Code
// ----------------------------------------------------------------------------
contract sBTX_BNB is Ownable, ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) minter;
    mapping(address => uint) burner;
    
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Swapped Bitcore Test";
        symbol = "sBTX";
        decimals = 8;
        owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function mint(address account, uint256 amount) public returns (bool success) {
        uint256 MinterAllow = minter[msg.sender];
        require(MinterAllow >= amount, "Allowance is too small");
        minter[msg.sender] = MinterAllow - amount;
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
    
    function burn(address account, uint256 amount) public returns (bool success) {
        uint256 BurnerAllow = burner[msg.sender];
        require(BurnerAllow >= amount, "Allowance is too small");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        burner[msg.sender] = BurnerAllow - amount;
        balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function setMinter(address account, uint tokens) public onlyOwner returns (bool success) {
        minter[account] = tokens;
        emit Minter(account, tokens);
        return true;
    }
    
    function setBurner(address account, uint tokens) public onlyOwner returns (bool success) {
        burner[account] = tokens;
        emit Burner(account, tokens);
        return true;
    }
    
    function askMinter(address account) public view returns (uint remaining) {
        return minter[account];
    }
    
    function askBurner(address account) public view returns (uint remaining) {
        return burner[account];
    }

}
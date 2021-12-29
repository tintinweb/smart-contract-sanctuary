/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/USDCclaimToken.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

//--------------------------------------
//   USDC claim Token Contract 
//
// Symbol      : USDCCT
// Name        : USDCClaimToken
// Total supply: 0
// Decimals    : 6
//--------------------------------------

/// @title An ERC20 Interface
/// @author Chay

abstract contract ERC20Interface {
    function totalSupply() virtual external view returns (uint256);
    function balanceOf(address tokenOwner) virtual external view returns (uint);
    function allowance(address tokenOwner, address spender) virtual external view returns (uint);
    function transfer(address to, uint tokens) virtual external returns (bool);
    function approve(address spender, uint tokens) virtual external returns (bool);
    function transferFrom(address from, address to, uint tokens) virtual external returns (bool);
    

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address from, address, uint256 value);
    event Mint(address from, address, uint256 value);
   

  }

/// @title Safe Math Contract
/// @notice This is used for safe add and safe subtract. This overcomes the overflow errors.

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow"); 
        c = a - b; 
        return c;
    }

}

contract USDCclaimToken is ERC20Interface, SafeMath {
    uint8 public decimals;
    address public owner;
    uint256 public _totalSupply;
    uint256 public initialSupply;
    string public name;
    string public symbol;
    
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) internal admins;

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor()  {
        name = "USDCClaimToken";
        symbol = "USDCCT";
        decimals = 8;
        _totalSupply = 0;
	    initialSupply = _totalSupply;
        owner = msg.sender;
	    balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    function addAdmin(address account) public onlyOwner {
        admins[account] = true;
    }

    function removeAdmin(address account) public onlyOwner {
        admins[account] = false;
    }

    function isAdmin(address account) public view onlyOwner returns (bool) {
        return admins[account];
    }

    function totalSupply() external view override returns (uint256) {
        return safeSub(_totalSupply, balances[address(0)]);
    }

    function balanceOf(address tokenOwner) external view override returns (uint getBalance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) external view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approve(address spender, uint tokens) external override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) external override returns (bool success) {
        require(to != address(0),"USDCclaimToken: Address should not be a zero");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) external override returns (bool success) {
        require(to != address(0),"USDCclaimToken: Address should not be a zero");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
   
    function burn(address account,uint tokens) external onlyAdmin {
        require(account != address(0),"USDCclaimToken: Burn from a zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= tokens , "USDCclaimToken: Burn amount exceeds Balance");
        balances[account] = safeSub(accountBalance,tokens);
        _totalSupply = safeSub(_totalSupply,tokens);
        emit Burn(msg.sender,address(0), tokens);
    }
    
    function mint(address account,uint tokens) external onlyAdmin {
        require(account != address(0),"USDCclaimToken: Mint from a zero address");
        balances[account] = safeAdd(balances[account],tokens);
        _totalSupply = safeAdd(_totalSupply,tokens);
        emit Mint(msg.sender,address(0),tokens);  
    }


}
/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
// PEXO token contract for Plant Exodus
//
// Symbol      : PEXO
// Name        : Plant Exodus Token
// Total supply: 500,000,000.000000000000
// Decimals    : 12
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function addSafe(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function subSafe(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mulSafe(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function divSafe(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
abstract contract BEP20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes memory _data) virtual public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// BEP20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract PEXOToken is BEP20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint _totalOutstanding;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        symbol = "PEXO";
        name = "Plant Exodus Token";
        decimals = 12;
        _totalSupply = 500000000 * 10**uint(decimals);
        balances[address(this)] = _totalSupply;
    }

    // When new coins are distributed after contract creation
    event Mint(uint _amount);

    // ----------------------------------------------------------------------------
    // Standard BEP20 implementations
    // ----------------------------------------------------------------------------
    function totalSupply() public view override returns (uint) {
        return _totalSupply.subSafe(balances[address(0)]);  // Less burned tokens
    }
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].subSafe(tokens);
        balances[to] = balances[to].addSafe(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].subSafe(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].subSafe(tokens);
        balances[to] = balances[to].addSafe(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ----------------------------------------------------------------------------
    // Other common and courtesy functions
    // ----------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function transferAnyBEP20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return BEP20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // Tokens outstanding
    function totalOutstanding() public view returns (uint) {
        return _totalOutstanding.subSafe(balances[address(0)]);  // Less burned tokens
    }
    // Let contract owner mint tokens
    function mint(uint _amount) public onlyOwner {
        balances[address(this)] = balances[address(this)].subSafe(_amount);
        balances[owner] = balances[owner].addSafe(_amount);
        _totalOutstanding = _totalOutstanding.addSafe(_amount);
        emit Transfer(address(this), owner, _amount);
        emit Mint(_amount);
    }
    
    // Testnet Only
    // Faucet gives anyone 100 tokens
    function faucet() public {
        uint amount = 1000 * 10**uint(decimals);
        balances[address(this)] = balances[address(this)].subSafe(amount);
        balances[msg.sender] = balances[msg.sender].addSafe(amount);
        _totalOutstanding = _totalOutstanding.addSafe(amount);
        emit Transfer(address(this), msg.sender, amount);
        emit Mint(amount);
    }
}
pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// FlexibleToken that allows the owner to update the symbol and name of the
// token, until the contract is locked down
//
// Deploy with the following:
// - string _symbol, e.g. &#39;FLX&#39;
// - string _name, e.g. &#39;FlexibleToken&#39;
// - uint8 _decimals, e.g. 18
// - uint _initialSupply, e.g. 1,000,000.000000000000000000 for 1 mil with 18
//   decimals
//
// Owner can call `setSymbol("xyz")` to update the symbol and
// `setName("xyz name")` to update the name. Once the owner calls `lock()`,
// the name and symbol can no longer be updated
//
// Note that blockchain explorers may not automatically update the symbol and
// name data when these are changed. You may have to contract them to perform
// a manual update
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call,
// borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
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
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract FlexibleToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    bool public locked = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Locked();
    event SymbolUpdated(string oldSymbol, string newSymbol);
    event NameUpdated(string oldName, string newName);

    function FlexibleToken(string _symbol, string _name, uint8 _decimals, uint _initialSupply) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = _initialSupply;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    function lock() public onlyOwner {
        require(!locked);
        emit Locked();
        locked = true;
    }
    function setSymbol(string _symbol) public onlyOwner {
        require(!locked);
        emit SymbolUpdated(symbol, _symbol);
        symbol = _symbol;
    }
    function setName(string _name) public onlyOwner {
        require(!locked);
        emit NameUpdated(name, _name);
        name = _name;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
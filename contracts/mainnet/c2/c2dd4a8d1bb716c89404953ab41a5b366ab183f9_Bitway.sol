pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------
// &#39;Bitway&#39; &#39;ERC20 Token&#39;
// 
// Name        : Bitway
// Symbol      : BTWX
// Max supply  : 21m
// Decimals    : 18
//
// Bitway "BTWX"
// ----------------------------------------------------------------------------
//
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
// ERC20 Token Standard
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name, decimals and totalSupply
// ----------------------------------------------------------------------------
contract Bitway is ERC20 {
    
    using SafeMath for uint;

    string public name = "Bitway";
    string public symbol = "BTWX";
    uint public totalSupply = 0;
    uint8 public decimals = 18;
    uint public RATE = 1000;
    
    uint multiplier = 10 ** uint(decimals);
    uint million = 10 ** 6;
    uint millionTokens = 1 * million * multiplier;
    
    uint constant stageTotal = 5;
    uint stage = 0;
    uint [stageTotal] targetSupply = [
         1 * millionTokens,
         2 * millionTokens,
         5 * millionTokens,
         10 * millionTokens,
         21 * millionTokens
    ];
    
    address public owner;
    bool public completed = true;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
    owner = msg.sender;
    supplyTokens(millionTokens);
    }
    
    // ------------------------------------------------------------------------
    // Payable token creation
    // ------------------------------------------------------------------------
    function () public payable {
        createTokens();
    }
    
    // ------------------------------------------------------------------------
    // Returns currentStage
    // ------------------------------------------------------------------------
    function currentStage() public constant returns (uint) {
        return stage + 1;
    }
    
    // ------------------------------------------------------------------------
    // Returns maxSupplyReached True / False
    // ------------------------------------------------------------------------
    function maxSupplyReached() public constant returns (bool) {
        return stage >= stageTotal;
    }
    
    // ------------------------------------------------------------------------
    // Token creation
    // ------------------------------------------------------------------------
    function createTokens() public payable {
        require(!completed);
        supplyTokens(msg.value.mul((15 - stage) * RATE / 10)); 
        owner.transfer(msg.value);
    }
    
    // ------------------------------------------------------------------------
    // Complete token sale
    // ------------------------------------------------------------------------
    function setComplete(bool _completed) public {
        require(msg.sender == owner);
        completed = _completed;
    }
    
    // ------------------------------------------------------------------------
    // Check totalSupply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Create tokens and supply to msg.sender balances
    // ------------------------------------------------------------------------
    function supplyTokens(uint tokens) private {
        require(!maxSupplyReached());
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        if (totalSupply >= targetSupply[stage]) {
            stage += 1;
        }
        emit Transfer(address(0), msg.sender, tokens);
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
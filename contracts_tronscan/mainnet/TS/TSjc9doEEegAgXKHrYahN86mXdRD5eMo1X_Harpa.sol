//SourceUnit: Harpa.sol

pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// HarpaDeFi TRC20 Token
// Symbol         : HAA
// Name           : HarpaDeFi
// Total supply   : 1 000 000
// Decimals       : 18
//
// (c) by Harpa.Network
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
    // ------------------------------------------------------------------------
    // ERC20 Token, but used as TRC20 with the addition of symbol, name and decimals supply and founder
    // ------------------------------------------------------------------------
contract Harpa is ERC20Interface{
    string public name = "HarpaDeFi";
    string public symbol = "HAA";
    uint8 public decimals = 18;
    // (1 mln with 18 decimals) 
    uint public supply; 
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
    //allowed[0x111...owner][0x2222...spender] = 100;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // ------------------------------------------------------------------------
    // Constructor With 1 000 000 supply, All deployed tokens sent to Genesis wallet
    // ------------------------------------------------------------------------
    constructor() public{
        supply = 1000000000000000000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns(uint){
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    //  Transfer tokens from the 'from' account to the 'to' account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        return true;
    }
    // ------------------------------------------------------------------------
    // Public function to return supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint){
        return supply;
    }
    // ------------------------------------------------------------------------
    // Public function to return balance of tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Public Function to transfer tokens
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    } 
    // ------------------------------------------------------------------------
    // Revert function to NOT accept TRX
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
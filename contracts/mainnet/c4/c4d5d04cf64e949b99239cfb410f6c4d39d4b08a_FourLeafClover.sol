pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library _SafeMath {
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
// contract WhiteListAccess
// ----------------------------------------------------------------------------
contract WhiteListAccess {
    
    function WhiteListAccess() public {
        owner = msg.sender;
        whitelist[owner] = true;
        whitelist[address(this)] = true;
    }
    
    address public owner;
    mapping (address => bool) whitelist;

    modifier onlyOwner {require(msg.sender == owner); _;}
    modifier onlyWhitelisted {require(whitelist[msg.sender]); _;}

    function addToWhiteList(address trusted) public onlyOwner() {
        whitelist[trusted] = true;
    }

    function removeFromWhiteList(address untrusted) public onlyOwner() {
        whitelist[untrusted] = false;
    }

}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract _ERC20Interface {
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
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply of 0 units.
// The units will be created by demand using the create function reservated for trusted contract&#39;s address 
// ----------------------------------------------------------------------------
contract _Token is WhiteListAccess, _ERC20Interface {
    using _SafeMath for uint;
    
    uint8   public   decimals;
    uint    public   totSupply;
    string  public   symbol;
    string  public   name;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function _Token(string _name, string _sym) public {
        symbol = _sym;
        name = _name;
        decimals = 0;
        totSupply = 0;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totSupply;
    }


    // ------------------------------------------------------------------------
    // Get the _token balance for account `_tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!freezed);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function desapprove(address spender) public returns (bool success) {
        allowed[msg.sender][spender] = 0;
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!freezed);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // FLC API 
    // ------------------------------------------------------------------------
    bool freezed;

    function create(uint units) public onlyWhitelisted() {
        totSupply = totSupply + units;
        balances[msg.sender] = balances[msg.sender] + units;
    }

    function freeze() public onlyWhitelisted() {
        freezed = true;
    }
    
    function unfreeze() public onlyWhitelisted() {
        freezed = false;
    }

    // recover tokens sent accidentally
    function _withdrawal(address _token) public {
        uint _balance =  _ERC20Interface(_token).balanceOf(address(this));
        if (_balance > 0) {
            _ERC20Interface(_token).transfer(owner, _balance);
        }
        owner.transfer(this.balance);
    }
}

contract FourLeafClover is _Token("Four Leaf Clover", "FLC") {
    function FourLeafClover() public {}
}
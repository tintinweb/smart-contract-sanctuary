pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// BadToken
// - `transfer(...)`, `approve(...)` and `transferFrom(...)` do not return true
// - No SafeMath, checks are in place, but no return status
//
// Call `drip()` to get 1,000 tokens transferred to your account
//
// Symbol      : BAD
// Name        : Bad
// Total supply: 100,000,000.000000000000000000
// Decimals    : 18
//
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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
// Bad ERC20 Token, with the addition of symbol, name, decimals, a
// fixed supply and a faucet dripper
// ----------------------------------------------------------------------------
contract BadToken is Owned {

    string public symbol = "BAD";
    string public  name = "Bad";
    uint8 public constant decimals = 18;
    uint constant _totalSupply = 100000000 * 10**uint(decimals);

    uint public constant DRIP_AMOUNT = 1000 * 10**uint(decimals);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Drip from faucet
    // ------------------------------------------------------------------------
    function drip() public {
        if (balances[owner] >= DRIP_AMOUNT) {
            balances[owner] = balances[owner] - DRIP_AMOUNT;
            balances[msg.sender] = balances[msg.sender] + DRIP_AMOUNT;
            emit Transfer(owner, msg.sender, DRIP_AMOUNT);
        }
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    //
    // NOTE - No `true` return status
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public {
        if (balances[msg.sender] >= tokens) {
            balances[msg.sender] = balances[msg.sender] - tokens;
            balances[to] = balances[to] + tokens;
            emit Transfer(msg.sender, to, tokens);
        }
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    //
    // NOTE - No `true` return status
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    //
    // NOTE - No `true` return status
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens) {
            balances[from] = balances[from] - tokens;
            allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
            balances[to] = balances[to] + tokens;
            emit Transfer(from, to, tokens);
        }
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
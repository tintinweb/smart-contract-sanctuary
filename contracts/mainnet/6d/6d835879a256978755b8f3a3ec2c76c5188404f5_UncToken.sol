pragma solidity ^0.4.23;

// File: contracts/Owned.sol

// ----------------------------------------------------------------------------
// Ownership functionality for authorization controls and user permissions
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

// File: contracts/SafeMath.sol

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// File: contracts/ERC20.sol

// ----------------------------------------------------------------------------
// ERC20 Standard Interface
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

// File: contracts/UncToken.sol

// ----------------------------------------------------------------------------
// &#39;UNC&#39; &#39;Uncloak&#39; token contract
// Symbol      : UNC
// Name        : Uncloak
// Total supply: 4,200,000,000
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// Receives ETH and generates tokens
// ----------------------------------------------------------------------------
contract UncToken is SafeMath, Owned, ERC20 {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    // Track whether the coin can be transfered
    bool private transferEnabled = false;

    // track addresses that can transfer regardless of whether transfers are enables
    mapping(address => bool) public transferAdmins;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) internal allowed;

    event Burned(address indexed burner, uint256 value);

    // Check if transfer is valid
    modifier canTransfer(address _sender) {
        require(transferEnabled || transferAdmins[_sender]);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "UNC";
        name = "Uncloak";
        decimals = 18;
        _totalSupply = 4200000000 * 10**uint(decimals);
        transferAdmins[owner] = true; // Enable transfers for owner
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) canTransfer (msg.sender) public returns (bool success) {
        require(to != address(this)); //make sure we&#39;re not transfering to this contract

        //check edge cases
        if (balances[msg.sender] >= tokens
            && tokens > 0) {

                //update balances
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);

                //log event
                emit Transfer(msg.sender, to, tokens);
                return true;
        }
        else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        // Ownly allow changes to or from 0. Mitigates vulnerabiilty of race description
        // described here: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint tokens) canTransfer(from) public returns (bool success) {
        require(to != address(this));

        //check edge cases
        if (allowed[from][msg.sender] >= tokens
            && balances[from] >= tokens
            && tokens > 0) {

            //update balances and allowances
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);

            //log event
            emit Transfer(from, to, tokens);
            return true;
        }
        else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // Owner can allow transfers for a particular address. Use for crowdsale contract.
    function setTransferAdmin(address _addr, bool _canTransfer) onlyOwner public {
        transferAdmins[_addr] = _canTransfer;
    }

    // Enable transfers for token holders
    function enablesTransfers() public onlyOwner {
        transferEnabled = true;
    }

    // ------------------------------------------------------------------------
    // Burns a specific number of tokens
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burned(burner, _value);
    }

    // ------------------------------------------------------------------------
    // Doesn&#39;t Accept Eth
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
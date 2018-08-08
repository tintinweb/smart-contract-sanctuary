pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// ZooblinToken CROWDSALE token contract
//
// Deployed by : 0x9D926842F6D40c3AF314992f7865Bc5be17e8676
// Symbol      : ZBN
// Name        : ZooblinToken
// Total supply: 600000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function zeroSub(uint a, uint b) internal pure returns (uint c) {
        if (a >= b) {
            c = safeSub(a, b);
        } else {
            c = 0;
        }
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract ZooblinToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    uint public startDate;

    uint public preSaleAmount;
    uint private preSaleFrom;
    uint private preSaleUntil;

    uint public roundOneAmount;
    uint private roundOneFrom;
    uint private roundOneUntil;

    uint public roundTwoAmount;
    uint private roundTwoFrom;
    uint private roundTwoUntil;

    uint public roundThreeAmount;
    uint private roundThreeFrom;
    uint private roundThreeUntil;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "ZBN";
        name = "Zooblin Token";
        decimals = 18;
        _totalSupply = 300000000000000000000000000;

        balances[0x9D926842F6D40c3AF314992f7865Bc5be17e8676] = _totalSupply;
        emit Transfer(address(0), 0x9D926842F6D40c3AF314992f7865Bc5be17e8676, _totalSupply);

        startDate       = 1525564800; // Sunday, May 6, 2018 12:00:00 AM

        preSaleAmount   = 20000000000000000000000000;
        roundOneAmount  = 150000000000000000000000000;
        roundTwoAmount  = 80000000000000000000000000;
        roundThreeAmount= 50000000000000000000000000;

        preSaleFrom     = 1527811200; // Friday, June 1, 2018 12:00:00 AM
        preSaleUntil    = 1531699199; // Sunday, July 15, 2018 11:59:59 PM

        roundOneFrom    = 1533081600; // Wednesday, August 1, 2018 12:00:00 AM
        roundOneUntil   = 1535759999; // Friday, August 31, 2018 11:59:59 PM

        roundTwoFrom    = 1535760000; // Saturday, September 1, 2018 12:00:00 AM
        roundTwoUntil   = 1538351999; // Sunday, September 30, 2018 11:59:59 PM

        roundThreeFrom  = 1538352000; // Monday, October 1, 2018 12:00:00 AM
        roundThreeUntil = 1541030399; // Wednesday, October 31, 2018 11:59:59 PM
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Pre-sale Period
    // ------------------------------------------------------------------------
    function isPreSalePeriod(uint date) public constant returns (bool) {
        return date >= preSaleFrom && date <= preSaleUntil && preSaleAmount > 0;
    }

    // ------------------------------------------------------------------------
    // Round One Sale Period
    // ------------------------------------------------------------------------
    function isRoundOneSalePeriod(uint date) public constant returns (bool) {
        return date >= roundOneFrom && date <= roundOneUntil && roundOneAmount > 0;
    }

    // ------------------------------------------------------------------------
    // Round Two Sale Period
    // ------------------------------------------------------------------------
    function isRoundTwoSalePeriod(uint date) public constant returns (bool) {
        return date >= roundTwoFrom && date <= roundTwoUntil && roundTwoAmount > 0;
    }

    // ------------------------------------------------------------------------
    // Round Three Sale Period
    // ------------------------------------------------------------------------
    function isRoundThreeSalePeriod(uint date) public constant returns (bool) {
        return date >= roundThreeFrom && date <= roundThreeUntil && roundThreeAmount > 0;
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
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // 10,000 ZBN Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && msg.value >= 1000000000000000000);

        uint tokens = 0;

        if (isPreSalePeriod(now)) {
            tokens = msg.value * 13000;
            preSaleAmount = zeroSub(preSaleAmount, tokens);
        }

        if (isRoundOneSalePeriod(now)) {
            tokens = msg.value * 11500;
            roundOneAmount = zeroSub(roundOneAmount, tokens);
        }

        if (isRoundTwoSalePeriod(now)) {
            tokens = msg.value * 11000;
            roundTwoAmount = zeroSub(roundTwoAmount, tokens);
        }

        if (isRoundThreeSalePeriod(now)) {
            tokens = msg.value * 10500;
            roundThreeAmount = zeroSub(roundThreeAmount, tokens);
        }

        require(tokens > 0);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
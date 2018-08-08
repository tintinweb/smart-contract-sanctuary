pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
//
// Symbol      : YUC
// Name        : Yet Another Useless Coin
// Total supply: 10^7
// Decimals    : 10
//
// Enjoy.
//
// (c) With reference to Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
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
contract YetAnotherUselessToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 public _totalSupply;
    bool public purchasingAllowed;
    uint256 public totalContribution;
    uint256 public totalIssued;
    uint256 public totalBonusTokensIssued;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "YUC";
        name = "YetAnotherUselessToken";
        decimals = 10;
        _totalSupply = 10000000;
        balances[owner] = _totalSupply * (10 ** decimals);
        purchasingAllowed = false;
        totalContribution = 0;
        totalIssued = 0;
        totalBonusTokensIssued = 0;

        emit Transfer(address(0), owner, _totalSupply * (10 ** decimals));
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply * (10 ** decimals)  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
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
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // purchasingAllowed
    // ------------------------------------------------------------------------
    function purchasingAllowed() public constant returns (bool) {
        return purchasingAllowed;
    }

    function enablePurchasing() public onlyOwner {
        purchasingAllowed = true;
    }

    function disablePurchasing() public onlyOwner {
        purchasingAllowed = false;
    }

    // ------------------------------------------------------------------------
    // Interface to the web app.
    // Its Keccak-256 hash value is 0xc59d4847
    // ------------------------------------------------------------------------
    function getStats() constant public returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalIssued, totalBonusTokensIssued, purchasingAllowed);
    }

    // -----------------------------------------------------------------------
    // Accept ETH
    // ------------------------------------------------------------------------
    function() public payable {
        if (!purchasingAllowed) { revert(); }

        if (msg.value == 0) { return; }

        owner.transfer(msg.value);

        totalContribution += msg.value;

        // issue the token
        uint256 tokensIssued = (msg.value * 100);
        if (msg.value >= 10 finney) {
            bytes20 bonusHash = ripemd160(block.coinbase, block.number, block.timestamp);
            if (bonusHash[0] == 0) {
                uint256 bonusMultiplier =
                    ((bonusHash[1] & 0x01 != 0) ? 1 : 0) + ((bonusHash[1] & 0x02 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x04 != 0) ? 1 : 0) + ((bonusHash[1] & 0x08 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x10 != 0) ? 1 : 0) + ((bonusHash[1] & 0x20 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x40 != 0) ? 1 : 0) + ((bonusHash[1] & 0x80 != 0) ? 1 : 0);

                uint256 bonusTokensIssued = (msg.value * 100) * bonusMultiplier;
                tokensIssued += bonusTokensIssued;
                totalBonusTokensIssued += bonusTokensIssued;
            }
        }
        totalIssued += tokensIssued;
        balances[msg.sender] += tokensIssued * (10 ** decimals);
        balances[owner] -= tokensIssued * (10 ** decimals);

        emit Transfer(owner, msg.sender, tokensIssued * (10 ** decimals));
    }
}
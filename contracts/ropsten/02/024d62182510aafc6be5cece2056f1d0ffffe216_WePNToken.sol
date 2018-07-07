pragma solidity ^0.4.18;

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
// EscrowableToken contract
// ----------------------------------------------------------------------------
contract EscrowableToken {
    //escrow a specified amount of tokens
    function createEscrow(address receiver, uint256 tokens, uint256 expireTime) public returns (bool success);

    //query the escrow
    function queryEscrow(address from, address to) public returns (bool exist, uint256 amount, uint256 expireTime);

    //sender to release an escrow regardless of whether it is expired
    function releaseEscrow(address receiver) public returns (bool success);

    //release an escrow if it is expired.
    function releaseExpiredEscrow(address from, address to) public returns (bool success);

    //sender to terminate an unreleased escrow. Tokens will be transferred to contract owner.
    function terminateEscrow(address receiver) public returns (bool success);
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
contract WePNToken is ERC20Interface, Owned, SafeMath, EscrowableToken {

    struct Escrow {
        //flag for if this struct exist
        bool exist;
        //amount of tokens escrowed
        uint256 amount;
        //epoch in seconds. If an escrow is expired then it can be released by anyone
        uint256 expireTime;
    }

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    mapping(address => mapping(address => Escrow)) escrowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = &quot;WEPN&quot;;
        name = &quot;WePN Token&quot;;
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
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
    // Token owner can approve for spender to transferFrom(...) tokens
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
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
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
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    //escrow a specified amount of tokens
    function createEscrow(address receiver, uint256 tokens, uint256 expireTime) public returns (bool success) {
        Escrow storage escrow = escrowed[msg.sender][receiver];
        if (escrow.exist == true) {
          return false;
        }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        escrowed[msg.sender][receiver] = Escrow({
            exist: true,
            amount: tokens,
            expireTime: expireTime
        });
        return true;
    }

    //query the escrow
    function queryEscrow(address from, address to) public returns (bool exist, uint256 amount, uint256 expireTime) {
        if (escrowed[from][to].exist == true) {
            return (escrowed[from][to].exist, escrowed[from][to].amount, escrowed[from][to].expireTime);
        } else {
            return (false, 0, 0);
        }
    }

    //sender to release an escrow regardless of whether it is expired
    function releaseEscrow(address receiver) public returns (bool success) {
        Escrow storage escrow = escrowed[msg.sender][receiver];
        if (escrow.exist == true) {
            checkoutEscrowAndDelete(escrow, msg.sender, receiver);
            return true;
        }
        return false;
    }

    //release an escrow if it is expired.
    function releaseExpiredEscrow(address from, address to) public returns (bool success) {
        Escrow storage escrow = escrowed[from][to];
        if (escrow.exist == true) {
            uint256 currentTime = block.timestamp;
            if (escrow.expireTime < currentTime) {
                checkoutEscrowAndDelete(escrow, from, to);
                return true;
            }
        }
        return false;
    }

    //sender to terminate an unreleased escrow. Tokens will be transferred to contract owner.
    function terminateEscrow(address receiver) public returns (bool success) {
        Escrow storage escrow = escrowed[msg.sender][receiver];
        if (escrow.exist == true) {
            uint256 currentTime = block.timestamp;
            if (escrow.expireTime > currentTime) {
                balances[owner] = safeAdd(balances[owner], escrow.amount);
                delete escrowed[msg.sender][receiver];
                return true;
            }
        }
        return false;
    }

    function checkoutEscrowAndDelete(Escrow escrow, address from, address to) private {
        balances[to] = safeAdd(balances[to], escrow.amount);
        delete escrowed[from][to];
    }
}
pragma solidity ^0.4.24;


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
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
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


contract Owned {
    address public owner;
    // address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // function transferOwnership(address _newOwner) public onlyOwner {
    //     newOwner = _newOwner;
    // }

    // function acceptOwnership() public {
    //     require(msg.sender == newOwner);
    //     emit OwnershipTransferred(owner, newOwner);
    //     owner = newOwner;
    //     newOwner = address(0);
    // }
}


contract VXV is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    uint public rate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "VXV";
        name = "VectorspaceAI";
        decimals = 18;
        totalSupply = 50000000 * 10 ** uint256(decimals);
        rate = 203;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function changeRate(uint newRate) public onlyOwner {
        require(newRate > 0);
        rate = newRate;
    }

    function totalSupply() public view returns (uint) {
        return totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    modifier validTo(address to) {
        require(to != address(0));
        require(to != address(this));
        _;
    }

    function transferInternal(address from, address to, uint tokens) internal {
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function transfer(address to, uint tokens) public validTo(to) returns (bool success) {
        transferInternal(msg.sender, to, tokens);
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
    function transferFrom(address from, address to, uint tokens) public validTo(to) returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        transferInternal(from, to, tokens);
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

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        if (approve(spender, tokens)) {
            ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
            return true;
        }
    }

    function () public payable {
        uint tokens;
        tokens = safeMul(msg.value, rate);

        balances[owner] = safeSub(balances[owner], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);

        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    // function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    //     return ERC20Interface(tokenAddress).transfer(owner, tokens);
    // }
}
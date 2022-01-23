/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        virtual
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        public
        virtual
        returns (bool success);

    function approve(address to, uint256 tokens)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a - b;
        require(b <= a);
    }
}

// ----------------------------------------------------------------------------
//  MattBucks token
// ----------------------------------------------------------------------------
contract MattBucks is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    address private owner;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() {
        name = "MattBucks";
        symbol = "MATB";
        decimals = 0;
        _totalSupply = 0;
        owner = msg.sender;
    }

    // Allow Matt (Owner) to mint more MattBucks and send them to a reciever
    function mint(address reciever, uint256 amount)
        public
        returns (bool success)
    {
        require(owner == msg.sender, "Caller is not the owner");
        // require(amount % 1 == 0, "MattBucks are indivisible");
        balances[reciever] = safeAdd(balances[reciever], amount);
        _totalSupply = safeAdd(_totalSupply, amount);

        emit Transfer(address(0), reciever, amount);
        return true;
    }

    // Allow matt to destroy MattBucks
    function destroy() public returns (bool success) {
        require(msg.sender == owner, "Caller is not the owner");
        selfdestruct(payable(owner));
        return true;
    }

    // Allow the owner to pass ownership to another account
    function changeOwner(address newOwner) public returns (bool success) {
        require(owner == msg.sender, "Caller is not the owner");
        owner = newOwner;
        return true;
    }

    // Checks the total supply of tokens in the ecosystem
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Checks the number of tokens in the passed in account
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    // Record the remaining amount someone else is allowed
    // to withdraw from  a token owners account.
    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // Set the amount of allowance the spender is allowed to transfer from the caller
    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(
            balances[msg.sender] >= tokens,
            "Allowance cannot be greater than account balance"
        );
        // require(tokens % 1 == 0, "MattBucks are indivisible");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Moves tokens from the caller into the recievers account
    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens, "Insufficient funds");
        require(msg.sender != to, "Cannot transfer tokens to the same account");
        // require(tokens % 1 == 0, "MattBucks are indivisible");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Facilitates automatic payment transfers from an authorized source
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(balances[from] >= tokens, "Insufficient funds");
        require(
            allowed[from][msg.sender] >= tokens,
            "Transaction is not approved"
        );
        // require(tokens % 1 == 0, "MattBucks are indivisible");

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(from, to, tokens);
        return true;
    }
}
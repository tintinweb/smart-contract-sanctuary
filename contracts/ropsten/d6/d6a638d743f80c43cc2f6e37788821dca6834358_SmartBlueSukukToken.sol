// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "Address.sol";
import "Ownable.sol";
import "Context.sol";
// ----------------------------------------------------------------------------
// 'SmartBlueSukuk' token contract
//
// Deployed to : 0xfCc68f72a9B81B2Cb2c8D3C2AC899B42Be2F2307
// Symbol      : SBST
// Name        : SmartBlueSukukToken
// Decimals    : 18
// (c) by Lise Demay and Sean Ng. 

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//Contract function to receive approval and execute function in one call
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------

contract SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// SmartBlueSukuk Token, with the addition of symbol, name, decimals, version and assisted
// token transfers
// ----------------------------------------------------------------------------
contract SmartBlueSukukToken is ERC20Interface, SafeMath, Context, Ownable  {
    using Address for address;
    
    using Address for address;
    
    string public name;
    string public symbol;
    string public version;
    uint8 public decimals;

    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        name = "SmartBlueSukukToken";
        symbol = "SBST";
        version = "0.0.1";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view virtual override returns (uint balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom (...) tokens
    // from the token owner's account 
    // no checks for the approval double-spend attack
    // as this would be implemented in a user interface called SBS (Smart Blue Sukuk)
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Atomically increases the allowance granted to `spender` by the caller.
    // ------------------------------------------------------------------------
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender] + (addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Atomically decreases the allowance granted to `spender` by the caller.
    // ------------------------------------------------------------------------
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender] - (subtractedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Creates `amount` tokens and assigns them to `account`, increasing the total supply
    // Emits a {Transfer} event with `from` set to the zero address.
    // ------------------------------------------------------------------------
    function _mint(address account, uint256 amount) internal virtual{
        require(amount != 0,"ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
    // ------------------------------------------------------------------------
    // Creates `amount` tokens and assigns them to `account`, increasing the total supply
    // Emits a {Transfer} event with `from` set to the zero address.
    // ------------------------------------------------------------------------
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    
    // ------------------------------------------------------------------------
    // Hook that is called before any transfer of tokens. 
    //This includes minting and burning.
    //Creates `amount` tokens and assigns them to `account`, increasing the total supply
    // ------------------------------------------------------------------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    // ------------------------------------------------------------------------
    // Hook that is called after any transfer of tokens. This includes minting and burning. 
    // ------------------------------------------------------------------------

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
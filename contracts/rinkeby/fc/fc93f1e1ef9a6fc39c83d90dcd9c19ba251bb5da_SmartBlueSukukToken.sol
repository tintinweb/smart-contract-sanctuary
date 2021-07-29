// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "Address.sol";

// ----------------------------------------------------------------------------
// 'SmartBlueSukuk' token contract
//
// Deployed to : 0xfCc68f72a9B81B2Cb2c8D3C2AC899B42Be2F2307
// Symbol      : SBST
// Name        : SmartBlueSukukToken
// Decimals    : 18
// (c) by Lise Demay and Sean Ng. 

// ----------------------------------------------------------------------------
// Safe Math Library
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
//
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
// Ownable contract
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;
    address public newOwner;

    // MODIFIERS

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /// @dev Throws if called by any account other than the new owner.
    modifier onlyNewOwner() {
        require(msg.sender == newOwner, "Only New Owner");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0),"address is Null");
        _;
    }

    // CONSTRUCTORS

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param _newOwner The address to transfer ownership to.
    
    function transferOwnership(address _newOwner) public notNull(_newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    /// @dev Allow the new owner to claim ownership and so proving that the newOwner is valid.
    function acceptOwnership() public onlyNewOwner {
        address oldOwner = owner;
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    // EVENTS
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/*
 *Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender); // added payable
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode 
        return msg.data;
    }
}

// ----------------------------------------------------------------------------
// SmartBlueSukuk Token, with the addition of symbol, name, decimals, version and assisted
// token transfers
// ----------------------------------------------------------------------------
contract SmartBlueSukukToken is ERC20Interface, Context, Ownable, SafeMath  {
    using Address for address;
    
    string public name;
    string public symbol;
    string public version;
    uint8 public decimals;

    uint public _totalSupply;
    
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

        balances[0xfCc68f72a9B81B2Cb2c8D3C2AC899B42Be2F2307] = _totalSupply;
        emit Transfer(address(0), 0xfCc68f72a9B81B2Cb2c8D3C2AC899B42Be2F2307, _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
     function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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
// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
import { ITokenManager, IERC20, ISafeMath } from './Interfaces.sol';

// ----------------------------------------------------------------------------
// Implementation of ERC20 Standard
// ----------------------------------------------------------------------------
contract ERC20 is IERC20 {
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint public _totalSupply;

    // For each person map between their address and the number of tokens they have
    mapping(address => uint) balances;
    // To transfer erc20 token, give contract permission to transfer. Maps from your address to address of transfer target and amount to transfer.
    mapping(address => mapping(address => uint)) allowed;

    ISafeMath immutable public safemath;

    constructor(string memory symbol, string memory name, uint8 decimals, uint total_supply, ISafeMath safemath_contract) {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = total_supply;
        safemath = safemath_contract;
    }

    //Returns decimals that this token uses.
    function decimals() public view returns (uint8) {
        return _decimals;
    }


    //Returns the token name
    function name() public view returns (string memory) {
        return _name;
    }


    //Returns the symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }


    // Return total supply
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }


    // Return the token balance for account tokenOwner
    function balanceOf(address _token_owner) public override view returns (uint balance) {
        return balances[_token_owner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _num_tokens) public override returns (bool success) {
        require(_num_tokens <= balances[msg.sender], "You are trying to transfer more tokens than you have");

        balances[msg.sender] = safemath.sub(balances[msg.sender], _num_tokens);
        balances[_to] = safemath.add(balances[_to], _num_tokens);
        emit Transfer(msg.sender, _to, _num_tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // Non-standard approval function that takes care of the potential double-spend issue
    // If a user wants to ensure that the double spend issue doesn't become a problem, they can choose
    // to use this function instead of the standard approve function.
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        allowed[msg.sender][_spender] = safemath.add(oldValue, _addedValue);
        emit Approval(msg.sender, _spender, safemath.add(oldValue, _addedValue));
        return true;
    }


    // Non-standard approval function that takes care of the potential double-spend issue
    // If a user wants to ensure that the double spend issue doesn't become a problem, they can choose
    // to use this function instead of the standard approve function.
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        allowed[msg.sender][_spender] = safemath.sub(oldValue, _subtractedValue);
        emit Approval(msg.sender, _spender, safemath.sub(oldValue, _subtractedValue));
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
        balances[from] = safemath.sub(balances[from], tokens);
        allowed[from][msg.sender] = safemath.sub(allowed[from][msg.sender], tokens);
        balances[to] = safemath.add(balances[to], tokens);
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

}
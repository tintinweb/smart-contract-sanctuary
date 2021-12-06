/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // DONE: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    address public minter = 0x2EA7985d8ec271F452fFE427f133CDFF0E32Eb38;
    uint256 supply = 50000;
 
    // DONE: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // DONE: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // DONE: create mapping for balances
    mapping (address => uint256) public balances;

    // DONE: create mapping for allowances
    mapping (address => mapping(address => uint256)) public allowances;

    constructor() public {
        // DONE: set sender's balance to total supply
        balances[msg.sender]=supply;
    }

    function totalSupply() public view returns (uint256) {
        // DONE: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // DONE: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // DONE: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter,"You are not an approved minter");
        require((supply + amount) <= MAXSUPPLY,"With this amount minted, total supply would be larger than maximum authorized supply");
        balances[receiver] += amount;
        supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // DONE: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(supply-amount >= 0,"With this amount burned, total supply would be negative");
        balances[address(0)] += amount;
        supply -= amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // DONE: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership 
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter,"You are not authorized to transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(msg.sender, minter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // DONE: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender],"You don't have enough tokens to perform this transaction");
        require(_value > 1,"Transation is not large enough to cover the fees");
        balances[msg.sender]-= _value;
        balances[_to]+= _value - 1;
        balances[minter] += 1;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // DONE: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[_from],"Sender account doesn't have enough tokens to perform this transaction");
        require(_value > 1,"Transation is not large enough to cover the fees");
        require(_value <= allowances[_from][msg.sender],"Sender account didn't allow you to spend that amount on his behalf");
        balances[_from]-= _value;
        balances[_to] += _value-1;
        allowances[_from][msg.sender] -= _value;
        balances[minter] += 1;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // DONE: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // DONE: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
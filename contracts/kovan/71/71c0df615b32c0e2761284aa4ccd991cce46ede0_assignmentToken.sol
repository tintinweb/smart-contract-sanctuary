/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // DONE: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    address public minter = 0xbB124629feC7f8dd86624628d17Dbc0a6A23fd74;
    uint256 supply = 50000;
 
    // DONE: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // DONE: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // DONE: create mapping for balances
    mapping (address => uint) public balances;

    // DONE: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

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
        require(msg.sender == minter,"You have not been approved");
        require(supply+amount <= MAXSUPPLY,"Total supply would be greater than the maximum authorized if this amount is minted.");
        balances[receiver] += amount;
        supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // DONE: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(supply-amount >= 0,"The total supply would be negative with this amount burned.");
        balances[address(0)] += amount;
        supply -= amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // DONE: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership 
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter,"You have not been authorized to transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(msg.sender, minter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // DONE: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value +1 <= balances[msg.sender],"This transaction cannot be completed because you don't have enough tokens.");
        require(_value > 1,"The volume of transation is insufficient to cover the fees.");
        balances[msg.sender]-= _value + 1;
        balances[_to]+= _value;
        balances[minter] += 1;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // DONE: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value + 1 <= balances[_from],"This transaction cannot be completed because the sender account does not have enough tokens.");
        require(_value > 1,"The volume of transation is insufficient to cover the fees.");
        require(_value <= allowances[_from][msg.sender],"You cannot spend that amount on sender's behalf as he didn't allowed you to do so.");
        balances[_from]-= _value + 1;
        balances[_to] += _value;
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
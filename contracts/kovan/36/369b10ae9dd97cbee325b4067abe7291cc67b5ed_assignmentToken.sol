/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
        address public minter;
        uint256 total_supply = 50000;
        uint256 constant max_supply = 1000000;
        uint256 constant flat_fee = 1;
        //NEED TO DECLARE minter
    // TODO: specify event to be emitted on transfer
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // TODO: specify event to be emitted on approval
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances
        mapping(address => uint) public balances;
    // TODO: create mapping for allowances
        mapping (
        address => mapping(address => uint)
        ) public allowances;
    constructor() public {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        balances[msg.sender] = total_supply;}

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return total_supply;}

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];}

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        require(msg.sender == minter);
        require(total_supply + amount <= max_supply);
        total_supply += amount;
        balances[receiver] += amount;
        // NOTE: total supply must not exceed `MAXSUPPLY`
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount; 
        emit Transfer(msg.sender, address(0),amount);
        return true;
        // NOTE: must have enough balance to burn
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value + flat_fee <= balances[msg.sender]);
        balances[_to] +=_value;
        balances[msg.sender] -= _value - flat_fee;
        balances[minter] += flat_fee;
        emit Transfer(msg.sender, minter, flat_fee);
        emit Transfer(msg.sender, _to, _value);
        return true;}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee 
        require(_value <= balances[msg.sender]);
        require(allowances[_from][msg.sender] >= _value + flat_fee);
        balances[_from] -= _value + flat_fee;
        balances[_to] += _value; 
        balances[minter] += flat_fee;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(msg.sender, minter, flat_fee);
        emit Transfer(_from, _to, _value);
        return true;} 

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;}//from lab

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];}
}
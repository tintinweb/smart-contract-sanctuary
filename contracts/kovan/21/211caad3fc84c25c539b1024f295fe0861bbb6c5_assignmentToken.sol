/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract assignmentToken {
    // MAXSUPPLY, supply, fee and minter
    uint256 constant private fee = 1;
    uint256 constant private MAXSUPPLY = 1000000;
    uint256 private supply = 50000;
    address private minter;

    // Event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Event to be emitted on mintership transfer
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // Mapping for balances
    mapping (address => uint) public balances;

    // Mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        // Sender's balance gets set to total supply and sender gets assigned as minter
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // Returns total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // Returns the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + amount <= MAXSUPPLY, "The added supply will exceed the max supply");
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        // The sender needs to be the current minter to burn tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        supply -= amount;
        balances[address(0)] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // Transfer mintership to newminter
        // Only incumbent minter can transfer mintership
        // Should emit MintershipTransfer event
        require(msg.sender == minter, "Sender is not the current minter");
        minter = newMinter;
        emit MintershipTransfer(minter, newMinter);
        return true;
    }

    function doTransfer(address _from, address _to, uint256 _value) private returns (bool) {
        require(balances[_from] >= _value, "Insufficient balance");
        require(fee < _value, "Cover fee exceeds the transfer value");
        balances[_from] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from sender to `_to`
        // Sender needs to have enough tokens
        // Transfer value needs to be sufficient to cover fee
        bool response = doTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return response;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from `_from` to `_to`
        // `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // Transfer value needs to be sufficient to cover fee
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        bool response = doTransfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return response;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Allow `_spender` to spend `_value` on sender's behalf
        // If an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // Return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
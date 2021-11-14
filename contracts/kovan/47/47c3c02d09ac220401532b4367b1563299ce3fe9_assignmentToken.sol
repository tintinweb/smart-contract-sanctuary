/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 MAXSUPPLY = 1000000;
    address minter = msg.sender;
    uint256 supply = 50000;
    uint256 constant fee = 1;
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

    constructor() {
        // TODO: set sender's balance to total supply
        balances[msg.sender] = supply;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(supply <= MAXSUPPLY);
        balances[receiver] += amount;
        supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
        
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender]);
        require(_value > fee);
        balances[minter] += fee;
        uint256 _newVal = _value-fee;
        balances[_to] += _newVal;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender,  _to, _newVal);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[_from]);
        require(_value > fee);
        require(allowances[_from][msg.sender] >= _value);
        uint256 _newVal = _value-fee;
        balances[minter] += fee;
        balances[_from]-= _value;
        balances[_to] += _newVal;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from,  _to, _newVal);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value; // Here we're assigning the allowance of the _spender
        emit Approval(msg.sender, _spender, _value);  // Here we're checking if the allowance is OKAY
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
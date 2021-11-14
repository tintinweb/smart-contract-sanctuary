/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant _maxSupply = 1000000;
    uint256 supply = 50000;
    address public minter;
    uint256 constant _fee = 1;

    // TODO: specify event to be emitted on transfer
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value,
        uint256 _fee
        );

    // TODO: specify event to be emitted on approval
    event Approval(
        address indexed _sender, 
        address indexed _receiver, 
        uint256 _value,
        uint256 _fee
    );

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
        minter = msg.sender;
        balances[msg.sender]=supply;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address _receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter);
        require(supply + amount <= _maxSupply);
        balances[_receiver] += amount;
        supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        supply -= amount;
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

    function transfer(address _to, uint256 _value, uint256 _fee) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value + _fee <= balances[msg.sender]);
        balances[msg.sender] -= _value + _fee;
        balances[_to] += _value;
        balances[minter] += _fee;
        emit Transfer(msg.sender, _to, _value, _fee);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value + _fee <= balances[msg.sender]);
        require(allowances[_from][msg.sender] >= _value + _fee);
        balances[_from] -= _value + _fee;
        balances[_to] += _value;
        balances[minter] += _fee;
        allowances[_from][msg.sender] -= _value + _fee;
        emit Transfer(_from, _to, _value, _fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        require(_value <= balances[msg.sender]);
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value, _fee);
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
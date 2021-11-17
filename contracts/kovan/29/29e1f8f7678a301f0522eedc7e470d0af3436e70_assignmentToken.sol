/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`
    uint256 constant MAXSUPPLY = 1000000;
    
    // TODO: declare `minter` and `supply
    address public minter;
    uint256 supply = 50000; 
    
    
    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);
    // TODO: create mapping for balances
    // TODO: create mapping for allowances
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowances;

    // The initial supply belongs to the minter. 
    constructor() {
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    // TODO: return total supply
    function totalSupply() public view returns (uint256) {
        return supply;
    }
    
    // TODO: return the balance of _owner
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    // TODO: mint tokens by updating receiver's balance and total supply
    // NOTE: total supply must not exceed `MAXSUPPLY`
    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        require((supply + amount) <= MAXSUPPLY);
        balances[receiver] = balances[receiver] + amount;
        supply = supply + amount;
        return true;
    }   

    // TODO: burn tokens by sending tokens to `address(0)`
    // NOTE: must have enough balance to burn
    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        supply = supply - amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }


    // TODO: transfer mintership to newminter
    // NOTE: only incumbent minter can transfer mintership
    // NOTE: should emit `MintershipTransfer` event
    function transferMintership(address newMinter) public returns (bool) {
        require (msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens
    // NOTE: transfer value needs to be sufficient to cover fee
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_value >= 1);
        balances[_to] += _value - 1;
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[minter] = balances[minter] + 1;
        emit Transfer(msg.sender, _to,  _value);
        return true;
    }

    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    // NOTE: transfer value needs to be sufficient to cover fee
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(allowances[_from][msg.sender] >= _value);
        require(_value >= 1);
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value - 1;
        balances[minter] = balances[minter] + 1;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval( msg.sender, _spender, _value);
        return true;
    }

    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}
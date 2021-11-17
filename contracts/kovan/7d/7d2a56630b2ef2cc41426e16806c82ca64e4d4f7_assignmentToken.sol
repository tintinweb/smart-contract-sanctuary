/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 supply = 50000;
    uint256 MAXSUPPLY = 1000000;
    address public minter;

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
        balances[msg.sender]= supply;
        minter = msg.sender;
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
        require (msg.sender == minter, "Solely minters are permitted to mint new tokens" );
        require ((supply+amount) <= MAXSUPPLY,"the total supply cannot be more than 1000000");
        balances[receiver] += amount;
        supply += amount;
        return true;
        // NOTE: total supply must not exceed `MAXSUPPLY`
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        require (balances[msg.sender] > amount);
        balances[msg.sender] -= amount;
        balances[address(0)] += amount;
        supply = supply - amount;
        emit Transfer(msg.sender,address(0),amount);
        return true;
        // NOTE: must have enough balance to burn

    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        require(msg.sender == minter,"solely a minter is permitted to transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(msg.sender,newMinter);
        return true;
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        require(balances[msg.sender] > _value);
        require(_value > 1,"Please increase the Transfer amount. It should be more than 1");
        balances[msg.sender] -= _value;
        balances[_to] += _value-1;
        balances[minter] += 1;
        emit Transfer(msg.sender,_to,_value);
        emit Transfer(msg.sender,minter,1);
        return true; 
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        //require(balances[_from])
        require (_value <= balances[msg.sender],"Sorry, you do not have sufficient balance");
        require (allowances[_from][msg.sender]>= _value,"Sorry, Approval was not granted for the following transfer");
        require(_value > 1,"Please increase the amount you want to transfer, it needs to be more than 1");
        balances[_from] -= _value;
        balances[_to] += _value-1;
        balances[minter] += 1;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from,minter,1);
        return true;
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);
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
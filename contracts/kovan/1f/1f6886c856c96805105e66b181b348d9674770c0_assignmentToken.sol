/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000; // maximum supply of tokens at 1m
    uint256 supply = 50000; // initial supply of tokens at 50k
    address public minter;

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);
    
    // TODO: burn tokens by sending tokens to `address(0)` must have enough balance to burn
    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        supply =  supply  - amount;
        balances[msg.sender] -= amount;
        transfer(address(0), amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address previousMinter, address newMinter) public returns (bool) {
        require(msg.sender == minter);
        previousMinter == msg.sender;
        newMinter == minter;
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        emit MintershipTransfer(previousMinter,newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require((_value + 1) <= balances[msg.sender]);
        balances[_to] += _value;
        balances[msg.sender] -= (_value + 1);
        balances[minter] += balances[minter] + 1;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) 
        public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to` 
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value +1 <= (balances[_from])); // account for transfer fee
        require(allowances[_from][msg.sender] >= (_value + 1)); // account for transfer fee
        balances[_from] -= (_value -1);
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        balances[minter] += 1;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // TODO: specify event to be emitted on transfer 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // TODO: create mapping for balances
    mapping(address => uint256) public balances;
    
    // TODO: create mapping for allowances
    mapping(address => mapping(address => uint)) public allowances;
    
    // TODO: return the balance of _owner 
    function balanceOf(address _owner) public view returns (uint256) {return balances[_owner];}

    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner` 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
        {remaining = allowances[_owner][_spender]; return remaining;}
    
    // TODO: allow `_spender` to spend `_value` on sender's behalf - Done!
    // NOTE: if an allowance already exists, it should be overwritten
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value; emit Approval(msg.sender, _spender, _value); return true;}
        
    // TODO: set sender's balance to total supply
    constructor(){balances[msg.sender] = supply; msg.sender == minter;} 
    
    // TODO: return total supply
    function totalSupply() public view returns (uint256) {return supply;}
   
    // TODO: mint tokens by updating receiver's balance and total supply - Done!
    // NOTE: total supply must not exceed `MAXSUPPLY` 
    function mint(address receiver, uint256 amount) public returns (bool) {
    require(receiver == minter);
    require((amount + supply) <= MAXSUPPLY); 
    balances[receiver] += amount;
    supply += amount;
    emit Transfer(receiver, receiver, amount);
    return true;
    }

}
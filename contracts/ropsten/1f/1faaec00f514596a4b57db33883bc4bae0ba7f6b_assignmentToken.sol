/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`

    uint256 private supply = 50000;
    address minter;
    uint256 constant MAXSUPPLY = 1000000;
    
    // TODO: specify event to be emitted on transfer
    // TODO: specify event to be emitted on approval
    event Send(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer( address indexed previousMinter, address indexed newMinter);

    // TODO: create mapping for balances
    // TODO: create mapping for allowances
    mapping (address => uint256) public inventoryBalance;

    mapping (address => mapping(address => uint256)) public allowances;
        

    constructor() public {
        // TODO: set sender's balance to total supply
        
        inventoryBalance[msg.sender] = supply;
        minter = msg.sender;
    }


    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        
        return inventoryBalance[_owner]; 
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        
        require (msg.sender == minter);
        require ((amount + supply) < MAXSUPPLY);
        inventoryBalance[receiver] = inventoryBalance[receiver] + amount;
        supply = supply + amount;
        return true;

    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        
        require (amount <= inventoryBalance[msg.sender]);
        inventoryBalance[msg.sender] = inventoryBalance[msg.sender] - amount;
        supply = supply - amount;
        emit Send(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        
        require (msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(minter, newMinter);
        return true;
        
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        
        require(_value <= inventoryBalance[msg.sender]);
        require(inventoryBalance[msg.sender] > 1); // must be greater for fee
        inventoryBalance[msg.sender] = inventoryBalance[msg.sender] - _value;
        inventoryBalance[_to] = inventoryBalance[_to] + _value;
        inventoryBalance[msg.sender] = inventoryBalance[msg.sender] - 1; // fee
        inventoryBalance[minter] = inventoryBalance[minter] + 1; // fee
        emit Send(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee

        require(inventoryBalance[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);
	    inventoryBalance[_from] = inventoryBalance[_from] - _value;
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
	    inventoryBalance[_to] = inventoryBalance[_to] + _value;
        inventoryBalance[msg.sender] = inventoryBalance[msg.sender] - 1; // fee
        inventoryBalance[minter] = inventoryBalance[minter] + 1; // fee
        emit Send(_from, _to, _value);
        return true;
	    
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
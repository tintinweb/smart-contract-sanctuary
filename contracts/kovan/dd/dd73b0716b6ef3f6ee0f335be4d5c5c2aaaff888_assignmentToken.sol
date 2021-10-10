/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 supply = 50000;
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
    mapping (address => uint) public balances;

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
         balances[msg.sender] = supply; // TODO: set sender's balance to total supply
         minter = msg.sender; // So that the original minter is the contract creator
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
        require( supply + amount <= MAXSUPPLY ); // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter); // Only the minter can mint 
        balances[receiver] += amount; // TODO: mint tokens by updating receiver's balance and total supply
        supply+=amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require( balances[msg.sender] >= amount); // NOTE: must have enough balance to burn
        supply -= amount; // reducing supply
        balances[msg.sender] -= amount; // burn the money of the sender
        balances[address(0)] += amount; // TODO: burn tokens by sending tokens to `address(0)`
        emit Transfer(msg.sender, address(0), amount); // Message 
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender == minter); // NOTE: only incumbent minter can transfer mintership
        minter = newMinter;// TODO: transfer mintership to newminter
        emit MintershipTransfer(msg.sender, newMinter);// NOTE: should emit `MintershipTransfer` event
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // The initiator of any transaction can choose to make the transaction output(s) < input(s)
        // NOTE: sender needs to have enough tokens
        require(balances[msg.sender] >= _value ); 
        // NOTE: transfer value needs to be sufficient to cover fee !!!!!!!
        require( _value >= 1);
        // TODO: transfer `_value` tokens from sender to `_to`
	    balances[msg.sender] -= _value;
 	    balances[_to] += _value - 1;
 	    balances[minter] += 1; //flat fee to the minter
        emit Transfer(msg.sender, _to, _value); //emit
        emit Transfer(msg.sender, minter, 1); //emit fee
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require(balances[_from] >= _value );
        require(allowances[_from][msg.sender] >= _value);
        // NOTE: transfer value needs to be sufficient to cover fee
        require( _value >= 1);
        // TODO: transfer `_value` tokens from `_from` to `_to`
    	balances[_from] -= _value ;
        allowances[_from][msg.sender] -= _value;
	    balances[_to] += _value-1;
	    balances[minter] += 1; //flat fee to the minter
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, minter, 1); //emit fee
	return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
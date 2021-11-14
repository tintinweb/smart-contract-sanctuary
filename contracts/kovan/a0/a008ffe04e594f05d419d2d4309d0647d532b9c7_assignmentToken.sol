/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract assignmentToken {
    /// TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
      address public minter;
    constructor() {minter = msg.sender;}
    uint256 constant supply= 1000000;
    uint256 constant MAXSUPPLY = 1000000;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // TODO: create mapping for balances
    mapping (address => uint256) public balances;

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint256)) public allowances;

   // constructor() public {
        // TODO: set sender's balance to total supply
    //balances[msg.sender] = supply;
    //}

    function totalSupply() public pure returns (uint256) {
        // TODO: return total supply
        return supply;    
        }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
    return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        /// TODO: mint tokens by updating receiver's balance and total supply
        /// NOTE: total supply must not exceed `MAXSUPPLY`
        //Makes sure that the person doing the minting is the minter
        require(msg.sender == minter);
        require(amount < MAXSUPPLY);
        balances[receiver] += amount;
        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        /// TODO: burn tokens by sending tokens to `address(0)`
        /// NOTE: must have enough balance to burn
        require(account != address(0), "burn from the zero address");
        require(supply > amount, "burn amount exceeds balance");
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function transferMintership(address previousMinter, address newMinter) public returns (bool) {
        /// TODO: transfer mintership to newminter
        /// NOTE: only incumbent minter can transfer mintership
        /// NOTE: should emit `MintershipTransfer` event
        require(newMinter != address(0));
        emit MintershipTransfer(previousMinter, newMinter);
        previousMinter = newMinter;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        /// NOTE: transfer value needs to be sufficient to cover fee
    require(balances[msg.sender] >= _value, "Insufficient funds");
    require(_value >= 1, "value needs to be able to cover fee");
	balances[msg.sender] -= _value;
 	balances[_to] += _value; // this is for the transaction fee
    emit Transfer(msg.sender, _to, _value);
    return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        /// NOTE: transfer value needs to be sufficient to cover fee
    require(balances[_from] >= _value, "balances too low");
    require(allowances[_from][msg.sender] >= _value, "allowances too low");
    require(_value >= 1, "value needs to be able to cover fee");
	balances[_from] -= _value;
    allowances[_from][msg.sender] -= _value;
	balances[_to] += _value;
    emit Transfer(_from, _to, _value);
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
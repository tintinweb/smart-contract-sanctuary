/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

contract assignmentToken {
      address public minter;
    uint256 supply = 50000;
    uint256 constant MAXSUPPLY = 1000000;
    uint256 constant transactionFee = 1;

    // specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // create mapping for balances
    mapping (address => uint256) public balances;

    // create mapping for allowances
    mapping (address => mapping(address => uint256)) public allowances;

   constructor() public {
        // set contract creator's balance to initial supply
    balances[msg.sender] = supply; minter = msg.sender; //ensures only a minter can mint a token
    }

    function totalSupply() public view returns (uint256) {
        // return total supply
        return supply;    
        }

    function balanceOf(address _owner) public view returns (uint256) {
        // return the balance of _owner
    return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        //Makes sure that the person doing the minting is the minter
        require(msg.sender == minter);
        require(amount +supply <= MAXSUPPLY);
        supply += amount;
        balances[receiver] += amount;
        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        // burn tokens by sending tokens to `address(0)`
        require(account != address(0), "burn from the zero address");
        require(balances[msg.sender] >= amount, "burn amount exceeds balance");
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfer mintership to newminter
        require(newMinter != address(0));
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
    require(balances[msg.sender] > _value + transactionFee, "Insufficient funds");
    require(_value >= transactionFee, "value needs to be able to cover fee");
	balances[msg.sender] -= _value;
 	balances[_to] += _value - transactionFee; // this is for the transaction fee
    balances[minter] += transactionFee;
    emit Transfer(msg.sender, _to, _value);
    emit Transfer(msg.sender, minter, transactionFee);
    return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool) {
        // transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    require(balances[_from] > _value, "balances too low");
    require(allowances[_from][msg.sender] > _value, "allowances too low");
    require(_value >= 1, "value needs to be able to cover fee");
	balances[_from] -= _value;
    allowances[_from][msg.sender] -= _value;
	balances[_to] += _value - transactionFee; // this is for the transaction fee
	balances[minter] += transactionFee;
    emit Transfer(msg.sender, _to, _value);
    emit Transfer(_from, _to, _value);
	return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // allow `_spender` to spend `_value` on sender's behalf
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;    
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
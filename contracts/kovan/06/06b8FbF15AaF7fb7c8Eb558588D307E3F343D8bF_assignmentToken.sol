/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
//Complier version need to be checked

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;  //Total supply of token
    uint256 constant INITSUPPLY = 50000;  //Value of the initial supply
    uint256 constant FEE = 1;  //Value of the transaction fee
    uint256 public supply;  //Dynamic supply
    address public minter;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // TODO: specify event to be emitted on Transfering Mintership
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // TODO: create mapping for balances
    mapping(address => uint) public balances;  //Syntax: mapping(key type => value type), regards as Hash Tables

    // TODO: create mapping for allowances
    mapping(address => mapping(address => uint)) public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;  //1.3 The original minter is the contract creator
        supply = INITSUPPLY;  //3.1 Initial supply at contract creation
        balances[msg.sender] = supply;  //3.1 To be credited to the contract creator's balance
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
        require(msg.sender == minter, "ERROR: Only minter can mint the token!"); //1.2 Ensure identity
        require((amount + supply) <= MAXSUPPLY, "ERROR: New mint can not exceed the MAXSUPPLY!");  //3.2 Ensure capped supply
        supply = amount + supply;  //1.1 Update the total supply
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(amount <= balances[msg.sender], "ERROR: Ensure have enough balance to burn!");
        balances[msg.sender] -= amount;
        supply -= amount;  //2 Also reduce the supply dynamically
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter, "ERROR: Only incumbent minter can transfer the mintership!");
        minter = newMinter;  //1.4 Transfer mintership
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        // Note: Very Important: The _value is the total amount that the sender spends, 
        // Note: whereas _to will receive only _value minus the fee  -ref from Linpeng at Forums
        require(_value >= FEE, "ERROR: Transfer value is not enough to cover the fee!");  //4.2 Ensure to cover the fee  //Test: _value = 1
        require(_value <= balances[msg.sender], "ERROR: Do not have enough balance to transfer!");  //To be tested: Transfer > Supply
        balances[msg.sender] -= _value;
        balances[_to] += _value - FEE;
        balances[minter] += FEE;  //4.1 Transaction fee for the minter
        emit Transfer(msg.sender, _to, _value - FEE);
        emit Transfer(msg.sender, minter, FEE);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value >= FEE, "ERROR: Transfer value is not enough to cover the fee!");  //4.2 Ensure to cover the fee
        require(_value <= balances[_from], "ERROR: Do not have enough balance to transfer!");
        require(allowances[_from][msg.sender] >= _value, "ERROR: Do not have enough allowance to transfer!");
        balances[_from] -= _value;
        balances[_to] += _value - FEE;
        allowances[_from][msg.sender] -= _value;
        balances[minter] += FEE;  //4.1 Transaction fee for the minter
        emit Transfer(_from, _to, _value - FEE);
        emit Transfer(_from, minter, FEE);
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
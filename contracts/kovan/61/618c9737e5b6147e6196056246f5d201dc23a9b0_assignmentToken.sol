/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 public supply = 50000;
    address public minter;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // TODO: create mapping for balances
    mapping(address => uint256) public balances;

    // TODO: create mapping for allowances
    mapping(address => mapping(address => uint256)) public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        balances[msg.sender] = supply;
        minter = msg.sender; // the original minter is the contract creator
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
        require(msg.sender == minter); // Only a minter can mint the token
        require(amount < 1e60);
        require(supply + amount <= MAXSUPPLY); // so it doesn't exceed max supply
        
        balances[receiver] += amount; // updating receiver's balance
        supply += amount;
        
        return true;

    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        
        require(balances[msg.sender] >= amount); // the sender should have enough balance to burn 
        require(amount < 1e60);
        require(supply - amount >= 0); // so that the transaction is feasible

        balances[msg.sender] -= amount; // subtracting from sender
        balances[address(0)] += amount; // sending to address(0)
        supply -= amount; // reducing supply

        emit Transfer(msg.sender,address(0),amount); // emitting transfer to address(0)
        return true;

    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        
        require(msg.sender == minter); // NOTE: only incumbent minter can transfer mintership
        
        minter = newMinter;

        emit MintershipTransfer(msg.sender, newMinter);// NOTE: should emit `MintershipTransfer` event

        return true;


    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        
        require(balances[msg.sender] >= _value + 1);  // NOTE: sender needs to have enough tokens + fees
        require(_value < 1e60);
        require(_value>=1); // transaction should be able to cover the trasanction fee to succeed

        balances[msg.sender] -= (_value + 1); // value + transfer
        balances[_to] += _value;
        balances[minter] += 1; // minter get 1 

        emit Transfer(msg.sender, _to, _value); // transfer for both
        emit Transfer(msg.sender, minter, 1);
        return true;


    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee

        
        require(_value>=1);
        require(balances[_from] >= (_value + 1));
        require(_value < 1e60);
        require(allowances[_from][msg.sender] >=(_value + 1)); // if allowance is enough

        balances[_from] -= (_value + 1);
        balances[_to] += _value;
        balances[minter] += 1;

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, minter, 1);
        allowances[_from][msg.sender] -= (_value + 1); // updating allowance
        return true;

    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten

        allowances[msg.sender][_spender] = _value; //specify how much is allowed 

        emit Approval(msg.sender,_spender,_value);
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
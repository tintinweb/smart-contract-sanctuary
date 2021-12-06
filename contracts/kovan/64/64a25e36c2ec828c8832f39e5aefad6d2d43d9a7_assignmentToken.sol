/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant supply = 50000;
    uint256 constant MAXSUPPLY = 1000000;
    uint _totalsupply;
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
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        _totalsupply += supply;
        balances[msg.sender] = supply;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return _totalsupply; 
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require (msg.sender == minter, "Only the Minter can mint tokens");
        require (_totalsupply+amount <= MAXSUPPLY) ;
        _totalsupply += amount;
        balances[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require (msg.sender == minter, "Only the Minter can burn tokens");
        require (amount <= _totalsupply);
        balances[msg.sender] -= amount ; 
        _totalsupply -= amount; //NOT SURE THOUGH, COMPREHENSION ISSUE, NEED TO CHECK IT OUT
        balances[address(0)] += amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter OK
        // NOTE: only incumbent minter can transfer mintership OK
        // NOTE: should emit `MintershipTransfer` event OK
        require (msg.sender == minter, "Only the Minter can transfer the mintership");
        minter = newMinter ;
        emit MintershipTransfer (msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require (_value <= balances[msg.sender],"Sorry mate, insufficient balance");
        balances[msg.sender] -= _value;
        balances[minter] += 1;
        balances[_to] += _value-1;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require (_value  <= balances[_from], "You are too poor bro");
        require (_value  <= allowances[_from][msg.sender], "Insufficient allowance");
        balances[_from] -= _value;
        balances[minter] += 1;
        balances[_to] += _value -1;
        emit Transfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
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
        return allowances[_owner][_spender];
    }
}
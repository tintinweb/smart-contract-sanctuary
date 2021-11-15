/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    address public minter;
    uint256 constant maxSupply = 1000000; // To set the maximum supply
    uint256 supply = 50000; // To set initial supply 
    uint256 constant txFee = 1; // 1 unit flat fee for token transfer
    
    constructor() {
        minter = msg.sender; // To set original minter = the contract creator
        balances[msg.sender] = supply; // To set sender's balance to total supply
    }  

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
    mapping(address => mapping(address => uint)) public allowances;

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
        require(msg.sender == minter);
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(amount < maxSupply);
        require((supply + amount) < maxSupply);
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        require(msg.sender != address(0));
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        supply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        require(msg.sender == minter);
        minter = newMinter;
        // NOTE: should emit `MintershipTransfer` event
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        
        // NOTE: sender needs to have enough tokens
        // TODO: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender]);    
        require(txFee <= _value);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - txFee);
        balances[minter] += txFee;
        emit Transfer(msg.sender, _to, (_value - txFee));
        emit Transfer(msg.sender, minter, txFee);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // TODO: transfer value needs to be sufficient to cover fee
        require(_value <= balances[_from]);
        require(txFee <= _value);
        require(allowances[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += (_value - txFee);
        balances[minter] += txFee;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, (_value - txFee));
        emit Transfer(_from, minter, txFee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
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
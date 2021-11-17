/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    uint256 constant MAXSUPPLY = 1000000; // the maximum supply of tokens
    uint256 supply;
    
    // amount levied to the minter after each transfer
    uint256 constant transactionFee = 1; 
    address public minter;

    // event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // event to be emitted on mintership transfer
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // mapping for balances
    mapping (address => uint) public balances;

    // mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        // on contract creation, sets current supply to 50000 
        // then adds it to creator of the contract's balance
        // also assigns the contract creator the role of the minter
        supply = 50000;
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // returns total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // returns the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // mints tokens by updating receiver's balance and total supply
        // total supply cannot not exceed `MAXSUPPLY`
        require(msg.sender == minter, "only incumbent minter can mint");
        require(amount + supply <= MAXSUPPLY, "current supply exceeds MAXSUPPLY");
        supply += amount;
        balances[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // burns tokens by sending tokens to `address(0)`, essentially a "black hole"
        // burner must have enough balance to burn
        require(balances[msg.sender] >= amount, "balance too low to burn");
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfers mintership to new address
        // only the current minter can transfer mintership
        // emits `MintershipTransfer` event
        require(msg.sender == minter, "only incumbent minter can transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfers `_value` tokens from sender to `_to`
        // sender must have enough tokens
        // transfer value also needs to be sufficient to cover the transaction fee
        require(_value >= transactionFee, "value cannot cover transaction fee");
        require(balances[msg.sender] >= _value, "balance too low");
    	balances[msg.sender] -= _value;
     	balances[_to] += _value - transactionFee;
        emit Transfer(msg.sender, _to, _value - transactionFee);
        
        balances[minter] += transactionFee;
        emit Transfer(msg.sender, minter, transactionFee);
        return true;
    }

    function transferFrom( address _from, 
    address _to, 
    uint256 _value) public returns (bool) {
        // transfers `_value` tokens from `_from` to `_to`, 
        // i.e. transfers on someone else's behalf
        // `_from` needs to have enough tokens  
        // also to have allowed sender to spend on their behalf
        // transfer value also needs to be sufficient to cover the transaction fee
        require(_value >= transactionFee);
        require(balances[_from] >= _value, "balances too low");
        require(allowances[_from][msg.sender] >= _value, "allowances too low");
    	balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
    	balances[_to] += _value - transactionFee;
        emit Transfer(_from, _to, _value - transactionFee);
        
        balances[minter] += transactionFee;
        emit Transfer(msg.sender, minter, transactionFee);
    	return true; 
    }

    function approve(address _spender, 
    uint256 _value) public returns (bool) {
        // allows `_spender` to spend `_value` on sender's behalf
        // if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, 
    address _spender) public view returns (uint256 remaining){
        // returns allowance of '_spender' to spend on '_owner''s behalf
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
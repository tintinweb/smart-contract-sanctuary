/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract assignmentToken {
    
    //specify `MAXSUPPLY`, declare `supply` and `minter`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 constant supply = 50000;
    address public minter;
    
    //integer that will keep track of supplied, freshly minted or burned tokens
    uint total_supply;
    

    //specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //events emitted when there is change in total supply
    event Mint(address indexed _receiver,uint256 _value);
    event Burn(uint256 _value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    //create mapping for balances
    mapping(address => uint) public balances;

    //create mapping for allowances
    mapping(address => mapping(address => uint)) public allowances;

    constructor() {
        //set sender's balance to total supply
        minter=msg.sender;
        balances[msg.sender]=supply;
        total_supply=supply;
    }

    function totalSupply() public view returns (uint256) {
        //return total supply
        return total_supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        //return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        //mint tokens by updating receiver's balance and total supply
        //total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter);
        require(MAXSUPPLY >= totalSupply()+amount);
        balances[receiver] += amount;
        total_supply += amount;
        emit Mint(receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        //burn tokens by sending tokens to `address(0)`
        //must have enough balance to burn
        require(msg.sender == minter);
        require(totalSupply() >= amount);
        balances[msg.sender] -= amount;
        balances[address(0)] += amount;
        total_supply -= amount;
        emit Burn(amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        //transfer mintership to newminter
        //only incumbent minter can transfer mintership
        //should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        //transfer `_value` tokens from sender to `_to`
        //sender needs to have enough tokens
        //transfer value needs to be sufficient to cover fee
        require(_value+1 <= balances[msg.sender], "Insufficient Balance");
        balances[_to] += _value;
        balances[msg.sender] -= (_value+1);
        balances[minter] += 1;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        //transfer `_value` tokens from `_from` to `_to`
        //`_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        //transfer value needs to be sufficient to cover fee
        require(_value+1 <= balances[_from], "Insufficient Balance");
        require(allowances[_from][msg.sender] >= _value+1);
        balances[_from] -= (_value+1);
        balances[_to] += _value;
        balances[minter] += 1;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        //allow `_spender` to spend `_value` on sender's behalf
        //if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        //return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
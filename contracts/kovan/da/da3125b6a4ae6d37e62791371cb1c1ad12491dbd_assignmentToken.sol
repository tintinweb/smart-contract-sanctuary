/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`

    address public minter; // not sure
    uint256 supply = 50000;
    uint256 constant MAXSUPPLY = 1000000;

    // done : TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // done : TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );


    //done : TODO: create mapping for balances 
    mapping (address => uint) public balances;

    // done : TODO: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;


    constructor() {
        // done : TODO: set sender's balance to total supply
        minter = msg.sender;
        balances[msg.sender] += supply;
    }

    function totalSupply() public view returns (uint256) {
        // done : TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // done : TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // done : TODO: mint tokens by updating receiver's balance and total supply
        // done : NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter);
        require((supply + amount) <= MAXSUPPLY);
        balances[receiver] += amount;
        supply += amount;
        return true;

    }

    function burn(uint256 amount) public returns (bool) {
        // done : TODO: burn tokens by sending tokens to `address(0)`
        // done : NOTE: must have enough balance to burn
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[address(0)] += amount;
        supply -= amount;
        emit Transfer(msg.sender,address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // done : TODO: transfer mintership to newminter
        // done : NOTE: only incumbent minter can transfer mintership
        // done : NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // done : TODO: transfer `_value` tokens from sender to `_to`
        // done : NOTE: sender needs to have enough tokens
        // done : NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender]);
        require(_value >= 1);
        balances[_to] += _value-1; // 1 coin is transferred to the minter
        balances[msg.sender] -= _value;
        balances[minter] += 1;
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, minter, 1);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // done : TODO: transfer `_value` tokens from `_from` to `_to`
        // done :  NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // done : NOTE: transfer value needs to be sufficient to cover fee
        require(balances[_from]>= _value);
        require(allowances[_from][msg.sender]>= _value);
        require(_value >= 1);
        balances[_from] -= _value;
        balances[_to] += _value -1;
        balances[minter] += 1;
        emit Transfer(_from, _to, _value);
        emit Transfer(msg.sender, minter, 1);
        return true;   
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // done : TODO: allow `_spender` to spend `_value` on sender's behalf
        // done : NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value); // Transfer or Approval
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        // done : TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
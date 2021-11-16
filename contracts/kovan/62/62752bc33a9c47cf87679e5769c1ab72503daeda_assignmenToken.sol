/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmenToken {
   // specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 supply = 50000;
    address public minter;

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);
    
    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount); // must have enough balance to burn
        supply -= amount;
        balances[msg.sender] -= amount;
        transfer(address(0), amount); // burn tokens by sending tokens to `address(0)`
        emit Transfer(msg.sender, address(0), amount);
        return true;}

    function transferMintership(address previousMinter, address newMinter) public returns (bool) {
        require(previousMinter == minter); // only incumbent minter can transfer mintership
        newMinter == minter; // transfer mintership to newminter
        emit MintershipTransfer(previousMinter,newMinter); // NOTE: should emit `MintershipTransfer` event
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require((_value + 1) <= balances[msg.sender]); // NOTE: sender needs to have enough tokens
        balances[_to] += _value; // transfer `_value` tokens from sender to `_to`
        balances[msg.sender] -= (_value + 1); // NOTE: transfer value needs to be sufficient to cover fee
        balances[minter] += balances[minter] + 1;
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, minter, 1);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) 
        public returns (bool) {
        require(_value +1 <= (balances[_from])); // transfer value needs to be sufficient to cover fee
        require(allowances[msg.sender][_from] >= (_value + 1)); // `_from` needs to have enough tokens 
        //and to have allowed sender to spend on his behalf
        balances[_from] -= (_value -1);
        balances[_to] += _value; // transfer `_value` tokens from `_from` to `_to` 
        allowances[_from][msg.sender] -= _value;
        balances[minter] += 1;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, minter, 1);
        return true;
    }
    
    // specify event to be emitted on transfer 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // create mapping for balances
    mapping(address => uint256) public balances;
    
    // create mapping for allowances
    mapping(address => mapping(address => uint)) public allowances;
    
    // TODO: return the balance of _owner 
    function balanceOf(address _owner) public view returns (uint256) {return balances[_owner];}

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
        {remaining = allowances[_owner][_spender]; 
        require(remaining <= balances[_owner]);
        return remaining;} // return how much `_spender` is allowed to spend on behalf of `_owner` 
    
    // NOTE: if an allowance already exists, it should be overwritten
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value; // allow `_spender` to spend `_value` on sender's behalf 
        require(balances[msg.sender] >= _value);
        emit Approval(msg.sender, _spender, _value); return true;}
        
    constructor(){balances[msg.sender] = supply; msg.sender == minter;} // sender's balance = total supply, sender is minter
    
    function totalSupply() public view returns (uint256) {return supply;} //return total supply
   
    // mint tokens by updating receiver's balance and total supply
    function mint(address receiver, uint256 amount) public returns (bool) {
    require((amount + supply) <= MAXSUPPLY); // total supply must not exceed `MAXSUPPLY` 
    balances[receiver] += amount;
    supply += amount;
    emit Transfer(minter, receiver, amount);
    return true;
    }
}
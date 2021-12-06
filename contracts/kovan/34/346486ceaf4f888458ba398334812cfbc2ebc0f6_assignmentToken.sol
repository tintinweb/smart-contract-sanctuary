/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract assignmentToken {
 // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
 uint256 MAXSUPPLY = 1000000;
 uint256 supply = 50000;
 address public minter;
 // TODO: specify event to be emitted on transfer
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 // TODO: specify event to be emitted on approval
 event Approval(address indexed _from, address indexed _to, uint256 _value);
 event MintershipTransfer(
 address indexed previousMinter,
 address indexed newMinter
 );
 // TODO: create mapping for balances
 mapping (address => uint) public balances;
 // TODO: create mapping for allowances
 mapping (address => mapping (address => uint)) public allowances;
 constructor() {
 // TODO: set sender's balance to total supply'
 minter = msg.sender;
 balances[msg.sender] = supply;
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

 require (msg.sender == minter,"User doesn't have minter ownership to mint");
 require (supply+amount <= MAXSUPPLY,"Value is more than MAXSUPPLY Limit");
 balances[receiver] += amount;
 supply +=amount;
 return true;
 }
 // NOTE: total supply must not exceed `MAXSUPPLY`
 function burn(uint256 amount) public returns (bool) {
 // TODO: burn tokens by sending tokens to `address(0)`

 require (msg.sender == minter,"User doesn't have minter ownership to mint");
 require (balances[minter] >= amount,"Not enough balances available for burn");
 balances[minter] -= amount;
 balances[address(0)]+=amount;
 //balances[address(0)]
 supply -=amount;
 return true;
 }
 // NOTE: must have enough balance to burn
 function transferMintership(address newMinter) public returns (bool) {
 // TODO: transfer mintership to newminter
 require (msg.sender == minter,"User doesn't have minter ownership to mint");
 address previousMinter = minter;
 minter = newMinter;
 emit MintershipTransfer(previousMinter,newMinter);
 return true;
 }
 // NOTE: only incumbent minter can transfer mintership
 // NOTE: should emit `MintershipTransfer` event
 function transfer(address _to, uint256 _value) public returns (bool) {
 // TODO: transfer `_value` tokens from sender to `_to`
 require(balances[msg.sender] >= _value+1,"balances too low for transaction (transaction fee is 1 coin)");
 balances[msg.sender] -= _value+1;
 balances[_to] += _value;
 balances[minter]+=1;
 emit Transfer(msg.sender, _to, _value);
 return true;
 }
 // NOTE: sender needs to have enough tokens
 // NOTE: transfer value needs to be sufficient to cover fee
 function transferFrom(
 address _from,

 address _to,
 uint256 _value
 ) public returns (bool) {
 // TODO: transfer `_value` tokens from `_from` to `_to`
 require(balances[_from] >= _value+1, "balances too low for transaction (transaction fee is 1 coin)");
 require(allowances[_from][msg.sender] >= _value, "allowances too low");
 balances[_from] -= _value+1;
 allowances[_from][msg.sender] -= _value+1;
 balances[_to] += _value;
 balances[minter]+=1;
 emit Transfer(_from, _to, _value);
 return true;
 }
 // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
 // NOTE: transfer value needs to be sufficient to cover fee
 function approve(address _spender, uint256 _value) public returns (bool) {
 // TODO: allow `_spender` to spend `_value` on sender's behalf
 allowances[msg.sender][_spender] = _value;
 emit Approval(msg.sender, _spender, _value);
 return true;
 }
 // NOTE: if an allowance already exists, it should be overwritten
 function allowance(address _owner, address _spender)
 public
 view
 returns (uint256 remaining)
 {
 // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
 remaining = allowances[_owner][_spender];
 return remaining;
 }
}
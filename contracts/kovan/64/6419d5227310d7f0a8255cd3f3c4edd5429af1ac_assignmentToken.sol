/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 MAXSUPPLY = 1000000;
    uint256 totalsupply = 50000; // This is totalsupply at the beginning equal to initial supply
    address public Minter;

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
    mapping ( 
      address => mapping(address => uint)
      ) public allowances;
    
    constructor() {
        // TODO: set sender's balance to total supply
        Minter = msg.sender;  // Minter's address
        balances[msg.sender] = totalsupply;}

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return totalsupply;}

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];}

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require (msg.sender == Minter); // Only Minter has the right to mint coins
        totalsupply += amount;          // Add amount of tokens to totalsupply first to check
                                        // whether it will exceed MAXSUPPLY after mint tokens.
        require (totalsupply <= MAXSUPPLY); 
        balances[receiver] += amount;
        return true;}

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require (balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[address(0)] += amount;
        totalsupply -= amount; // The amount of tokens needs to be subtracted in totalsupply
        return true;}

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require (msg.sender == Minter); //Only current Minter has the right to tranfer mintership
        Minter = newMinter;
        emit MintershipTransfer( Minter, newMinter );
        return true;}

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
         require( _value <= balances[msg.sender]);
         require( _value >= 1);          // Make sure tranfer value covering transaction fee(1 unit)
         balances[msg.sender] -= _value; // Sender sends _value amount of tokens
         balances[_to] += _value-1;      // But the receiver will only get _value-1 tokens
         balances[Minter] += 1;          // The missing 1 token is paid as transaction fee to Minter
         emit Transfer(msg.sender, _to, _value);
         return true;}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
         require(_value <= balances[_from]);
         require(_value >= 1);
         require(allowances[_from][msg.sender] >= _value);
         balances[_from] -= _value;     // Same as the condition in transfer function,
         balances[_to] += _value-1;     // also need to consider the trasaction fee(1 unit) here
         balances[Minter] += 1;
         allowances[_from][msg.sender] -= _value;
         emit Transfer(_from, _to, _value);
         return true;}

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
         allowances[msg.sender][_spender]=_value;
         emit Approval(msg.sender, _spender, _value);
         return true;}

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
         return allowances[_owner][_spender];}
}
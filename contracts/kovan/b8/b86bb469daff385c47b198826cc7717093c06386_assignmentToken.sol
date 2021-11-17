/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
        uint256 constant MAXSUPPLY = 1000000;
        //The MAXSUPPLY of the token is set to constant with value 1000000 
        address public minter;
        //decalare the minter's data type to addre and make sure all contract have access to its value
        uint256 supply = 50000;
        //Declare the initial supply to 50000 
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
        //balances is a public variable 

    // TODO: create mapping for allowances
        mapping(
            address => mapping(address => uint)
            ) public allowances;
        //allowances is also a public variable 
            
    constructor() {
        //TODO: set sender's balance to total supply
        minter=msg.sender;
        //initial the minter to contract creator 
        balances[msg.sender]=supply;
        //initial the balance of contract creator to supply(50000)
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
            return balances[_owner];}

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
            require(msg.sender == minter);
            require (supply+amount <= MAXSUPPLY);
            balances[receiver] += amount;
            supply += amount;
            return true;}

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
            require (amount <= balances[msg.sender]);
            balances[msg.sender] -= amount;
            supply -= amount;
            emit Transfer(msg.sender, address(0), amount);
            return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
            require(msg.sender == minter);
            //Only the sender is the minter the function can be 
            minter=newMinter;
            emit MintershipTransfer (minter, newMinter);
            return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
            require(_value <= balances[msg.sender] && _value>1);
            //Make sure there is sufficient balance to transfer 
            balances[_to] += _value-1;
            //The balance of _to should increase (value - 1) as there is 1 unit fee
            balances[msg.sender] -= _value;
            //The balnce of  sender should decrease value
            balances[minter] += 1;
            //Pay the flat  fee to minter 
            emit Transfer (msg.sender,minter,1);
            //emit the Transfer event with minter
            emit Transfer (msg.sender, _to, _value-1);
            //emit the Transfer event with _to
            return true;}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
            require(_value <= balances[_from] && _value>1);
            //Make sure there is sufficient balance of _from to transfer 
            require(allowances[_from][msg.sender] >= _value);
            //Make sure there is sufficient allowances for _spender to represent _from to Pay 
            balances[_from] -=  _value;
            //The balnce of _from should decrease value
            balances[_to] += _value-1;
            //The balance of _to should increase (value - 1) as there is 1 unit fee
            balances[minter] += 1;
            //Pay the flat  fee to minter 
            allowances[_from][msg.sender] -= _value;
            //The allowances should also decrese _value
            emit Transfer (msg.sender,minter,1);
            //emit the Transfer event with minter
            emit Transfer (_from, _to, _value-1);
            //emit the Transfer event with _to
            return true;}

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
             allowances[msg.sender][_spender]= _value;
             //set the allowances of the sender to values 
             emit Approval(msg.sender, _spender, _value);
             //emit the Approval event
            return true;}

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
            return allowances[_owner][_spender];}
}
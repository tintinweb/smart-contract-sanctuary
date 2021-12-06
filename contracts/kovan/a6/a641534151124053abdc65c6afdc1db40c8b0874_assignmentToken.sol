/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    address public minter;
    uint256 supply = 50000;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // TODO: create mapping for balances
    mapping (address => uint) public balances;

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() public {
        // TODO: set sender's balance to total supply
        balances[msg.sender] = supply;
        minter = msg.sender;
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
            require(minter == msg.sender, "Not the minter,only the minter can mint the token");//Only a minter can mint the token
            require(supply + amount <= MAXSUPPLY, "Total supply exceed the max supply"); //total supply must not exceed `MAXSUPPLY`
            balances[receiver] += amount;
            supply += amount;//add the mint tokens to the total supply
            return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender]>=amount, "Not sufficient balance");
        balances[address(0)]+=amount;
        balances[msg.sender]-=amount;
        supply -= amount; //substract the burn tokens from the total supply
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter, "Only incumbent minter can transfer mintership and you are not the incumbent minter");
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value<=balances[msg.sender],"Not sufficient balance");
        require(1 <= _value,"Value is not sufficient to cover transfer fees");
        balances[msg.sender] -= _value ; // Subtract from the sender
        balances[_to] += (_value -1); // Add the same to the recipient, flat fee paiement
        balances[minter] += 1; // Reward the minter with the flat fee
        emit Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
        return true; //Say it's ok, like handshake
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value<=balances[_from],"Not sufficient balance");
        require(1 <= _value,"Value is not sufficient to cover transfer fees");
        require(allowances[_from][msg.sender]>=_value,"Insufficient allowances");
        balances[_from]-=_value;// Subtract from the sender
        balances[_to]+=(_value -1);// Add the same to the recipient, flat fee paiement
        balances[minter]+= 1;// Reward the minter with the flat fee
        emit Transfer(_from,_to,_value);
        allowances[_from][msg.sender]-=_value;
        return true; //Say it's ok, like handshake
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value; // allow `_spender` to spend `_value`
        emit Approval(msg.sender, _spender, _value);
        return true;//Say it's ok, like handshake
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
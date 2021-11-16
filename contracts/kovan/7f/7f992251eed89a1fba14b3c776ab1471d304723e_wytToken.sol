/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract wytToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 MAXSUPPLY = 1000000;
    address minter;
    uint256 supply;
    uint256 fee;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances
    mapping (address => uint256) public balance;

    // TODO: create mapping for allowances
    mapping (address => mapping (address => uint256)) public allowanceOf;

    constructor() {
        // TODO: set sender's balance to total supply
        supply = 50000;
        minter = msg.sender;
        balance[msg.sender] = 50000;
        fee = 1;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balance[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(receiver == minter);
        require(supply + amount <= MAXSUPPLY);
        balance[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balance[msg.sender] >= amount);   // Check if the sender has enough
        balance[msg.sender] -= amount;            // Subtract from the sender
        supply -= amount;                      // Updates totalSupply
        balance[address(0)] += amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(minter  == msg.sender);
        minter = newMinter;
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(balance[_from] >= _value);
        require(balance[_to] + _value > balance[_to]);
        require(_value > fee);
        balance[minter] += fee;
        // Subtract from the sender
        balance[_from] -= _value;
        // Add the same to the recipient
        uint rest_value = _value - fee;
        balance[_to] += rest_value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= allowanceOf[_from][msg.sender]);     // Check allowance
        allowanceOf[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowanceOf[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowanceOf[_owner][_spender];
    }
}
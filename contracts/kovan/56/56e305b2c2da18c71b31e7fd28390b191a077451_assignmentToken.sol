/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant maxsupply = 1000000;
    uint256 constant supply = 50000;
    address public minter = msg.sender;
    

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

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() public {
        // TODO: set sender's balance to total supply
        balances[msg.sender] = supply;
    }

    function totalSupply() public pure returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        require (msg.sender == minter, "Not the minter");
        balances[receiver] += amount;
        balances[msg.sender] += amount;
        require (balances[msg.sender] <= maxsupply, "Exceed Maximum");
        return true;

        // NOTE: total supply must not exceed `MAXSUPPLY`
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        require (balances[msg.sender] >= amount, "Not sufficient balance to burn");
        balances[address(0)] += amount;
        balances[msg.sender] -= amount;
        return true;
        // NOTE: must have enough balance to burn
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        require (minter == msg.sender, "Not incumbent minter");
        newMinter = minter;
        emit MintershipTransfer(minter, newMinter);
        return true;
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        require (_value <= balances[msg.sender], "Not sufficient tokens");
        require (_value > 1, "Can not cover transfer fee");
        balances[msg.sender] -= _value;
        balances[msg.sender] += 1;
        balances[_to] += _value-1;
        return true;
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        require(_value <= balances[_from], "Not sufficient tokens");
        require(allowances[_from][msg.sender] >= _value, "insufficient allowances");
        require (_value > 1, "Can not cover transfer fee");
        balances[_from] -= _value;
        balances[_to] += _value-1;
        balances[msg.sender] += 1; //transfer fee awarded
        emit Transfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        return true;
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        // NOTE: if an allowance already exists, it should be overwritten
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
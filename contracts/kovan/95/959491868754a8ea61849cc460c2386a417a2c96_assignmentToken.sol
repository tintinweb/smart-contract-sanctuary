/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract assignmentToken {
    uint256 constant MAXSUPPLY = 1000000;
    address private minter;
    uint256 private totalsupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    constructor() public {
    minter = msg.sender;
    totalsupply = 50000;
    balances[minter] = totalsupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        require(totalsupply + amount <= MAXSUPPLY);

        totalsupply += amount;
        balances[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        totalsupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value > 1);
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value - 1;
        balances[minter] += 1;

        emit Transfer(msg.sender, _to, _value - 1);
        emit Transfer(msg.sender, minter, 1);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value > 1);
        require(balances[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value - 1;
        balances[minter] += 1;

        approve(_from, msg.sender, allowances[_from][msg.sender] - _value);

        emit Transfer(_from, _to, _value - 1);
        emit Transfer(_from, minter, 1);
        return true;
    }

    function approve(address _owner, address _spender, uint256 _value) public returns (bool) {
        allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
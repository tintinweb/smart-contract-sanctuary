/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SafeRune {
    string public name = 'Safe Rune';
    uint8 public decimals = 18;
    string public symbol = 'SafeRune';
    string public version = '1.0';
    uint256 public totalSupply = 0;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    Erc20Rune erc20RuneContract = Erc20Rune(0x3155BA85D5F96b2d030a4966AF206230e46849cb);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function approve(address _spender, uint256 _value ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function RedeemErc20Rune(uint256 amount) public {
        if(!erc20RuneContract.transfer(msg.sender, amount)) revert();
        balances[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function MintSafeRune(uint256 amount) public {
        // transferTo always returns true so theres no reason to check the return value. Reverts on fail
        erc20RuneContract.transferTo(address(this), amount);
        balances[msg.sender] += amount;
        totalSupply += amount;
    }
}

interface Erc20Rune {
  function transferTo(address recipient, uint256 amount) external returns (bool);
  function transfer(address _to, uint256 _value) external returns (bool success);
}
//SPDX-License-Identifier: MIT

/*
Stolen from https://github.com/ConsenSys/Tokens/tree/master/contracts/eip20

The first stablecoin pegged to the Zimbabwe Dollar

Not tested, because who cares?
*/


pragma solidity ^0.4.21;

import "./EIP20Interface.sol";


contract ZimbabweDollarCoin is EIP20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    struct balData {
        uint248 balance;
        bool used;
    }

    mapping (address => balData) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public constant name = "ZimbabweDollarCoin";
    uint8 public constant decimals = 6;
    string public constant symbol = "ZWDC";

    constructor() public {
        totalSupply = 1461501637330902918203684832716283019655932542976000000;//# of addresses x 1000000
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= _value);
        balances[msg.sender].balance = ((uint248)(senderBalance - _value));
        balances[msg.sender].used = true;
        balances[_to].balance = ((uint248)(balanceOf(_to) + _value));
        balances[_to].used = true;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        uint256 fromBalance = balanceOf(_from);
        require(fromBalance >= _value && allowance >= _value);
        balances[_to].balance = ((uint248)(balanceOf(_to) + _value));
        balances[_to].used = true;
        balances[_from].balance = ((uint248)(fromBalance - _value));
        balances[_from].used = true;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ((uint256)(balances[_owner].used ? balances[_owner].balance : 1000000));
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
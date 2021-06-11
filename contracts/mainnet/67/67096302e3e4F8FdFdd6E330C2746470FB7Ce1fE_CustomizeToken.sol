// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StandardToken.sol";
import "./SafeMath.sol";

contract CustomizeToken is StandardToken {

    using SafeMath for uint256 ;
      
    string public name  ;
    string public symbol;
    uint8 public decimals = 18;
    address owner;

    // 事件，用来通知客户端代币被消耗
    event Burn(address indexed from, uint256 value);


    constructor (uint256 initialSupply_, string memory name_, string memory symbol_) public {
        totalSupply_ = initialSupply_ * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
        name = name_;
        symbol = symbol_;
        owner = msg.sender;
    }


    function burn(uint256 _value) public returns (bool) {
        assert(owner == msg.sender);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}
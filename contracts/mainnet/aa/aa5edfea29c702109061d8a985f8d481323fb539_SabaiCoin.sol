/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract SabaiCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balanceOf[0x820BB2b4973b41bf56342d4D9cf9D13412a93dFB] = 3000000;
        totalSupply = 3000000;
        name = "Sabai";
        symbol = "SAB";
        decimals = 3;
        owner = 0x820BB2b4973b41bf56342d4D9cf9D13412a93dFB;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value >= 0, "Cannot send negative amount");
        require(balanceOf[msg.sender] > _value, "The balance is not sufficient");
        require(balanceOf[_to] + _value > balanceOf[_to], "Overflow attack");
        require(balanceOf[msg.sender] - _value < balanceOf[msg.sender], "Overflow attack");
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value >= 0, "Cannot send negative amount");
        require(balanceOf[_from] > _value, "The balance is not sufficient");
        require(balanceOf[_to] + _value > balanceOf[_to], "Overflow attack");
        require(_value < allowance[_from][msg.sender], "The allowance is not sufficient");
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value >= 0, "Cannot send negative amount");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}
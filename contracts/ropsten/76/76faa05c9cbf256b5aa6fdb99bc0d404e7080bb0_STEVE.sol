/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.5.16;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >= 0);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract STEVE is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address payable public owner; 
    
    mapping(address => uint256) balanceOf;
    mapping(address => uint256) freezeOf;
    mapping(address => mapping(address => uint256)) allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    constructor() public {
        decimals = 18;
        balanceOf[msg.sender] = 1 * 10 ** 18;
        totalSupply = 1 * 10 ** 18;
        name = 'STEVE';
        symbol = 'STEVE';
        owner = msg.sender;
    }
    
    
    function transfer(address _to, uint256 _value) public returns(bool success) {
        assert(_to != address(0x0));
        assert(_value > 0);
        assert(balanceOf[msg.sender] >= _value);
        assert(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool success) {
        assert(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function burn(uint256 _value) public returns(bool success){
        assert(balanceOf[msg.sender] >= _value);
        assert(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function freeze(uint256 _value) public returns(bool success) {
        assert(balanceOf[msg.sender] >= _value);
        assert(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) public returns (bool success) {
        assert(balanceOf[msg.sender] >= _value);
        assert(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    // transfer balance to owner
    function withdrawEther(uint256 amount) payable public {
        assert(msg.sender == owner);
        owner.transfer(amount);
    }
    
    // can access ether
    function() external payable {}
}
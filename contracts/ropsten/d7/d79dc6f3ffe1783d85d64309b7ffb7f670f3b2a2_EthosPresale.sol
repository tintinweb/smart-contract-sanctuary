/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.21;

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    }

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner {require(msg.sender == owner);_;}
}

contract ERC20Token is ERC20Interface, Ownable {

    mapping (address => uint256) public balances;
  
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }
}

contract EthosPresale is ERC20Token {

    uint public rate = 100;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 50 ether; //Maximum purchase
    
    bool public open;
    bool public closed;
    
    event Purchase(address indexed purchaser, uint256 amount);
    event ChangeRate(uint256 _value);
  
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }

    function () public payable {
        
        uint tokens; tokens = msg.value * rate;
        require(now >= startDate || (msg.sender == owner));
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        require(!closed);
        balances[msg.sender] += tokens;
        balances[address(this)] -= tokens;
        totalSupply += tokens;
        emit Transfer(address(this), msg.sender, tokens);
        emit Purchase(msg.sender, tokens);
        owner.transfer(msg.value);
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate; emit ChangeRate(rate);
    }
  
    function withdraw(uint _value) public onlyOwner {
        balances[msg.sender] += _value;
        emit Transfer(address(this), msg.sender, _value);
    }
}
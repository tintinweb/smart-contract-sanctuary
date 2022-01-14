/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

//This is dummy version of CryptoBerry
//Telegram: https://t.me/cryptoberrycommunity
//Web: https://thecryptoberry.com/
//main contract is deployed on address 0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
//BSC: https://bscscan.com/token/0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
/**
*
FIRST EVER TOKEN IN HISTORY to have Dynamic sell tax and Greylisting
GREYLISTING: After your latest buy or sell, tokens cannot be sold within 24 hours(in main contract) and ONLY 5 minutes in lite contarct(connect telegram for this address). 
DYNAMIC TAX: sell tax varies from 10% to 5% (more you HOLD then less tax you pay)
Buy Tax 10%(half to marketing and half to liquidity)

2% Max wallet.
Locked Liquidity
1 Trillion supply
0% transfer Tax while transfer to any normal account 
Buy CryptoBerry the Next future gem.
Follow CryptoBerry
BSC: https://bscscan.com/token/0xd2977a2a148df7f2c881c6eAb8E61fa2E859F5B0
Web: https://thecryptoberry.com/
twitter: https://twitter.com/MyCryptoBerry
Telegram: https://t.me/cryptoberrycommunity
Facebook: https://www.facebook.com/cryptoberrycommunity
Instagram: https://www.instagram.com/mycryptoberry/
*
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract CryptoBerry is StandardToken {
    string public name;
    string public symbol;
    uint public decimals;
    address public owner;
	
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address tokenOwner) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }
    
}
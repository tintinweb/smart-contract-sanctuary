pragma solidity ^ 0.4.25;

/*
 Copyright 2018 IDMCOSAS

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

/* 
The MIT License (MIT)

Copyright (c) 2018 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// ----------------------------------------------------------------------------
// &#39;MCS&#39; token contract
//
// Сreator : 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d
// Symbol      : MCS
// Name        : IDMCOSAS
// Total supply: 100000000
// Decimals    : 18
//
//
// (c) by Maxim Yurkov with IDMCOSAS / IDMCOSAS Ltd Au 2017. The MIT Licence.
// ----------------------------------------------------------------------------

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

constructor() public {owner = msg.sender;}


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
 }
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
/*@title SafeMath
 * @dev Math operations with safety checks that revert on error*/

 library SafeMath {

  /*@dev Multiplies two numbers, reverts on overflow.*/

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.

    if (a == 0) {return 0;}

    uint256 c = a * b;
    require(c / a == b);
    return c;}

  /*@dev Integer division of two numbers truncating the quotient, reverts on division by zero.*/

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
	// Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b);
	// There is no case in which this doesn&#39;t hold
    return c;}

  /*@dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).*/

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;}

  /*@dev Adds two numbers, reverts on overflow.*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;}

  /*@dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.*/

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;}
}

/*@title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.*/
 
library SafeERC20 {function safeTransfer(ERC20 token,address to, uint256 value) internal{
    require(token.transfer(to, value));}

  function safeTransferFrom(ERC20 token, address from,address to,uint256 value) internal {
    require(token.transferFrom(from, to, value));}

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));}
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value)public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {

    function transfer(address _to, uint _value) public returns (bool) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

  function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnlimitedAllowanceToken is StandardToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract IDMCOSAS is Ownable, UnlimitedAllowanceToken {
using SafeERC20 for ERC20;
    string public constant name = "IDMCOSAS";
   
  string public constant symbol = "MCS";
    
  uint32 public constant decimals = 18;
  
  uint256 public totalSupply = (10 ** 8) * (10 ** 18); // hundred million, 18 decimal places;  

    function MCS() public onlyOwner {
        balances[msg.sender] = totalSupply;
    }
}

contract PRESALE_IDMCOSAS is Ownable, IDMCOSAS {   

  using SafeMath for uint;
using SafeERC20 for ERC20;

  address multisig;

  uint restrictedPercent;

  address restricted;

  IDMCOSAS public token;

  uint public start;

  uint public period;

  uint256 public totalSupply;
      
  uint public hardcap;

  uint public softcap;
  
  address public wallet;

  uint256 public rate;

  uint256 public weiRaised;

  function rate() public view returns(uint256) {return rate; }
  function weiRaised() public view returns (uint256) { return weiRaised; }

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

// ------------------------------------------------------------------------
// Constructor
// ------------------------------------------------------------------------
  function PRESALE () public  {
	 token = IDMCOSAS(0x005dd5f95e135cd739945d50113fbe492c43bf2b4b);
     multisig = 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d;
     restricted = 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d;
     restrictedPercent = 15;
     rate = 189000000000000000000;
     start = 1538352000;
     period = 15;
     hardcap = 2000000000000000000000000;
     softcap = 498393000000000000000000;
	 totalSupply = (10 ** 8) * (10 ** 18); // hundred million, 18 decimal places;
	 wallet = 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d;
    }

   function buyTokens(address beneficiary) public payable {

    uint256 weiAmount = msg.value;
   

    // calculate token amount to be created
	
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
	
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokenPurchase( msg.sender, beneficiary, weiAmount, tokens);

    _forwardFunds();
    
  }
  
   // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /*@dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted*/
   
  function _deliverTokens( address beneficiary, uint256 tokenAmount) internal {
    emit Transfer(token, beneficiary, tokenAmount); }

  /*@dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased */
   
  function _processPurchase( address beneficiary, uint256 tokenAmount) internal {
    _deliverTokens(beneficiary, tokenAmount); }

 

  /*@dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount*/
  
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate); }

  /*@dev Determines how ETH is stored/forwarded on purchases.*/
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);}


  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

  function BonusTokens() public saleIsOn payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
    if(now < start + (period * 1 days).div(4)) {
      bonusTokens = tokens.div(4);
    } else if(now >= start + (period * 1 days).div(4) && now < start + (period * 1 days).div(4).mul(2)) {
      bonusTokens = tokens.div(10);
    } else if(now >= start + (period * 1 days).div(4).mul(2) && now < start + (period * 1 days).div(4).mul(3)) {
      bonusTokens = tokens.div(20);
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    uint restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
    token.transfer(restricted, restrictedTokens);
  }

    
  function() external payable {
    buyTokens(msg.sender);
    BonusTokens();
  }

}
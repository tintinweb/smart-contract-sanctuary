pragma solidity ^0.4.23;


// @title ERC20 interface
// @dev see https://github.com/ethereum/EIPs/issues/20
contract iERC20 {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}





// @title SafeMath
// @dev Math operations with safety checks that throw on error
library SafeMath {

  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

  // @dev Integer division of two numbers, truncating the quotient.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

  // @dev Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}

/* 
  Copyright 2018 Token Sales Network (https://tokensales.io)
  Licensed under the MIT license (https://opensource.org/licenses/MIT)

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
  and associated documentation files (the "Software"), to deal in the Software without restriction, 
  including without limitation the rights to use, copy, modify, merge, publish, distribute, 
  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
  is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or 
  substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// @title Token Sale Network
// A contract allowing users to buy a supply of tokens
// Adapted from OpenZeppelin&#39;s Crowdsale contract
// 
contract TokenSales {
  using SafeMath for uint256;

  // Event for token purchase logging
  // @param token that was sold
  // @param seller who sold the tokens
  // @param purchaser who paid for the tokens
  // @param value weis paid for purchase
  // @param amount amount of tokens purchased
  event TokenPurchase(
    address indexed token,
    address indexed seller,
    address indexed purchaser,
    uint256 value,
    uint256 amount
  );

  mapping(address => mapping(address => uint)) public saleAmounts;
  mapping(address => mapping(address => uint)) public saleRates;

  // @dev create a sale of tokens.
  // @param _token - must be an ERC20 token
  // @param _rate - how many token units a buyer gets per wei.
  //   The rate is the conversion between wei and the smallest and indivisible token unit.
  //   So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  //   1 wei will give you 1 unit, or 0.001 TOK.
  // @param _addedTokens - the number of tokens to add to the sale
  function createSale(iERC20 token, uint256 rate, uint256 addedTokens) public {
    uint currentSaleAmount = saleAmounts[msg.sender][token];
    if(addedTokens > 0 || currentSaleAmount > 0) {
      saleRates[msg.sender][token] = rate;
    }
    if (addedTokens > 0) {
      saleAmounts[msg.sender][token] = currentSaleAmount.add(addedTokens);
      token.transferFrom(msg.sender, address(this), addedTokens);
    }
  }

  // @dev A payable function that takes ETH, and pays out in the token specified.
  // @param seller - address selling the token
  // @param token - the token address
  function buy(iERC20 token, address seller) public payable {
    uint size;
    address sender = msg.sender;
    assembly { size := extcodesize(sender) }
    require(size == 0); // Disallow calling from contracts, for safety
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);

    uint rate = saleRates[seller][token];
    uint amount = saleAmounts[seller][token];
    require(rate > 0);

    uint256 tokens = weiAmount.mul(rate);
    saleAmounts[seller][token] = amount.sub(tokens);

    emit TokenPurchase(
      token,
      seller,
      msg.sender,
      weiAmount,
      tokens
    );

    token.transfer(msg.sender, tokens);
    seller.transfer(msg.value);
  }

  // dev Cancels all the sender&#39;s sales of a given token
  // @param token - the address of the token to be cancelled.
  function cancelSale(iERC20 token) public {
    uint amount = saleAmounts[msg.sender][token];
    require(amount > 0);

    delete saleAmounts[msg.sender][token];
    delete saleRates[msg.sender][token];

    if (amount > 0) {
      token.transfer(msg.sender, amount);
    }
  }

  // @dev fallback function always throws
  function () external payable {
    revert();
  }
}
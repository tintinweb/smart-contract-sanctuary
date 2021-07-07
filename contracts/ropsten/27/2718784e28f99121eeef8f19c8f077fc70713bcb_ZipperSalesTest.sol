/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.6;

contract ZipperSalesSafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ZipperSalesTest is ZipperSalesSafeMath { 
    address admin;
    uint256 public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint256 public decimals;


    event Sell(address _buyer, uint256 _amount);

    function withdrawPayments(address owner, uint256 amount) external payable {
    
    }

    function payments(address dest, uint256 amount) external payable returns(uint256) {
   
    }

    function ZipperTokenSale(uint256 _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(address _receiver, uint256 _amount) public payable {
        _amount = msg.value;
        require(_receiver != address(0));
        require(_amount > 0);
        uint256 tokensToBuy = multiply(_amount, (10 ** 18)) / 1 ether * tokenPrice;
        //require(tokenContract.transfer(msg.sender, tokensToBuy));
        tokensSold += _amount;

        emit Sell(msg.sender, tokensToBuy);
    }
}

 /** 
* Copyright CENTRE SECZ 2018 
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
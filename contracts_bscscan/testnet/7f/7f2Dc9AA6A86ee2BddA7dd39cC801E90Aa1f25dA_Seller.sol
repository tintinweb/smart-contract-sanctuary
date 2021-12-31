// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IToken.sol";

contract Seller is Ownable {
    IToken public token;

    constructor(address _tokenAddress) {
        token = IToken(_tokenAddress);
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    event Buy(address indexed buyer, uint indexed amountIn, uint indexed amountOut, uint exchangeUsd, uint priceUSD, uint priceBNB);

    function buy() public payable {
        require(msg.value > 0, "Value is too low");

        uint amount = calcAmount(msg.value);
        require(amount <= getTokenBalance(), "Not enough tokens on the balance");

        token.transfer(msg.sender, amount);

        emit Buy(msg.sender, msg.value, amount, token.getLatestPrice(), token.getPriceUSD(), token.getPriceBNB());
    }

    function calcAmount(uint value) public view returns (uint) {
        return value * (10 ** token.decimals()) / token.getPriceBNB();
    }

    function transfer(address recipient, uint amount) public onlyOwner {
        require(amount <= address(this).balance, "There is not enough balance");

        payable(recipient).transfer(amount);
    }

    function transferTokens(address recipient, uint amount) public onlyOwner {
        require(amount <= getTokenBalance(), "There is not enough balance");

        token.transfer(recipient, amount);
    }
}
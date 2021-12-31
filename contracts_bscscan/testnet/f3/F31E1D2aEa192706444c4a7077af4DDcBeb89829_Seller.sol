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
        uint amount = calcAmount(msg.value);

        require(getTokenBalance() >= amount, "Not enough tokens on the balance");

        token.transfer(msg.sender, amount);

        emit Buy(msg.sender, msg.value, amount, token.getLatestPrice(), token.getPriceUSD(), token.getPriceBNB());
    }

    function calcAmount(uint value) public view returns (uint) {
        return value * (10 ** token.decimals()) / uint(token.getPriceBNB());
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
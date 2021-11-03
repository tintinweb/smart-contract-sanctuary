/*
BlockNews is a DAO project, focused on blockchain media, news and articles. For more information visit the bellow link:
https://BlockNews.tech/

1,000,000 Initial Supply

Name: BlockNews
Symbol: BNW
Decimals: 6
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BEP20Token.sol";

contract Token is BEP20Token {

    constructor() {
    _name = "BlockNews";
    _symbol = "BNW";
    _decimals = 6;
    _totalSupply = 1000000 * 10 ** 6;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BEP20Token.sol";

contract Token is BEP20Token {

    constructor() {
    _name = "Husky";
    _symbol = "HUSKY";
    _decimals = 6;
    _totalSupply = 4000000000 * 10 ** 6;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

}
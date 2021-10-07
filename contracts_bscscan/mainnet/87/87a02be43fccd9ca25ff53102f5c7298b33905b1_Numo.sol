// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./BEP20Token.sol";

contract Numo is BEP20Token {

    constructor() {
    _name = "NUMO";
    _symbol = "NMO";
    _decimals = 6;
    _totalSupply = 250000 * 10 ** 6;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

}
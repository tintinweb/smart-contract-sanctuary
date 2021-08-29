// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <=0.6.12;

import "./Token.sol";

contract FactoryToken {
    function create_token(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
        new Token(_name, _symbol, _decimals, _totalSupply);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20.sol";



contract MyTestCoin is ERC20 {
    // mapping(address => uint256) private _balances;

    // mapping(address => mapping(address => uint256)) private _allowances;

    // uint256 private _totalSupply;

    // string private _name;
    // string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _name = "Dady Jiang";
        _symbol = "DADY";
        _totalSupply = 10000000 * (10 ** uint256(decimals()));
        _balances[_msgSender()] = _totalSupply;
    }
    
}
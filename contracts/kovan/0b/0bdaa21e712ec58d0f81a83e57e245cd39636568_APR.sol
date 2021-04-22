// SPDX-License-Identifier: MIT

pragma solidity ^ 0.7.6;

import "./ERC20.sol";

/**
 *  APR token based on ERC20
 */
contract APR is ERC20 {
    using SafeMath for uint256;

    /**
     *  call super constructor
     *  with _name, _symbol,
     *  with _decimals as 6,
     *  with maximium limit number of tokens as 21,000,000
     */
    constructor () ERC20("April", "APR") {
        _setupDecimals(6);
        _mint(msg.sender, 21000000 * (uint256(10) ** 6));
    }
}
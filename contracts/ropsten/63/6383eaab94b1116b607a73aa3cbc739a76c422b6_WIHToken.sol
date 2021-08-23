// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

/**
 * @dev Wealth in Health Token implementation.
 */
contract WIHToken is  ERC20Burnable {

    uint256 internal constant INITIAL_SUPPLY = 10 * (10**9) * (10 ** 18); // 10 billions tokens

    constructor(address _beneficiary) ERC20("Wealth in Health Token", "WIH") {
        _mint(_beneficiary, INITIAL_SUPPLY);
    }
}
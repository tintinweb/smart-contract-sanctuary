// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Context.sol";
import "./ERC20.sol";

contract HelioToken is Context, ERC20 {

    constructor () public ERC20("Helioroid", "HELIO") {
        _mint(_msgSender(), 100000000 * (10 ** uint256(decimals())));
    }
}
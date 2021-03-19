// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


import "./ERC20.sol";

contract Token is ERC20 {

    constructor () ERC20("Mars Panda Voucher Token", "MPVT") {
        _mint(msg.sender, 2000000 * (10 ** uint256(decimals())));
    }
}
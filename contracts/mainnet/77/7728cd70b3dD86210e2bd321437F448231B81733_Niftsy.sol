// SPDX-License-Identifier: MIT
// NIFTSY protocol ERC20
pragma solidity ^0.8.6;

import "./ERC20.sol";


contract Niftsy is ERC20 {
    //using SafeMath for uint256;

    uint256 constant public MAX_SUPPLY = 500_000_000e18;

    constructor(address initialKeeper)
    ERC20("NIFTSY", "NIFTSY")
    { 
        //Initial supply mint  - review before PROD
        _mint(initialKeeper, MAX_SUPPLY);
    }
}
pragma solidity ^0.8.7;

import "./RisingToken.sol";

/**

    
 */
 // SPDX-License-Identifier: MIT
contract SquidGameRevenge is RisingToken {

    string private name_ = "SquidGameRevenge";
    string private symbol_ = "SGV";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 100000000 * 10**6 * 10**decimals_;

    constructor() RisingToken(name_, symbol_, decimals_, supply_) {}

}
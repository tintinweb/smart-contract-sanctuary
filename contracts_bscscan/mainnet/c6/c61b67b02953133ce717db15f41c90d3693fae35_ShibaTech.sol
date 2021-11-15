pragma solidity ^0.8.7;

import "./RisingToken.sol";

/**

    
 */
 // SPDX-License-Identifier: MIT
contract ShibaTech is RisingToken {

    string private name_ = "ShibaTech";
    string private symbol_ = "ST";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 500000000 * 10**6 * 10**decimals_;

    constructor() RisingToken(name_, symbol_, decimals_, supply_) {}

}
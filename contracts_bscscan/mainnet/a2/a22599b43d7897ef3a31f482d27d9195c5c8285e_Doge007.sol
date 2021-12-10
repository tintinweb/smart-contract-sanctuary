pragma solidity ^0.8.7;

import "./RisingToken.sol";

/**

    
 */
 // SPDX-License-Identifier: MIT
contract Doge007 is RisingToken {

    string private name_ = "Doge007";
    string private symbol_ = "DGE";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 100000000 * 10**6 * 10**decimals_;

    constructor() RisingToken(name_, symbol_, decimals_, supply_) {}

}
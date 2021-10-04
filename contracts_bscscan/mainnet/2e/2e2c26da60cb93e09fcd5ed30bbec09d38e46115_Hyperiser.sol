pragma solidity ^0.8.7;

import "./DebasingToken.sol";

/**
    The AntiGravity contract.
    Visit the website : https://antigravity.money/
    Say hi in the telegram : https://t.me/Antigravity_Token
 */
 // SPDX-License-Identifier: MIT
contract Hyperiser is DebasingToken {

    string private name_ = "Hyperiser";
    string private symbol_ = "HR";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 10**15 * 10**decimals_;

    constructor() DebasingToken(name_, symbol_, decimals_, supply_) {}

}
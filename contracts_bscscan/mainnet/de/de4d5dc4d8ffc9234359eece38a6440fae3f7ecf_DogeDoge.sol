pragma solidity ^0.8.7;

import "./RewardToken.sol";

/**
    The DogeDoge contract.
    Visit the website : https://dogedoge.finance
    Say hi (or woof woof) in the telegram : https://t.me/dogedoge_coin
 */
 // SPDX-License-Identifier: MIT
contract DogeDoge is RewardToken {

    string private name_ = "DogeDoge";
    string private symbol_ = "DogeDoge";
    uint8 private decimals_ = 9;
    uint256 private supply_ = 10**15 * 10**decimals_;

    constructor() RewardToken(name_, symbol_, decimals_, supply_) {}

}
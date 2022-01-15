/**
 * @title Blacklist Math
 * @dev Blacklist contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

import "./Ownable.sol";
import "./BlacklistRole.sol";

pragma solidity ^0.6.12;

contract Blacklist is Ownable, BlacklistRole {
    mapping(address => bool) blacklist;
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    /**
     * @dev add address to the Blacklist.
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     * sender must have the blacklister role
     */
    function addToBlacklist(address _address) public onlyBlacklister {
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    /**
     * @dev Remove address from Blacklist.
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     * sender must have the blacklister role
     */
    function removeFromBlacklist(address _address) public onlyBlacklister {
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    /**
     * @dev Returns address is Blacklist true or false
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     */
    function isBlacklisted(address _address)
        public
        view
        returns (bool)
    {
        return blacklist[_address];
    }

}
/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CookieFactory {
    address baker;
    uint cookies;
    mapping(address => uint) givenCookies;

    event NewCookiesBaked(uint count);
    event CookiesDelivered(address to, uint count);
    event CookiesTransferred(address from, address to, uint count);
    event CookieEaten(address by);

    error OnlyBakerAllowed();
    error NotEnoughCookies(uint cookiesOwned);

    constructor() {
        baker = msg.sender;
    }

    function getBaker() view external returns (address) {
        return baker;
    }

    function getCookiesStored() view external returns (uint) {
        return cookies;
    }

    function getCookies(address owner) view external returns (uint) {
        return givenCookies[owner];
    }

    modifier kitchenAccess() {
        if (msg.sender != baker)
            revert OnlyBakerAllowed();
        _;
    }

    function transferFactory(address newOwner) external kitchenAccess {
        baker = newOwner;
    }

    function bakeCookies(uint count) external kitchenAccess {
        cookies += count;

        emit NewCookiesBaked(count);
    }

    function deliverCookies(uint count, address to) external kitchenAccess {
        require(cookies >= count);

        cookies -= count;
        givenCookies[to] += count;

        emit CookiesDelivered(to, count);
    }

    modifier haveCookies(uint count) {
        if (givenCookies[msg.sender] < count)
            revert NotEnoughCookies(givenCookies[msg.sender]);
        _;
    }

    function transferCookies(uint count, address to) external haveCookies(count) {
        givenCookies[msg.sender] -= count;
        givenCookies[to] += count;

        emit CookiesTransferred(msg.sender, to, count);
    }

    function consumeCookie() external haveCookies(1) {
        givenCookies[msg.sender]--;
        emit CookieEaten(msg.sender);
    }
}
/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Mintable {
    function mint(uint _amount) external returns (bool);
    function transfer(address _to, uint _amount) external returns (bool);
}

contract TestNetMint {
    constructor() {}

    function mint() public {
        Mintable(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F).mint(10000e18); // DAI
        Mintable(0xBD21A10F619BE90d6066c941b04e340841F1F989).mint(10000e6); // USDT
        Mintable(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e).mint(10000e6); // USDC
        Mintable(0x3C68CE8504087f89c640D02d133646d98e64ddd9).mint(3e18); // ETH
        Mintable(0x0d787a4a1548f673ed375445535a6c7A1EE56180).mint(1e8); // BTC

        Mintable(0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F).transfer(msg.sender, 10000e18); // DAI
        Mintable(0xBD21A10F619BE90d6066c941b04e340841F1F989).transfer(msg.sender, 10000e6); // USDT
        Mintable(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e).transfer(msg.sender, 10000e6); // USDC
        Mintable(0x3C68CE8504087f89c640D02d133646d98e64ddd9).transfer(msg.sender, 3e18); // ETH
        Mintable(0x0d787a4a1548f673ed375445535a6c7A1EE56180).transfer(msg.sender, 1e8); // BTC

        Mintable(0x9f9836AfB302FAf61F51a36A0eB79Bc95Be3DF6F).transfer(msg.sender, 1e18); // 2PI
    }
}
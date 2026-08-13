/**
 *Submitted for verification at cronoscan.com on 2022-05-23
*/

/*  
TOKEN - Faucet for testing the CRO <-> BSC Bridge
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.14;

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TheFaucet  {
    address public constant TOKEN = 0x5f553AD03E984ba54C691BCC32e18e5658C9e13B;
    address public theBridgeWallet = 0x5288009820Ff073Bb664e7330F5f0C9868878888;

    constructor() {}

    function get100TestToken() external {
        IBEP20(TOKEN).transferFrom(theBridgeWallet, msg.sender, 100000000000000000000);
    }
}
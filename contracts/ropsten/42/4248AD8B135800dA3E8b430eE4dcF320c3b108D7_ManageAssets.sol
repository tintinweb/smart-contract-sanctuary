/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ManageAssets {
    address[] private wallets;
    address[] private tokens;
    address private owner;

    event NewWallet(address _address);
    event NewToken(address _address);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function getWallets() public view returns (address[] memory) {
        return wallets;
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function pushWallet(address wallet) public onlyOwner returns (uint) {
        wallets.push(wallet);

        emit NewWallet(wallet);

        return wallets.length;
    }

    function pushToken(address token) public onlyOwner returns (uint) {
        tokens.push(token);

        emit NewToken(token);

        return tokens.length;
    }
}
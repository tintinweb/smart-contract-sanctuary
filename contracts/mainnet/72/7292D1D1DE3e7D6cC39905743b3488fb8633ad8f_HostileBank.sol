/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract HostileBank {
    address payable private _marketing;
    address payable private _buyback;
    address payable private _dev;
    address payable private _gameDev;

    constructor (address payable Marketing, address payable BuyBack, address payable Dev, address payable GameDev) {
        _marketing = Marketing;
        _buyback = BuyBack;
        _dev = Dev;
        _gameDev = GameDev;
    }

    receive() external payable {}
    
    function splitEth() external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        disperseEth();
    }
    
    function disperseEth() private {
         uint256 BALANCE = address(this).balance;
         uint256 GAMEFEE = BALANCE / 8 * 2;
         uint256 MKTGFEE = BALANCE / 8 * 4;
         uint256 DEVFEE = BALANCE / 8 * 1;
         uint256 BBFEE = BALANCE /8 * 1;
         payable(_gameDev).transfer(GAMEFEE);
         payable(_marketing).transfer(MKTGFEE);
         payable(_buyback).transfer(BBFEE);
         payable(_dev).transfer(DEVFEE);
         
    }

    function updateMarketing(address payable Marketing) external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        _marketing = Marketing;
    }

    function updateBuyBack(address payable BuyBack) external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        _buyback = BuyBack;
    }

    function updateDev(address payable Dev) external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        _dev = Dev;
    }

    function updateGameDev(address payable GameDev) external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        _gameDev = GameDev;
    }

    function manualSOS() external {
        require(msg.sender == _marketing || msg.sender == _dev, "Loser!");
        uint256 BALANCE = address(this).balance;
        sendETH(BALANCE);
    }

    function sendETH(uint256 amount) private {
        _dev.transfer(amount);
    }

}
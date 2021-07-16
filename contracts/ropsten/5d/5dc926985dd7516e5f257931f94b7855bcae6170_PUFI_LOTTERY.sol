/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface PUFI_LOTTERY_Interface {
    function sendLottery(address winner) external returns(bool);
}

contract PUFI_LOTTERY is PUFI_LOTTERY_Interface {
    uint256 public _prizeValue = (0.1 ether);
    address private _teamWallet;
    address private _PUFI;
    constructor (address teamWallet, address PUFIAddress) {
        _teamWallet = teamWallet;
        _PUFI = PUFIAddress;
    }
    function sendLottery(address winner) override external returns(bool) {
        require(msg.sender == _PUFI || msg.sender == _teamWallet);
        require(address(this).balance >= _prizeValue,"Insufficient funds in lottery");
        (bool success,) = winner.call{value: _prizeValue}("");
        return success;
    }
    function setPriceMoney(uint256 prizeValue) external {
        require(msg.sender == _teamWallet);
        _prizeValue = prizeValue;
    }
    receive() external payable {}
}
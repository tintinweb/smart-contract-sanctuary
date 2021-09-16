/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract Raffle is Ownable {
    uint RAFFLE_NUMBER = 5000;
    receive() external payable {}
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function changeRaffleNumber(uint raffleNumber) external onlyOwner {
        RAFFLE_NUMBER = raffleNumber;
    }
    function checkRaffleNumber() public view returns (uint) {
        return RAFFLE_NUMBER;
    }
    function raffle(address[] memory addresses) external onlyOwner {
        uint numberOfUsers = addresses.length;
        uint totalBalance = address(this).balance;
        uint sharePerOne = totalBalance/numberOfUsers;
        for(uint i = 0; i < numberOfUsers; i++) {
            payable(addresses[i]).transfer(sharePerOne);
        }
    }
}
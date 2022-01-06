/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReserveFTM {
    uint256 price = 1 ether;

    struct reserveList {
        string name;
        address addr;
    }
    reserveList[] reserves;

    constructor() { }

    modifier onlyOwner() {
        require(msg.sender == address(this), "Not owner");
        _;
    }

    function reserve() public payable {
        require(msg.value >= price, "Not Enough FTM Used For Reserve");
        reserveList memory newReserve = reserveList("contract", msg.sender);
        reserves.push(newReserve);
    }

    function getList() external view returns (reserveList[] memory) {
        return reserves;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No FTM Left To Withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
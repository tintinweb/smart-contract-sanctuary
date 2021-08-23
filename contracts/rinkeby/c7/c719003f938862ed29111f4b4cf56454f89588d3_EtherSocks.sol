/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

/**
 * EtherSocks
 *
 * Based on the incredible EtherRock project.
 *
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity ^0.8.4;

contract EtherSocks {
    struct Sock {
        address payable owner;
        bool currentlyForSale;
        uint256 price;
        uint256 timesSold;
    }

    event SockBought(
        address owner,
        uint256 sockNumber,
        uint256 price,
        uint256 timestamp
    );
    event SockListed(
        address owner,
        uint256 sockNumber,
        uint256 price,
        uint256 timestamp
    );
    event SockUnisted(address owner, uint256 sockNumber, uint256 timestamp);
    event SockGifted(address owner, uint256 sockNumber, uint256 timestamp);

    mapping(uint256 => Sock) public socks;

    mapping(address => uint256[]) public sockOwners;

    uint256 public latestNewSockForSale;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        socks[0].price = 10**15;
        socks[0].currentlyForSale = true;
        owner = msg.sender;
    }

    function getSockInfo(uint256 sockNumber)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        return (
            socks[sockNumber].owner,
            socks[sockNumber].currentlyForSale,
            socks[sockNumber].price,
            socks[sockNumber].timesSold
        );
    }

    function sockOwningHistory(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return sockOwners[_address];
    }

    function buySock(uint256 sockNumber) public payable {
        require(socks[sockNumber].currentlyForSale == true);
        require(msg.value == socks[sockNumber].price);
        socks[sockNumber].currentlyForSale = false;
        socks[sockNumber].timesSold++;
        if (sockNumber != latestNewSockForSale) {
            socks[sockNumber].owner.transfer(socks[sockNumber].price);
        }
        socks[sockNumber].owner = payable(msg.sender);
        sockOwners[msg.sender].push(sockNumber);

        emit SockBought(msg.sender, sockNumber, msg.value, block.timestamp);

        if (sockNumber == latestNewSockForSale) {
            if (sockNumber != 99) {
                latestNewSockForSale++;
                socks[latestNewSockForSale].price =
                    10**15 +
                    (latestNewSockForSale**2 * 10**15);
                socks[latestNewSockForSale].currentlyForSale = true;
            }
        }
    }

    function sellSock(uint256 sockNumber, uint256 price) public {
        require(msg.sender == socks[sockNumber].owner);
        require(price > 0);
        socks[sockNumber].price = price;
        socks[sockNumber].currentlyForSale = true;

        emit SockListed(msg.sender, sockNumber, price, block.timestamp);
    }

    function dontSellSock(uint256 sockNumber) public {
        require(msg.sender == socks[sockNumber].owner);
        socks[sockNumber].currentlyForSale = false;

        emit SockUnisted(msg.sender, sockNumber, block.timestamp);
    }

    function giftSock(uint256 sockNumber, address payable receiver) public {
        require(msg.sender == socks[sockNumber].owner);
        socks[sockNumber].owner = receiver;
        sockOwners[receiver].push(sockNumber);

        emit SockGifted(msg.sender, sockNumber, block.timestamp);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
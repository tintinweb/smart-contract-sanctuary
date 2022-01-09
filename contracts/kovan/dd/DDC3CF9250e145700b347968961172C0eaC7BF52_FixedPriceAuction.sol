// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IAuction.sol";

contract FixedPriceAuction is IAuction {
    uint private _price;
    string private _auctionType;
    string private _auctionDetails;
    mapping(uint => uint256) public _mintedCountAtPrice;

    constructor(uint price) {
        _auctionType = "Fixed Price";
        _auctionDetails = "";
        _price = price;

    }

    function auctionType() external view override returns (string memory) {
        return _auctionType;
    }

    function auctionDetails() external view override returns (string memory) {
        return _auctionDetails;
    }

    function getCurrentPrice() external view override returns (uint) {
        return _price;
    }

    function incrementAtCurrentPrice() external override {
        _mintedCountAtPrice[_price]++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IAuction {
    function auctionType() external view returns (string memory);
    function auctionDetails() external view returns (string memory);
    function getCurrentPrice() external view returns (uint); // in WEI
    function incrementAtCurrentPrice() external; // in WEI
}
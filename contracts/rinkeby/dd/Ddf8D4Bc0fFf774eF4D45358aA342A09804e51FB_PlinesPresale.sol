// SPDX-License-Identifier: MIT

// presale DApp https://presale.plines.io

pragma solidity ^0.8.9;

contract PlinesPresale {
    uint256 internal _price;
    uint256 internal _maxAmountPerPurchase;
    address internal _vault;

    event Buy(address indexed from, uint256 amount);

    constructor(
        uint256 price,
        uint256 maxAmountPerPurchase,
        address vault
    ) {
        _price = price;
        _maxAmountPerPurchase = maxAmountPerPurchase;
        _vault = vault;
    }

    function buy(uint256 amount) public payable {
        require(amount <= _maxAmountPerPurchase, "Can not buy > maxAmountPerPurchase");

        emit Buy(msg.sender, amount);
    }
}
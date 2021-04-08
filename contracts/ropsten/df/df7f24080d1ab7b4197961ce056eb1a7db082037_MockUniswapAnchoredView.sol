// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./UniswapAnchoredView.sol";

contract MockUniswapAnchoredView is UniswapAnchoredView {
    mapping(bytes32 => uint) public anchorPrices;

    constructor(OpenOraclePriceData priceData_,
                address reporter_,
                uint anchorToleranceMantissa_,
                uint anchorPeriod_,
                TokenConfig[] memory configs) UniswapAnchoredView(priceData_, reporter_, anchorToleranceMantissa_, anchorPeriod_, configs) public {}

    function setAnchorPrice(string memory symbol, uint price) external {
        prices[keccak256(abi.encodePacked(symbol))] = price;
    }

    function fetchAnchorPrice(string memory _symbol, TokenConfig memory config, uint _conversionFactor) internal override returns (uint) {
        _symbol; // Shh
        _conversionFactor; // Shh
        return anchorPrices[config.symbolHash];
    }
}
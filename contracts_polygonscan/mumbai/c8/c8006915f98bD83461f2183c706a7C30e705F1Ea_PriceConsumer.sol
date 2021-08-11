/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumer {
    function getLatestPrice() external view returns (int);
}

contract PriceConsumer {
    IPriceConsumer priceConsumerETH = IPriceConsumer(0x1943BD273b36d3D54442824F13F6CcC3F0b87f65);
    IPriceConsumer priceConsumerwBTC = IPriceConsumer(0x6AC37C599Be7eA006310366B1b89Dd1D315C028b);
    IPriceConsumer priceConsumerPolygon = IPriceConsumer(0x83072aC0d1dFe6b79E1b95B8b96309065ECCd074);

    uint8 constant ETH = 1;
    uint8 constant WBTC = 2;
    uint8 constant POLYGON = 3;

    function getSpotPrice(uint8 underlying) external view returns (uint256) {
        // Feeds always return a number with 8 decimals, that represents the price of 1 asset in USD
        
        if (underlying == ETH) {
            return uint256(priceConsumerETH.getLatestPrice());
        }
        else if (underlying == WBTC) {
            return uint256(priceConsumerwBTC.getLatestPrice());
        }
        else if (underlying == POLYGON) {
            return uint256(priceConsumerPolygon.getLatestPrice());
        }
        
        return 0;
    }
}
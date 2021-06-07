// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import './PriceDiscovery.sol';

contract TimeSet is PriceDiscovery{
    using SafeMath for uint;
    constructor( 
        address sYSL,
        address busdContractAddress,
        address wbnbContractAddress,
        address swapRouterContractAddress,
        uint sYSLInitialTotalSupply,
        uint privateStartTime) 
    PriceDiscovery(sYSL, busdContractAddress, 
                wbnbContractAddress, 
                swapRouterContractAddress, 
                sYSLInitialTotalSupply, 
                privateStartTime){

    }

    function setDiscoveryStart(uint _timestamp) public {
        privateSaleStartTime=_timestamp;
        priceDiscoveryStartTime = privateSaleStartTime.add(PRIVATE_SALE_DURATION);
    }
}
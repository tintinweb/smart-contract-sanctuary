/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPremiumCalculator {
    function getPremiumRate(uint16 assetIndex_) external view returns(uint256);
}

contract MockPremiumCalculator {
    
    address constant ROOT = 0xADc8B0ea9938BA9634ADd3288A4d6d9930c11a8a;
    
    function getPremiumRate(uint16 assetIndex_, address who_) external view returns(uint256) {
        IPremiumCalculator(ROOT).getPremiumRate(assetIndex_);
    }
}
/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract BTCOracle {
    uint256 public btcPrice;
    event UpdatedPrice(uint256 _btcPrice);
    
    function setBTCPrice(uint256 _btcPrice) external {
        btcPrice = _btcPrice;
        emit UpdatedPrice(btcPrice);
    }
}
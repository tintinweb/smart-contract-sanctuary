/**
 *Submitted for verification at FtmScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function setRole(uint8 index, address role) external;
}


contract AssetSetRole {
    address public immutable asset;
    address private immutable owner;

    constructor (address asset_) {
        asset = asset_;
        owner = msg.sender;
    }

    /**
        amount: asset amount
     */
    function setRole(uint8 index, address role) external {
        require(msg.sender == owner, "Must be owner");

        IAssetBox(asset).setRole(index, role);
    }

}
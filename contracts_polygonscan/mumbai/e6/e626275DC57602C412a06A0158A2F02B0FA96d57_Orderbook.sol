/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
// File: contracts/LibAsset.sol


pragma solidity ^0.8.0;

library LibAsset {
    // bytes4 public constant ERC20_DATA_TYPE = bytes4(keccak256("ERC20"));
    // bytes4 public constant ERC721_DATA_TYPE = bytes4(keccak256("ERC721"));
    // bytes4 public constant ERC1155_DATA_TYPE = bytes4(keccak256("ERC1155"));

    struct Asset {
        bytes4 dataType;
        bytes data;
    }
}

// File: contracts/LibOrder.sol


pragma solidity ^0.8.0;


library LibOrder {
    // bytes4 public constant ERC20_DATA_TYPE = bytes4(keccak256("ERC20"));
    // bytes4 public constant ERC721_DATA_TYPE = bytes4(keccak256("ERC721"));
    // bytes4 public constant ERC1155_DATA_TYPE = bytes4(keccak256("ERC1155"));

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        bytes4 dataType;
        bytes data;
        uint256 deadline;
    }
}

// File: contracts/Orderbook.sol


pragma solidity ^0.8.0;


contract Orderbook {
    function postOrders(LibOrder.Order[] calldata orders) external {}
}
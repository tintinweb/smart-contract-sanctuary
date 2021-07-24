/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IExchangeV2Core {
    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }
    
    struct Asset {
        AssetType assetType;
        uint value;
    }

    struct Order {
        address maker;
        Asset makeAsset;
        address taker;
        Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }
    
    function matchOrders(
        Order memory orderLeft,
        bytes memory signatureLeft,
        Order memory orderRight,
        bytes memory signatureRight
    ) external payable;
}

library RaribleV2Market {
    address public constant RARIBLE = 0x9757F2d2b135150BBeb65308D4a91804107cd8D6;

    struct RaribleBuy {
        IExchangeV2Core.Order orderLeft;
        bytes signatureLeft;
        IExchangeV2Core.Order orderRight;
        bytes signatureRight;
        uint256 price;
    }

    function buyAssetsForEth(RaribleBuy[] memory raribleBuys) external {
        for (uint256 i = 0; i < raribleBuys.length; i++) {
            _buyAssetForEth(raribleBuys[i]);
        }
    }

    function _buyAssetForEth(RaribleBuy memory raribleBuy) internal {
        bytes memory _data = abi.encodeWithSelector(
            IExchangeV2Core(RARIBLE).matchOrders.selector, 
            raribleBuy.orderLeft,
            raribleBuy.signatureLeft,
            raribleBuy.orderRight,
            raribleBuy.signatureRight
        );
        (bool success, ) = RARIBLE.call{value:raribleBuy.price}(_data);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
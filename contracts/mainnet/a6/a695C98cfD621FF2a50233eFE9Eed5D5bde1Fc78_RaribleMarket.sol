/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



// Part: IRarible

interface IRarible {
    enum AssetType {ETH, ERC20, ERC1155, ERC721, ERC721Deprecated}

    struct Asset {
        address token;
        uint tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint salt;

        /* what has owner */
        Asset sellAsset;

        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;

        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    function exchange(
        Order memory order,
        Sig memory sig,
        uint buyerFee,
        Sig memory buyerFeeSig,
        uint amount,
        address buyer
    ) payable external;
}

// File: RaribleMarket.sol

library RaribleMarket {
    address public constant RARIBLE = 0xcd4EC7b66fbc029C116BA9Ffb3e59351c20B5B06;

    struct RaribleBuy {
        IRarible.Order order;
        IRarible.Sig sig;
        uint buyerFee;
        IRarible.Sig buyerFeeSig;
        uint amount;
    }

    function buyAssetsForEth(bytes memory data, address recipient) public {
        RaribleBuy[] memory raribleBuys;

        (raribleBuys) = abi.decode(
            data,
            (RaribleBuy[])
        );

        for (uint256 i = 0; i < raribleBuys.length; i++) {
            uint256 price = raribleBuys[i].order.buying*raribleBuys[i].amount/raribleBuys[i].order.selling;
            price = price+(price*raribleBuys[i].buyerFee/10000);
            _buyAssetForEth(
                price,
                raribleBuys[i].amount, 
                raribleBuys[i].buyerFee, 
                raribleBuys[i].order, 
                raribleBuys[i].sig, 
                raribleBuys[i].buyerFeeSig, 
                recipient
            );
        }
    }

    function estimateBatchAssetPriceInEth(bytes memory data) public view returns(uint256 totalCost) {
        RaribleBuy[] memory raribleBuys;

        (raribleBuys) = abi.decode(
            data,
            (RaribleBuy[])
        );

        for (uint256 i = 0; i < raribleBuys.length; i++) {
            uint256 price = raribleBuys[i].order.buying*raribleBuys[i].amount/raribleBuys[i].order.selling;
            totalCost += price+(price*raribleBuys[i].buyerFee/10000);
        }
    }

    function _buyAssetForEth(
        uint256 _price, 
        uint256 _amount, 
        uint256 _buyerFee, 
        IRarible.Order memory _order, 
        IRarible.Sig memory _sig, 
        IRarible.Sig memory _buyerFeeSig, 
        address _recipient
    ) internal {
        bytes memory _data = abi.encodeWithSelector(IRarible(RARIBLE).exchange.selector, _order, _sig, _buyerFee, _buyerFeeSig, _amount, _recipient);
        (bool success, ) = RARIBLE.call{value:_price}(_data);
        require(success, "_buyAssetForEth: rarible buy failed.");
    }
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

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

library RaribleV1Market {
    address public constant RARIBLE = 0x09EaB21c40743B2364b94345419138eF80f39e30;

    struct RaribleBuy {
        IRarible.Order order;
        IRarible.Sig sig;
        uint buyerFee;
        IRarible.Sig buyerFeeSig;
        uint amount;
        uint256 price;
    }

    function buyAssetsForEth(RaribleBuy[] memory raribleBuys, address recipient) external {
        for (uint256 i = 0; i < raribleBuys.length; i++) {
            _buyAssetForEth(
                raribleBuys[i].price,
                raribleBuys[i].amount, 
                raribleBuys[i].buyerFee, 
                raribleBuys[i].order, 
                raribleBuys[i].sig, 
                raribleBuys[i].buyerFeeSig, 
                recipient
            );
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
        bytes memory _data = abi.encodeWithSelector(IRarible.exchange.selector, _order, _sig, _buyerFee, _buyerFeeSig, _amount, _recipient);
        (bool success, ) = RARIBLE.call{value:_price}(_data);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
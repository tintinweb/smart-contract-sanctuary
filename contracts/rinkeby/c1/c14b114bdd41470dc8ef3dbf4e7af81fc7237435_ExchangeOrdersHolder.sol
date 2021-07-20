/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-17
 */

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract ExchangeDomain {
    enum AssetType {
        ETH,
        ERC20,
        ERC1155,
        ERC721,
        ERC721Deprecated
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint256 salt;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling */
        uint256 sellerFee;
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
}

contract ExchangeOrdersHolder {
    mapping(bytes32 => OrderParams) internal orders;

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling */
        uint256 sellerFee;
    }

    function add(ExchangeDomain.Order calldata order) external {
        require(
            msg.sender == order.key.owner,
            "order could be added by owner only"
        );
        bytes32 key = prepareKey(order);
        orders[key] = OrderParams(order.selling, order.buying, order.sellerFee);
    }

    function exists(ExchangeDomain.Order calldata order)
        external
        view
        returns (bool)
    {
        bytes32 key = prepareKey(order);
        OrderParams memory params = orders[key];
        return
            params.buying == order.buying &&
            params.selling == order.selling &&
            params.sellerFee == order.sellerFee;
    }

    function prepareKey(ExchangeDomain.Order memory order)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    order.key.sellAsset.token,
                    order.key.sellAsset.tokenId,
                    order.key.owner,
                    order.key.buyAsset.token,
                    order.key.buyAsset.tokenId,
                    order.key.salt
                )
            );
    }
}
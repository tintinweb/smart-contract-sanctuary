/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/exchange/ExchangeDomainV1.sol

pragma solidity ^0.5.0;

/// @title ExchangeDomainV1
/// @notice Describes all the structs that are used in exchnages.
contract ExchangeDomainV1 {

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

        /* fee for selling. Represented as percents * 100 (100% - 10000. 1% - 100)*/
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
}


// File contracts/exchange/ExchangeOrdersHolderV1.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/// @title ExchangeOrdersHolderV1
/// @notice Optionally holds orders, which can be exchanged without order's holder signature.
contract ExchangeOrdersHolderV1 {

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }

    mapping(bytes32 => OrderParams) internal orders;

    /// @notice This function can be called to add the order to the contract, so it can be exchanged without signature.
    ///         Can be called only by the order owner.
    /// @param order - The order struct to add.
    function add(ExchangeDomainV1.Order calldata order) external {
        require(msg.sender == order.key.owner, "order could be added by owner only");
        bytes32 key = prepareKey(order);
        orders[key] = OrderParams(order.selling, order.buying, order.sellerFee);
    }

    /// @notice This function checks if order was added to the orders holder contract.
    /// @param order - The order struct to check.
    /// @return true if order is present in the contract's data.
    function exists(ExchangeDomainV1.Order calldata order) external view returns (bool) {
        bytes32 key = prepareKey(order);
        OrderParams memory params = orders[key];
        return params.buying == order.buying && params.selling == order.selling && params.sellerFee == order.sellerFee;
    }

    function prepareKey(ExchangeDomainV1.Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                order.key.sellAsset.token,
                order.key.sellAsset.tokenId,
                order.key.owner,
                order.key.buyAsset.token,
                order.key.buyAsset.tokenId,
                order.key.salt
            ));
    }
}
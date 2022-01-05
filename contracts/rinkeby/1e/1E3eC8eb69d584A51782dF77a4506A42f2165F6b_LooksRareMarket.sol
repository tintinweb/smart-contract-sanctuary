/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: contracts/OrderTypes.sol


pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}
// File: contracts/LooksRareMarket.sol



pragma solidity 0.8.7;


interface ILooksRare {
    // Buy the artwork for the currently set price
    // TakerOrder is the bid, MakerOrder is the list 
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external;
}

library LooksRareMarket {
    address public constant LOOKSRARE = 0x1AA777972073Ff66DCFDeD85749bDD555C0665dA;

    function buyAssetsForEth(OrderTypes.TakerOrder[] calldata takerBids, OrderTypes.MakerOrder[] calldata makerAsks) external {
        for(uint256 i = 0; i < makerAsks.length; i++) {
            _buyAssetForEth(takerBids[i], makerAsks[i]);
        }
    }

    function _buyAssetForEth(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) internal {
        bytes memory _data = abi.encodeWithSelector(ILooksRare.matchAskWithTakerBid.selector, takerBid, makerAsk);

        (bool success, ) = LOOKSRARE.call{value:0}(_data);
        require(success, "_buyAssetForEth: Looks Rare buy failed.");
    }

}
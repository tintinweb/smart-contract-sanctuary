// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "./libraries/OrderTypes.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";

/**
 * @title StrategyStandardSaleForFixedPrice
 * @notice Strategy that executes an order at a fixed price that
 * can be taken either by a bid or an ask.
 */
contract StrategyStandardSaleForFixedPrice is IExecutionStrategy {
    uint256 public immutable PROTOCOL_FEE;

    /**
     * @notice Constructor
     * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
     */
    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

    /**
     * @notice Check whether a taker ask order can be executed against a maker bid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     */
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            ((makerBid.price == takerAsk.price) &&
                (makerBid.tokenId == takerAsk.tokenId) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp)),
            makerBid.tokenId,
            makerBid.amount
        );
    }

    /**
     * @notice Check whether a taker bid order can be executed against a maker ask
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     */
    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            makerAsk.tokenId,
            makerAsk.amount
        );
    }

    /**
     * @notice Return protocol fee for this strategy
     * @return protocol fee
     */
    function viewProtocolFee() external view override returns (uint256) {
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the marketplace.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}
/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.8.0;
pragma experimental ABIEncoderV2;


contract Operator {
    enum OrderStatus {
        New,
        Approved,
        BuyerApproved,
        SellerApproved,
        Canceled,
        TradeSuccess,
        TradeFailure
    }

    enum OrderType {
        Buy,
        Sell
    }

    struct Order {
        OrderType orderType;
        OrderStatus orderStatus;
        address maker;
        address taker;
        bytes32 itemName;
        uint256 amount;
        uint256 value;
        
    }

    struct OrderInfo {
        Order order;
        bytes32 orderHash;
    }

    bytes2 constant private EIP191_HEADER = 0x1901;

    // EIP712 Domain Name value
    string constant private EIP712_DOMAIN_NAME = "Orders";

    // EIP712 Domain Version value
    string constant private EIP712_DOMAIN_VERSION = "1.1";

    bytes32 constant private EIP712_ORDER_STRUCT_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Order(",
        "OrderType orderType,",
        "OrderStatus orderStatus,",
        "address maker,",
        "address taker,",
        "bytes32 itemName,",
        "uint256 amount,",
        "uint256 value,",
        ")"
    ));

    mapping(address=>OrderInfo) public buyOrderMap;
    address payable public taker;

    function createOrder(Order memory order) public payable {
        taker = payable(msg.sender);
        order.maker = taker;
        order.orderStatus = OrderStatus.New;
        order.amount = msg.value;
        bytes32 orderHash = getOrderHash(order);
        OrderInfo memory orderInfo;
        orderInfo.order = order;
        orderInfo.orderHash = orderHash;
        buyOrderMap[order.maker] = orderInfo;
    }

    function getOrderItemName(address maker) public view returns (bytes32) {
        bytes32 itemName = buyOrderMap[maker].order.itemName;
        return itemName;
    }

    function getOrderHash(
        Order memory order
    )
        private
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(
            EIP712_ORDER_STRUCT_SCHEMA_HASH,
            order
        ));

        return keccak256(abi.encodePacked(
            EIP191_HEADER,
            structHash
        ));
    }
}
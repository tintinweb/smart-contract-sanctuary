/**
 *Submitted for verification at polygonscan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;
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
        bytes32 contact;
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
        "bytes32 contact,"
        "uint256 amount",
        ")"
    ));

    mapping(address=>OrderInfo) public buyOrderMap;
    mapping(address=>OrderInfo) public sellOrderMap;

    function buyOrder(bytes32 itemName, uint amount, bytes32 contact) public payable{
        payable(msg.sender).transfer(amount*2);

        Order memory order;
        
        
        order.orderStatus = OrderStatus.New;
        order.orderType = OrderType.Buy;
        order.maker = msg.sender;
        order.taker = address(0);
        order.itemName = itemName;
        order.contact = contact;
        order.amount = amount;

        bytes32 orderHash = getOrderHash(order);
        OrderInfo memory orderInfo;
        orderInfo.order = order;
        orderInfo.orderHash = orderHash;
        buyOrderMap[order.maker] = orderInfo;
    }

    function getItemName(address maker) public view returns (bytes32) {
        return buyOrderMap[maker].order.itemName;
    }

    function getContact(address maker) public view returns (bytes32) {
        return buyOrderMap[maker].order.contact;
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
/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;


contract Order {
    enum OrderStatus {
        New,
        Taked,
        MakerApproved,
        TakerApproved,
        Canceled,
        TradeSuccess,
        TradeFailure
    }

     enum OrderType {
        Buy,
        Sell
    }

    uint orderType;
    OrderStatus orderStatus;
    address maker;
    address taker;
    string itemName;
    uint amount;
    string contactMe;
    uint createDate;
    uint takeDate;

    constructor(uint _orderType, string memory _itemName, string memory _contactMe) public payable {
        // require(
        //     msg.value == _amount*2, 
        //     'need twice of item amount as deposit'
        //     );
        orderType = _orderType;
        orderStatus = OrderStatus.New;
        maker = msg.sender;
        taker = address(0);
        itemName = _itemName;
        amount = amount;
        contactMe = _contactMe;
        createDate = block.timestamp;
    }

    function take() public payable {
        require(msg.value == amount*2, 'need twice of item amount as deposit');
        taker = msg.sender;
        orderStatus = OrderStatus.Taked;
        takeDate = block.timestamp;
    }
}

contract Operator {

    // struct OrderInfo {
    //     Order order;
    //     bytes32 orderHash;
    // }

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
        "string itemName,",
        "string contactMe,"
        "uint256 amount",
        ")"
    ));

    mapping(address=>Order) public buyOrderMap;
    mapping(address=>Order) public sellOrderMap;
    // public Order[] buyOrderList;
    // public Order[] sellOrderList;

    function buyOrder(string memory itemName, string memory contactMe) public payable {
        Order order = (new Order).value(msg.value)(1, itemName, contactMe);
        
        
        // order.orderStatus = OrderStatus.New;
        // order.orderType = OrderType.Buy;
        // order.maker = msg.sender;
        // order.taker = address(0);
        // order.itemName = itemName;
        // order.contactMe = contactMe;
        // order.amount = msg.value*2;

        // bytes32 orderHash = getOrderHash(order);
        // OrderInfo memory orderInfo;
        // orderInfo.order = order;
        // orderInfo.orderHash = orderHash;

        // buyOrderList.push(order)
        buyOrderMap[msg.sender] = order;
    }

    // function getItemName(address maker) public view returns (string memory) {
    //     return buyOrderMap[maker].itemName;
    // }

    // function getContact(address maker) public view returns (string memory) {
    //     return buyOrderMap[maker].contact;
    // }

    // function getOrderHash(
    //     Order memory order
    // )
    //     private
    //     view
    //     returns (bytes32)
    // {
    //     bytes32 structHash = keccak256(abi.encode(
    //         EIP712_ORDER_STRUCT_SCHEMA_HASH,
    //         order
    //     ));

    //     return keccak256(abi.encodePacked(
    //         EIP191_HEADER,
    //         structHash
    //     ));
    // }
}
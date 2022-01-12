// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/IVNLSSellOrderBook.sol";
import "./interfaces/IVirtualBitcoin.sol";

contract VNLSSellOrderBook is IVNLSSellOrderBook {
    
    IVirtualBitcoin vbtc;

    struct SellOrder {
        address seller;
        uint256 amount;
        uint256 price;
    }
    SellOrder[] public orders;

    constructor(IVirtualBitcoin _vbtc) {
        vbtc = _vbtc;
    }

    function count() override external view returns (uint256) {
        return orders.length;
    }

    function get(uint256 orderId) override external view returns (address seller, uint256 amount, uint256 price) {
        SellOrder memory order = orders[orderId];
        return (order.seller, order.amount, order.price);
    }

    function sell(uint256 amount, uint256 price) override external {
        vbtc.transferFrom(msg.sender, address(this), amount);
        uint256 orderId = orders.length;
        orders.push(SellOrder({
            seller: msg.sender,
            amount: amount,
            price: price
        }));
        emit Sell(orderId, msg.sender, amount, price);
    }

    function remove(uint256 orderId) internal {
        delete orders[orderId];
        emit Remove(orderId);
    }

    function buy(uint256 orderId) override payable external {
        SellOrder storage order = orders[orderId];
        uint256 amount = order.amount * msg.value / order.price;
        vbtc.transfer(msg.sender, amount);
        order.amount -= amount;
        order.price -= msg.value;
        address seller = order.seller;
        if (order.amount == 0) {
            remove(orderId);
        }
        payable(seller).transfer(msg.value);
        emit Buy(orderId, msg.sender, amount);
    }

    function cancel(uint256 orderId) override external {
        SellOrder memory order = orders[orderId];
        require(order.seller == msg.sender);
        vbtc.transfer(msg.sender, order.amount);
        remove(orderId);
        emit Cancel(orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IVNLSSellOrderBook {

    event Sell(uint256 indexed orderId, address indexed seller, uint256 amount, uint256 price);
    event Remove(uint256 indexed orderId);
    event Buy(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event Cancel(uint256 indexed orderId);

    function count() external view returns (uint256);
    function get(uint256 orderId) external view returns (address seller, uint256 amount, uint256 price);
    function sell(uint256 amount, uint256 price) external;
    function buy(uint256 orderId) payable external;
    function cancel(uint256 orderId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVirtualBitcoin {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BuyPizza(address indexed owner, uint256 indexed pizzaId, uint256 power);
    event ChangePizza(address indexed owner, uint256 indexed pizzaId, uint256 power);
    event SellPizza(address indexed owner, uint256 indexed pizzaId);
    event Mine(address indexed owner, uint256 indexed pizzaId, uint256 subsidy);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function pizzaPrice(uint256 power) external view returns (uint256);
    function pizzaCount() external view returns (uint256);
    function subsidyAt(uint256 blockNumber) external view returns (uint256);
    function buyPizza(uint256 power) external returns (uint256);
    function sellPizza(uint256 pizzaId) external;
    function changePizza(uint256 pizzaId, uint256 power) external;
    function powerOf(uint256 pizzaId) external view returns (uint256);
    function subsidyOf(uint256 pizzaId) external view returns (uint256);
    function mine(uint256 pizzaId) external returns (uint256);
}
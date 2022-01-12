// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract AcceptedToken is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal acceptedTokens;

    event AddTokens(address[] tokens);
    event RemoveTokens(address[] tokens);

    function addAcceptedTokens(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            acceptedTokens.add(tokens[i]);
        }
        emit AddTokens(tokens);
    }

    function removeAcceptedTokens(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            acceptedTokens.remove(tokens[i]);
        }
        emit RemoveTokens(tokens);
    }

    function isAcceptedToken(address token) public view returns (bool) {
        return acceptedTokens.contains(token);
    }

    function totalAcceptedTokens() external view returns (uint256) {
        return acceptedTokens.length();
    }

    function acceptedTokenAt(uint256 i) external view returns (address) {
        return acceptedTokens.at(i);
    }
}

/**
 * @title Galaxy Survivor Marketplace.
 * @dev Implement a contract for buying and selling ships and items.
 */
contract GLXMarket is Context, Ownable, AcceptedToken {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    enum TargetType {
        ERC721,
        ERC1155
    }

    enum OrderSide {
        Buy,
        Sell
    }

    /**
     * @dev Data structure that contains information for an order.
     * @param maker is the address of account that creates the order.
     * @param tokenId is the id of item want to buy/sell.
     * @param price is price for buying/selling one item.
     * @param createdTime is timestamp when the order is created.
     * @param expiredTime is the timestamp when the order will be expired.
     * @param amount is the number of items want to buy/sell.
     * @param remainAmount is the remaining amount can be bought/sold.
     * @param targetType is the type of target contract.
     * @param side is whether buy or sell.
     */
    struct Order {
        address maker;
        address token;
        address target;
        uint256 tokenId;
        uint256 price;
        uint64 createdTime;
        uint64 expiredTime;
        uint32 amount;
        uint32 remainAmount;
        TargetType targetType;
        OrderSide side;
    }

    // Reverse of one basic point.
    uint256 constant public INVERSE_BASIC_POINT = 10000;
    uint256 constant public MIN_ORDER_DURATION = 10 minutes;

    // Base fee in basic points.
    uint256 private _baseFee = 100;

    uint256 public totalOrders;

    mapping(uint256 => Order) private orders;
    mapping(address => EnumerableSet.UintSet) userOrderIds;

    /**
    * @dev Emitted when a new fee is set.
    */
    event SetFee(address indexed operator, uint256 oldFee, uint256 newFee);

    /**
    * @dev Emitted when an order is successfully created.
    */
    event CreateOrder(
        uint256 indexed orderId,
        address indexed maker,
        address token,
        address target,
        TargetType targetType,
        uint256 tokenId,
        uint256 price,
        uint32 amount,
        uint64 createdTime,
        uint64 expiredTime,
        OrderSide side
    );

    /**
    * @dev Emitted when an order is successfully cancelled.
    */
    event CancelOrder(address indexed operator, uint256 indexed orderId);

    /**
    * @dev Emitted when an order is taken.
    */
    event TakeOrder(
        uint256 indexed orderId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice,
        uint256 totalFee
    );

    /**
    * @dev Sets addresses for accepted tokens for purchasing.
    */
    constructor(address[] memory tokens) {
        addAcceptedTokens(tokens);
    }

    /**
    * @dev Sets a new fee value for market.
    *
    * The unit for fee value basic points.
    */ 
    function setFee(uint256 fee) external onlyOwner {
        require(fee > 0, "zero fee");
        uint256 oldFee = _baseFee;
        _baseFee = fee;
        emit SetFee(_msgSender(), oldFee, _baseFee);
    }

    receive() external payable {}

    /**
    * @dev Withdraws an {amount} of {token} to {to} address.
    */
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        _tokenTransfer(token, to, amount);
    }

    /**
    * @dev Creates a new order for buying/selling items.
    * @param tokenId is id of item want to buy/sell.
    * @param targetType is the type of target contract.
    * @param price is the price for an item.
    * @param amount is the number of items want to buy/sell. This value is ignore for GLXShip and GLXItem.
    * @param duration is the valid duration time in seconds of the order.
    * @param side is whether buy or sell.
    */
    function createOrder(
        address token,
        address target,
        TargetType targetType,
        uint256 tokenId,
        uint256 price,
        uint32 amount,
        uint64 duration,
        OrderSide side
    ) external returns (uint256 orderId) {
        require(target != address(0x0), "target token address is 0x0");
        require(price > 0, "zero price");
        require(duration >= MIN_ORDER_DURATION, "duration too short");

        if (targetType == TargetType.ERC721) {
            amount = 1;
        } else {
            require(amount > 0, "amount is zero");
        }

        if (side == OrderSide.Sell) {
            bool isValidOwner = false;
            if (targetType == TargetType.ERC721) {
                address tokenOwner = IERC721(target).ownerOf(tokenId);
                isValidOwner = _msgSender() == tokenOwner;
            } else {
                uint256 availableAmount = IERC1155(target).balanceOf(_msgSender(), tokenId);
                isValidOwner = availableAmount >= amount;
            }
            require(isValidOwner, "insufficient balance");
        } else {
            require(token != address(0x0), "not support native token for buying");
            uint256 balance = IERC20(token).balanceOf(_msgSender());
            require(balance >= price * amount, "insufficient balance");
        }

        orderId = ++totalOrders;
        uint64 currentTime = _getBlockTimestamp();

        orders[orderId] = Order({
            maker: _msgSender(),
            token: token,
            target: target,
            targetType: targetType,
            tokenId: tokenId,
            price: price,
            amount: amount,
            remainAmount: amount,
            createdTime: currentTime,
            expiredTime: currentTime + duration,
            side: side
        });
        userOrderIds[_msgSender()].add(orderId);

        emit CreateOrder(
            orderId,
            _msgSender(),
            token,
            target,
            targetType,
            tokenId,
            price,
            amount,
            currentTime,
            currentTime + duration,
            side
        );

        return orderId;
    }

    /**
    * @dev Cancels an existing order.
    */
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(
            (order.maker == _msgSender()) || (owner() == _msgSender()),
            "permission denied"
        );
        require(order.remainAmount > 0, "sold out");
        userOrderIds[order.maker].remove(orderId);
        delete orders[orderId];
        emit CancelOrder(_msgSender(), orderId);
    }

    /**
    * @dev Take an amount of items from an order.
    */
    function takeOrder(uint256 orderId, uint32 amount) external payable {
        Order storage order = orders[orderId];

        require(order.maker != address(0x0), "order not found");
        require(order.maker != _msgSender(), "cannot take own order");
        require(amount > 0, "amount is zero");
        require(order.remainAmount >= amount, "amount is too large");
        require(order.expiredTime >= _getBlockTimestamp(), "order expired");

        uint256 totalPrice = amount * order.price;
        uint256 totalFee = totalPrice * _baseFee / INVERSE_BASIC_POINT;
        order.remainAmount -= amount;

        if (order.remainAmount == 0) {
            userOrderIds[order.maker].remove(orderId);
        }

        address seller;
        address buyer;
        if (order.side == OrderSide.Sell) {
            seller = order.maker;
            buyer = _msgSender();
        } else {
            seller = _msgSender();
            buyer = order.maker;
        }
        emit TakeOrder(orderId, seller, buyer, amount, totalPrice, totalFee);

        if (order.token == address(0x0)) {
            require(msg.value >= totalPrice, "insufficient amount");
            _tokenTransfer(order.token, seller, totalPrice - totalFee);
            // Refund to sender if sender send too much amount.
            if (msg.value > totalPrice) {
                _tokenTransfer(order.token, buyer, msg.value - totalPrice);
            }
        } else {
            IERC20(order.token).safeTransferFrom(buyer, address(this), totalFee);
            IERC20(order.token).safeTransferFrom(buyer, seller, totalPrice - totalFee);
        }

        if (order.targetType == TargetType.ERC721) {
            IERC721(order.target).safeTransferFrom(seller, buyer, order.tokenId);
        } else {
            IERC1155(order.target).safeTransferFrom(seller, buyer, order.tokenId, amount, "");
        }
    }

    /**
    * @dev Returns order's information.
    */
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /**
    * @dev Returns a list of orders' information from {startIndex} to {endIndex}.
    */
    function getOrders(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (Order[] memory) {
        Order[] memory result = new Order[](endIndex - startIndex + 1);
        for (uint256 i = startIndex; i <= endIndex; i++) {
            result[i-startIndex] = orders[i];
        }
        return result;
    }

    function getTotalOrdersByMaker(address maker) external view returns (uint256) {
        return userOrderIds[maker].length();
    }

    function getOrderByMaker(address maker, uint256 i) external view returns (Order memory) {
        uint256 orderId = userOrderIds[maker].at(i);
	return orders[orderId];
    }

    function _tokenTransfer(address token, address to, uint256 amount) internal {
        require(to != address(0x0), "transfer to address 0x0");
        if (token == address(0x0)) {
            (bool success, ) = payable(to).call{ value: amount }('');
            require(success, "fail to transfer native token");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _getBlockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}
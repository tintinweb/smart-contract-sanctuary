// SPDX-License-Identifier: MIT

import ".././interfaces/IERC20.sol";
import ".././interfaces/IAvatarArtExchange.sol";
import ".././core/Runnable.sol";

pragma solidity ^0.8.0;

contract AvatarArtExchange is Runnable, IAvatarArtExchange{
    enum EOrderType{
        Buy, 
        Sell
    }
    
    enum EOrderStatus{
        Open,
        Filled,
        Canceled
    }
    
    struct Order{
        uint256 orderId;
        address owner;
        uint256 price;
        uint256 quantity;
        uint256 filledQuantity;
        uint256 time;
        EOrderStatus status;
        uint256 fee;
    }
    
    uint256 constant public MULTIPLIER = 1000;
    uint256 constant public PRICE_MULTIPLIER = 1000000000000000000;
    
    uint256 public _fee;
    uint256 private _buyOrderIndex = 1;
    uint256 private _sellOrderIndex = 1;
    
    //Checks whether an `token0Address` can be tradable or not
    mapping(address => mapping(address => bool)) public _isTradable;
    
    //Stores users' orders for trading
    mapping(address => mapping(address => Order[])) public _buyOrders;
    mapping(address => mapping(address => Order[])) public _sellOrders;

    mapping(address => uint256) public _systemFees;
    
    constructor(uint256 fee){
        _fee = fee;
    }
    
    /**
     * @dev Get all open orders by `token0Address`
     */ 
    function getOpenOrders(address token0Address, address token1Address, EOrderType orderType) public view returns(Order[] memory){
        Order[] memory orders;
        if(orderType == EOrderType.Buy)
            orders = _buyOrders[token0Address][token1Address];
        else
            orders = _sellOrders[token0Address][token1Address];
        if(orders.length == 0)
            return orders;
        
        uint256 count = 0;
        Order[] memory tempOrders = new Order[](orders.length);
        for(uint256 index = 0; index < orders.length; index++){
            Order memory order = orders[index];
            if(order.status == EOrderStatus.Open){
                tempOrders[count] = order;
                count++;
            }
        }
        
        Order[] memory result = new Order[](count);
        for(uint256 index = 0; index < count; index++){
            result[index] = tempOrders[index];
        }
        
        return result;
    }
    
    /**
     * @dev Get buying orders that can be filled with `price` of `token0Address`
     */ 
    function getOpenBuyOrdersForPrice(address token0Address, address token1Address, uint256 price) public view returns(Order[] memory){
        Order[] memory orders = _buyOrders[token0Address][token1Address];
        if(orders.length == 0)
            return orders;
        
        uint256 count = 0;
        Order[] memory tempOrders = new Order[](orders.length);
        for(uint256 index = 0; index < orders.length; index++){
            Order memory order = orders[index];
            if(order.status == EOrderStatus.Open && order.price >= price){
                tempOrders[count] = order;
                count++;
            }
        }
        
        Order[] memory result = new Order[](count);
        for(uint256 index = 0; index < count; index++){
            result[index] = tempOrders[index];
        }
        
        return result;
    }
    
    function getOrders(address token0Address, address token1Address, EOrderType orderType) public view returns(Order[] memory){
        return orderType == EOrderType.Buy ? _buyOrders[token0Address][token1Address] : _sellOrders[token0Address][token1Address];
    }
    
    function getUserOrders(address token0Address, address token1Address, address account, EOrderType orderType) public view returns(Order[] memory){
        Order[] memory orders;
        if(orderType == EOrderType.Buy)
            orders = _buyOrders[token0Address][token1Address];
        else
            orders = _sellOrders[token0Address][token1Address];
        if(orders.length == 0)
            return orders;
        
        uint256 count = 0;
        Order[] memory tempOrders = new Order[](orders.length);
        for(uint256 index = 0; index < orders.length; index++){
            Order memory order = orders[index];
            if(order.owner == account){
                tempOrders[count] = order;
                count++;
            }
        }
        
        Order[] memory result = new Order[](count);
        for(uint256 index = 0; index < count; index++){
            result[index] = tempOrders[index];
        }
        
        return result;
    }
    
    /**
     * @dev Get selling orders that can be filled with `price` of `token0Address`
     */ 
    function getOpenSellOrdersForPrice(address token0Address, address token1Address, uint256 price) public view returns(Order[] memory){
        Order[] memory orders = _sellOrders[token0Address][token1Address];
        if(orders.length == 0)
            return orders;
        
        uint256 count = 0;
        Order[] memory tempOrders = new Order[](orders.length);
        for(uint256 index = 0; index < orders.length; index++){
            Order memory order = orders[index];
            if(order.status == EOrderStatus.Open && order.price <= price){
                tempOrders[count] = order;
                count++;
            }
        }
        
        Order[] memory result = new Order[](count);
        for(uint256 index = 0; index < count; index++){
            result[index] = tempOrders[index];
        }
        
        return result;
    }
    
    function setFee(uint256 fee) public onlyOwner{
        _fee = fee;
    }
    
   /**
     * @dev Allow or disallow `token0Address` to be traded on AvatarArtOrderBook
    */
    function toogleTradableStatus(address token0Address, address token1Address) public override onlyOwner returns(bool){
        _isTradable[token0Address][token1Address] = !_isTradable[token0Address][token1Address];
        return true;
    }
    
    /**
     * @dev See {IAvatarArtOrderBook.buy}
     * 
     * IMPLEMENTATION
     *    1. Validate requirements
     *    2. Process buy order 
     */ 
    function buy(address token0Address, address token1Address, uint256 price, uint256 quantity) public override isRunning returns(bool){
        require(_isTradable[token0Address][token1Address], "Can not tradable");
        require(price > 0 && quantity > 0, "Zero input");
        
        uint256 matchedQuantity = 0;
        uint256 needToMatchedQuantity = quantity;
        
        Order memory order = Order({
            orderId: _buyOrderIndex,
            owner: _msgSender(),
            price: price,
            quantity: quantity,
            filledQuantity: 0,
            time: _now(),
            fee: _fee,
            status: EOrderStatus.Open
        });
        
        uint256 totalPaidAmount = 0;
        //Get all open sell orders that are suitable for `price`
        Order[] memory matchedOrders = getOpenSellOrdersForPrice(token0Address, token1Address, price);
        if (matchedOrders.length > 0){
            matchedQuantity = 0;
            for(uint256 index = 0; index < matchedOrders.length; index++)
            {
                Order memory matchedOrder = matchedOrders[index];
                uint256 matchedOrderRemainQuantity = matchedOrder.quantity - matchedOrder.filledQuantity;
                uint256 currentFilledQuantity = 0;
                if (needToMatchedQuantity < matchedOrderRemainQuantity)     //Filled
                {
                    matchedQuantity = quantity;
                    
                    //Update matchedOrder matched quantity
                    _increaseFilledQuantity(token0Address, token1Address, EOrderType.Sell, matchedOrder.orderId, needToMatchedQuantity);
                    
                    currentFilledQuantity = needToMatchedQuantity;
                    needToMatchedQuantity = 0;
                }
                else
                {
                    matchedQuantity += matchedOrderRemainQuantity;
                    needToMatchedQuantity -= matchedOrderRemainQuantity;
                    currentFilledQuantity = matchedOrderRemainQuantity;

                    //Update matchedOrder to completed
                    _updateOrderToBeFilled(token0Address, token1Address, matchedOrder.orderId, EOrderType.Sell);
                }

                totalPaidAmount += currentFilledQuantity * matchedOrder.price / PRICE_MULTIPLIER;
                
                //Save fee
                _increaseFeeReward(token0Address, currentFilledQuantity * _fee / 100 / MULTIPLIER);
                
                //Increase buy user token0 balance
                IERC20(token0Address).transfer(_msgSender(), currentFilledQuantity * (1 - _fee / 100 / MULTIPLIER));

                //Save fee
                _increaseFeeReward(token1Address, currentFilledQuantity * matchedOrder.price * matchedOrder.fee / 100 / MULTIPLIER / PRICE_MULTIPLIER);
                
                //Increase sell user token1 balance
                IERC20(token1Address).transfer(matchedOrder.owner, currentFilledQuantity * matchedOrder.price * (1 - matchedOrder.fee / 100 / MULTIPLIER) / PRICE_MULTIPLIER);

                //Create matched order
                emit OrderFilled(order.orderId, matchedOrder.orderId, matchedOrder.price, currentFilledQuantity, _now(), 0);
                
                if (needToMatchedQuantity == 0)
                    break;
            }
        }

        totalPaidAmount += price * (quantity - matchedQuantity) / PRICE_MULTIPLIER;
        if(totalPaidAmount > 0)
            IERC20(token1Address).transferFrom(_msgSender(), address(this), totalPaidAmount);

        //Create order
        order.filledQuantity = matchedQuantity;
        if(order.filledQuantity != quantity)
            order.status = EOrderStatus.Open;
        else
            order.status = EOrderStatus.Filled;
        _buyOrders[token0Address][token1Address].push(order);
        
        _buyOrderIndex++;
        emit OrderCreated(_now(), _msgSender(), token0Address, token1Address, EOrderType.Buy, price, quantity, order.orderId, _fee);
        return true;
    }
    
    /**
     * @dev Sell `token0Address` with `price` and `amount`
     */ 
    function sell(address token0Address, address token1Address, uint256 price, uint256 quantity) public override isRunning returns(bool){
        require(_isTradable[token0Address][token1Address], "Can not tradable");
        require(price > 0 && quantity > 0, "Zero input");
        
        uint256 matchedQuantity = 0;
        uint256 needToMatchedQuantity = quantity;

        Order memory order = Order({
            orderId: _sellOrderIndex,
            owner: _msgSender(),
            price: price,
            quantity: quantity,
            filledQuantity: 0,
            time: _now(),
            fee: _fee,
            status: EOrderStatus.Open
        });
        
        IERC20(token0Address).transferFrom(_msgSender(), address(this), quantity);
        Order[] memory matchedOrders = getOpenBuyOrdersForPrice(token0Address, token1Address, price);        
        if (matchedOrders.length > 0){
            matchedQuantity = 0;
            for(uint index = 0; index < matchedOrders.length; index++)
            {
                Order memory matchedOrder = matchedOrders[index];
                uint256 matchedOrderRemainQuantity = matchedOrder.quantity - matchedOrder.filledQuantity;
                uint256 currentMatchedQuantity = 0;
                if (needToMatchedQuantity < matchedOrderRemainQuantity)     //Filled
                {
                    matchedQuantity = quantity;
                    
                     //Update matchedOrder matched quantity
                    _increaseFilledQuantity(token0Address, token1Address, EOrderType.Buy, matchedOrder.orderId, needToMatchedQuantity);

                    currentMatchedQuantity = needToMatchedQuantity;
                    needToMatchedQuantity = 0;
                }
                else
                {
                    matchedQuantity += matchedOrderRemainQuantity;
                    needToMatchedQuantity -= matchedOrderRemainQuantity;
                    currentMatchedQuantity = matchedOrderRemainQuantity;

                    //Update matchedOrder to completed
                    _updateOrderToBeFilled(token0Address, token1Address, matchedOrder.orderId, EOrderType.Buy);
                }
                
                //Save fee
                _increaseFeeReward(token0Address, currentMatchedQuantity * _fee / 100 / MULTIPLIER);
                
                //Increase buy user token0 balance
                IERC20(token0Address).transfer(matchedOrder.owner, currentMatchedQuantity * (1 - _fee / 100 / MULTIPLIER));
                
                //Save fee
                _increaseFeeReward(token1Address, currentMatchedQuantity * matchedOrder.price * _fee / 100 / MULTIPLIER / PRICE_MULTIPLIER);

                //Increase sell user token1 balance
                IERC20(token1Address).transfer(_msgSender(), currentMatchedQuantity * matchedOrder.price * (1 - _fee / 100 / MULTIPLIER) / PRICE_MULTIPLIER);

                emit OrderFilled(matchedOrder.orderId, order.orderId, matchedOrder.price, currentMatchedQuantity, _now(), 1);

                if (needToMatchedQuantity == 0)
                    break;
            }
        }

        order.filledQuantity = matchedQuantity;
        if(order.filledQuantity != quantity)
            order.status = EOrderStatus.Open;
        else
            order.status = EOrderStatus.Filled;
       
        _sellOrders[token0Address][token1Address].push(order);

        _sellOrderIndex++;
        emit OrderCreated(_now(), _msgSender(), token0Address, token1Address, EOrderType.Sell, price, quantity, order.orderId, _fee);
        return true;
    }
    
    /**
     * @dev Cancel an open trading order for `token0Address` by `orderId`
     */ 
    function cancel(address token0Address, address token1Address, uint256 orderId, uint256 orderType) public override isRunning returns(bool){
        EOrderType eOrderType = EOrderType(orderType);
        require(eOrderType == EOrderType.Buy || eOrderType == EOrderType.Sell,"Invalid order type");
        
        if(eOrderType == EOrderType.Buy)
            return _cancelBuyOrder(token0Address, token1Address, orderId);
        else
            return _cancelSellOrder(token0Address, token1Address, orderId);
    }

    function withdrawFee(address[] memory tokenAddresses, address receipent) external onlyOwner{
        require(tokenAddresses.length > 0);
        for(uint256 index = 0; index < tokenAddresses.length; index++){
            if(_systemFees[tokenAddresses[index]] > 0){
                IERC20(tokenAddresses[index]).transfer(receipent, _systemFees[tokenAddresses[index]]);
                _systemFees[tokenAddresses[index]] = 0;
            }
        }
    }
    
    function _increaseFeeReward(address tokenAddress, uint256 feeAmount) internal{
        _systemFees[tokenAddress] += feeAmount;
    }
    
    /**
     * @dev Cancel buy order
     */ 
    function _cancelBuyOrder(address token0Address, address token1Address, uint256 orderId) internal returns(bool){
        for(uint256 index = 0; index < _buyOrders[token0Address][token1Address].length; index++){
            Order storage order = _buyOrders[token0Address][token1Address][index];
            if(order.orderId == orderId){
                require(order.owner == _msgSender(), "Forbidden");
                require(order.status == EOrderStatus.Open, "Order is not open");
                
                order.status = EOrderStatus.Canceled;
                IERC20(token1Address).transfer(order.owner, (order.quantity - order.filledQuantity) * order.price);
                emit OrderCanceled(_now(), orderId);
                
                break;
            }
        }
        return true;
    }
    
    /**
     * @dev Cancel sell order
     */ 
    function _cancelSellOrder(address token0Address, address token1Address, uint256 orderId) internal returns(bool){
        for(uint256 index = 0; index < _sellOrders[token0Address][token1Address].length; index++){
            Order storage order = _sellOrders[token0Address][token1Address][index];
            if(order.orderId == orderId){
                require(order.owner == _msgSender(), "Forbidden");
                require(order.status == EOrderStatus.Open, "Order is not open");
                
                order.status = EOrderStatus.Canceled;
                IERC20(token0Address).transfer(order.owner, order.quantity - order.filledQuantity);
                emit OrderCanceled(_now(), orderId);
                break;
            }
        }
        return true;
    }
    
    /**
     * @dev Increase filled quantity of specific order
     */ 
    function _increaseFilledQuantity(address token0Address, address token1Address, EOrderType orderType, uint256 orderId, uint256 quantity) internal {
        if(orderType == EOrderType.Buy){
            for(uint256 index = 0; index < _buyOrders[token0Address][token1Address].length; index++){
                Order storage order = _buyOrders[token0Address][token1Address][index];
                if(order.orderId == orderId){
                    order.filledQuantity += quantity;
                    break;
                }
            }
        }else{
            for(uint256 index = 0; index < _sellOrders[token0Address][token1Address].length; index++){
                Order storage order = _buyOrders[token0Address][token1Address][index];
                if(order.orderId == orderId){
                    order.filledQuantity += quantity;
                    break;
                }
            }
        }
    }
    
    /**
     * @dev Update the order is filled all
     */ 
    function _updateOrderToBeFilled(address token0Address, address token1Address, uint256 orderId, EOrderType orderType) internal{
        if(orderType == EOrderType.Buy){
            for(uint256 index = 0; index < _buyOrders[token0Address][token1Address].length; index++){
                Order storage order = _buyOrders[token0Address][token1Address][index];
                if(order.orderId == orderId){
                    order.filledQuantity == order.quantity;
                    order.status = EOrderStatus.Filled;
                    break;
                }
            }
        }else{
            for(uint256 index = 0; index < _sellOrders[token0Address][token1Address].length; index++){
                Order storage order = _buyOrders[token0Address][token1Address][index];
                if(order.orderId == orderId){
                    order.filledQuantity == order.quantity;
                    order.status = EOrderStatus.Filled;
                    break;
                }
            }
        }
    }
    
    event OrderCreated(uint256 time, address account, 
        address token0Address, address token1Address, EOrderType orderType, uint256 price, uint256 quantity, uint256 orderId, uint256 fee);
    event OrderCanceled(uint256 time, uint256 orderId);
    event OrderFilled(uint256 buyOrderId, uint256 sellOrderId, uint256 price, uint256 quantity, uint256 time, uint256 orderType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function _now() internal view returns(uint){
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    address internal _newRequestingOwner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function requestChangeOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        _newRequestingOwner = newOwner;
    }
    
    function approveToBeOwner() external{
        require(_newRequestingOwner != address(0), "Zero address");
        require(_msgSender() == _newRequestingOwner, "Forbidden");
        
        address oldOwner = _owner;
        _owner = _newRequestingOwner;
        
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Runnable is Ownable {
    
    modifier isRunning{
        require(_isRunning, "Contract is paused");
        _;
    }
    
    bool internal _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunningStatus() external onlyOwner{
        _isRunning = !_isRunning;
    }

    function getRunningStatus() external view returns(bool){
        return _isRunning;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAvatarArtExchange{
    /**
     * @dev Allow or disallow `token0Address` to be traded on AvatarArtOrderBook
    */
    function toogleTradableStatus(address token0Address, address token1Address) external returns(bool);
    
    /**
     * @dev Buy `token0Address` with `price` and `amount`
     */ 
    function buy(address token0Address, address token1Address, uint256 price, uint256 amount) external returns(bool);
    
    /**
     * @dev Sell `token0Address` with `price` and `amount`
     */ 
    function sell(address token0Address, address token1Address, uint256 price, uint256 amount) external returns(bool);
    
    /**
     * @dev Cancel an open trading order for `token0Address` by `orderId`
     */ 
    function cancel(address token0Address, address token1Address, uint256 orderId, uint256 orderType) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


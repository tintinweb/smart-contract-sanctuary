/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IAvatarArtExchange{
    /**
     * @dev Allow or disallow `token0Address` to be traded on AvatarArtOrderBook
    */
    function setPairInfo(address token0Address, address token1Address, bool tradable, uint256 minPrice, uint256 maxPrice) external returns(bool);
    
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function _now() internal view virtual returns(uint256){
        return block.timestamp;
    }
}

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function setOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
}

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
}

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

    struct PairInfo{
        bool isTradable;
        uint256 minPrice;
        uint256 maxPrice;
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
    uint256 constant public PRICE_MULTIPLIER = 1000000;
    
    uint256 public _fee;
    uint256 private _orderIndex = 1;
    
    //PairInfo of token0Address and token1Address: Information about tradable, min price and max price
    //Token0Address => Token1Address => PairInfo
    mapping(address => mapping(address => PairInfo)) public _pairInfos;
    
    //Stores users' orders for trading
    //Token0Address => Token1Address => Order list
    mapping(address => mapping(address => Order[])) public _buyOrders;

    //Token0Address => Token1Address => Order list
    mapping(address => mapping(address => Order[])) public _sellOrders;

    //Fee total that platform receives from transactions
    //TokenAddress => Fee amount
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

    /**
     * @dev Check whether the pair can tradable
     */ 
    function isTradable(address token0Address, address token1Address, uint256 price) public view returns(bool){
        PairInfo memory pairInfo = _pairInfos[token0Address][token1Address];
        if(!pairInfo.isTradable)
            return false;

        if(pairInfo.minPrice > 0 && pairInfo.minPrice > price)
            return false;
        
        if(pairInfo.maxPrice > 0 && pairInfo.maxPrice < price)
            return false;

        return true;
    }
    
    function setFee(uint256 fee) public onlyOwner{
        _fee = fee;
    }
    
   /**
     * @dev Allow or disallow `token0Address` to be traded on AvatarArtOrderBook
    */
    function setPairInfo(address token0Address, address token1Address, bool tradable, uint256 minPrice, uint256 maxPrice) public override onlyOwner returns(bool){
        _pairInfos[token0Address][token1Address] = PairInfo({
            isTradable: tradable,
            minPrice: minPrice,
            maxPrice: maxPrice
        });
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
        require(isTradable(token0Address, token1Address, price), "Can not tradable");
        require(price > 0 && quantity > 0, "Zero input");

        uint256 allTotalPaidAmount = price * quantity / PRICE_MULTIPLIER;
        IERC20(token1Address).transferFrom(_msgSender(), address(this), allTotalPaidAmount);
        
        Order memory order = Order({
            orderId: _orderIndex,
            owner: _msgSender(),
            price: price,
            quantity: quantity,
            filledQuantity: 0,
            time: _now(),
            fee: _fee,
            status: EOrderStatus.Open
        });
        
        uint256 totalPaidAmount = 0;
        uint256 matchedQuantity = 0;

        //Get all open sell orders that are suitable for `price`
        Order[] memory matchedOrders = getOpenSellOrdersForPrice(token0Address, token1Address, price);
        if (matchedOrders.length > 0){
            uint256 needToMatchedQuantity = quantity;
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
                emit OrderFilled(order.orderId, matchedOrder.orderId, matchedOrder.price, currentFilledQuantity, _now(), EOrderType.Buy);
                
                if (needToMatchedQuantity == 0)
                    break;
            }
        }

        //Payback token for user
        totalPaidAmount += price * (quantity - matchedQuantity) / PRICE_MULTIPLIER;
        if(totalPaidAmount < allTotalPaidAmount)
            IERC20(token1Address).transfer(_msgSender(), allTotalPaidAmount - totalPaidAmount);

        //Create order
        order.filledQuantity = matchedQuantity;
        if(order.filledQuantity != quantity)
            order.status = EOrderStatus.Open;
        else
            order.status = EOrderStatus.Filled;
        _buyOrders[token0Address][token1Address].push(order);
        
        _orderIndex++;
        emit OrderCreated(_now(), _msgSender(), token0Address, token1Address, EOrderType.Buy, price, quantity, order.orderId, _fee);
        return true;
    }
    
    /**
     * @dev Sell `token0Address` with `price` and `amount`
     */ 
    function sell(address token0Address, address token1Address, uint256 price, uint256 quantity) public override isRunning returns(bool){
        require(isTradable(token0Address, token1Address, price), "Can not tradable");
        require(price > 0 && quantity > 0, "Zero input");

        IERC20(token0Address).transferFrom(_msgSender(), address(this), quantity);
        
        Order memory order = Order({
            orderId: _orderIndex,
            owner: _msgSender(),
            price: price,
            quantity: quantity,
            filledQuantity: 0,
            time: _now(),
            fee: _fee,
            status: EOrderStatus.Open
        });

        uint256 matchedQuantity = 0;
        
        Order[] memory matchedOrders = getOpenBuyOrdersForPrice(token0Address, token1Address, price);        
        if (matchedOrders.length > 0){
            uint256 needToMatchedQuantity = quantity;
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

                emit OrderFilled(matchedOrder.orderId, order.orderId, matchedOrder.price, currentMatchedQuantity, _now(), EOrderType.Sell);

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

        _orderIndex++;
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
            address tokenAddress = tokenAddresses[index];
            if(_systemFees[tokenAddress] > 0){
                IERC20(tokenAddress).transfer(receipent, _systemFees[tokenAddress]);
                _systemFees[tokenAddress] = 0;
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
                IERC20(token1Address).transfer(order.owner, (order.quantity - order.filledQuantity) * order.price / PRICE_MULTIPLIER);
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
    event OrderFilled(uint256 buyOrderId, uint256 sellOrderId, uint256 price, uint256 quantity, uint256 time, EOrderType orderType);
}
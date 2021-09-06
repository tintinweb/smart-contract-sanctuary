/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) return a;
        return b;
    }
}

library ArrayUint256 {

    function push(uint256[] storage data, uint256 v) internal
    {
        require(v > 0, "push 0 is prohibited");

        bool added = false;
        for (uint i=0; i<data.length; i++)
        {
            if (data[i] == 0)
            {
                data[i] = v;
                added = true;
                break;
            }
        }
        if (added == false)
        {
            data.push(v);
        }
    }

    function remove(uint256[] storage data, uint256 v) internal
    {
        require(v > 0, "remove 0 is prohibited");

        for (uint i=data.length-1; i>=0; i--)
        {
            if (data[i] == v)
            {
                data[i] = 0;
                break;
            }
        }

        while (true)
        {
            if (data.length == 0)
                break;
            if (data[data.length-1] > 0)
                break;
            data.pop();
        }
    }

    // 升序
    function ascendingInsert(uint256[] storage data, uint256 price) internal
    {
        if (data.length == 0)
        {
            data.push(price);
        }
        else
        {
            data.push(0);
            uint i = data.length - 1;
            while (true)
            {
                if (i > 0)
                    i--;
                if (data[i] < price)
                {
                    data[i+1] = price;
                    break;
                }
                data[i+1] = data[i];
                if (i == 0)
                {
                    data[i] = price;
                    break;
                }
            }
        }
    }
    // 降序
    function descendingInsert(uint256[] storage data, uint256 price) internal
    {
        if (data.length == 0)
        {
            data.push(price);
        }
        else
        {
            data.push(0);
            uint i = data.length - 1;
            while (true)
            {
                if (i > 0)
                    i--;
                if (data[i] > price)
                {
                    data[i+1] = price;
                    break;
                }
                data[i+1] = data[i];
                if (i == 0)
                {
                    data[i] = price;
                    break;
                }
            }
        }
    }
}

interface OrderManager {

    function createOrder(address _tokenContract, address _sender, uint256 _price, uint256 _token, uint256 _usdt, uint8 _type) external returns (uint256 _orderId);

    function insertOrder(address _tokenContract, uint256 _orderId, address _sender) external returns (bool _flag);

    function removeOrder(address _tokenContract, uint256 _orderId, address _sender) external returns (bool _flag);

    function handleMatchOrder(address _tokenContract, uint256 _orderId) external;
    
    function getOrder(address _tokenContract, uint256 _orderId) external view returns (
        uint256 orderId,
        uint256 price,
        uint256 tokenTotal,
        uint256 tokenSurplus,
        uint256 usdtTotal,
        uint256 usdtSurplus,
        uint256 createnTime,
        uint256 endTime,
        address sender,
        uint8 orderType,
        uint8 status
    );
}

contract OrderManagerReal is OrderManager {

    address USDT = 0xa8557Ea8D2A59dE104B4aE5274F05A1a3ee862D3;

    // uint256 moleculeFee = 2;
    // uint256 denominatorFee = 1000;

    enum OrderType { Buy, Sell } // 枚举
    enum OrderStatus { Waiting, Finished, Cancelled } // 枚举

    struct Order {
        uint256 orderId;                    // 订单号
        uint256 price;                      // 挂单价格
        uint256 tokenTotal;                 // token总量
        uint256 tokenSurplus;               // token剩余未成交
        uint256 usdtTotal;                  // usdt总量
        uint256 usdtSurplus;                // usdt剩余未成交
        uint256 createnTime;                // 发起时间
        uint256 endTime;                    // 结束时间
        OrderType orderType;                // 1. 买单 0 1
        OrderStatus status;                 // 2. 委托中0 已成交1 已撤回2
        address sender;                     // 发起者
    }

    struct Match {
        uint256 matchId;                    // id
        uint256 buyOrderId;                 // 委托方
        uint256 sellOrderId;                // 成交方
        uint256 price;                      // 成交价格
        uint256 tokenDeal;                  // token数量
        uint256 usdtDeal;                   // usdt数量
        uint256 tokenFee;                   // token fee
        uint256 usdtFee;                    // usdt fee
        uint256 time;                        // 时间
    }

    struct Data {
        uint256  autoIncrement;
        uint256  autoMatchId;

        mapping(uint256 => Order) orderList;                       // 订单仓库

        mapping(uint256 => uint256[]) orderMatchingList;           // 订单撮合记录

        mapping(address => uint256[]) orderUnmatchedList;          // 用户未完全撮合de订单
        mapping(address => uint256[]) orderCanceledList;             // 用户撤销de订单
        mapping(address => uint256[]) orderFinishedList;            // 用户已成交de订单

        mapping(uint256 => uint256[])  orderBuyMap;                 // 买单   价格 => 订单号[]
        uint256[]                      orderBuyList;                // 买单   价格[]

        mapping(uint256 => uint256[])  orderSellMap;                // 买单   价格 => 订单号[]
        uint256[]                      orderSellList;               // 卖单   价格[]

        mapping(uint256 => Match) matchMap;                        // 撮合仓库

    }

    mapping(address => Data) public map;


    function getOrder(address _tokenContract, uint256 _orderId) external override view returns (
        uint256 orderId,
        uint256 price,
        uint256 tokenTotal,
        uint256 tokenSurplus,
        uint256 usdtTotal,
        uint256 usdtSurplus,
        uint256 createnTime,
        uint256 endTime,
        address sender,
        uint8 orderType,
        uint8 status
    )
    {
        Order memory _order = map[_tokenContract].orderList[_orderId];

        orderId = _orderId;
        price = _order.price;
        tokenTotal = _order.tokenTotal;
        usdtTotal = _order.usdtTotal;
        tokenSurplus = _order.tokenSurplus;
        usdtSurplus = _order.usdtSurplus;
        createnTime = _order.createnTime;
        endTime = _order.endTime;
        sender = _order.sender;
        orderType = uint8(_order.orderType);
        status = uint8(_order.status);
    }

    function getOrderPriceList(address _tokenContract) external view returns (
        uint256[] memory orderBuyList,
        uint256[] memory orderSellList
    )
    {
        Data storage _data = map[_tokenContract];
        return (_data.orderBuyList, _data.orderSellList);
    }

    function getOrderPriceOrderId(address _tokenContract, uint256 _price) external view returns (
        uint256[] memory orderBuyIdList,
        uint256[] memory orderSellIdList
    )
    {
        Data storage _data = map[_tokenContract];
        return (_data.orderBuyMap[_price], _data.orderSellMap[_price]);
    }

    function getMatch(address _tokenContract, uint256 _matchId) external view returns (
        uint256 matchId,
        uint256 buyOrderId,
        uint256 sellOrderId,
        uint256 price,
        uint256 tokenDeal,
        uint256 usdtDeal,
        uint256 tokenFee,
        uint256 usdtFee,
        uint256 time
    )
    {
        Match memory _match = map[_tokenContract].matchMap[_matchId];

        matchId = _match.matchId;
        buyOrderId = _match.buyOrderId;
        sellOrderId = _match.sellOrderId;
        price = _match.price;
        tokenDeal = _match.tokenDeal;
        usdtDeal = _match.usdtDeal;
        tokenFee = _match.tokenFee;
        usdtFee = _match.usdtFee;
        time = _match.time;
    }

    function getOrderMatching(address _tokenContract, uint256 _orderId) public view returns (uint256[] memory matchingList)
    {
        return map[_tokenContract].orderMatchingList[_orderId];
    }

    function setOrderStatus(address _tokenContract, uint256 _orderId, OrderStatus _status) public
    {
        Data storage data = map[_tokenContract];
        Order storage order = data.orderList[_orderId];

        require(order.status != _status && order.status == OrderStatus.Waiting, "Do not modify repeatedly");

        order.status = _status;
        order.endTime = block.timestamp;
        if (order.status == OrderStatus.Cancelled)
        {
            // 撤回状态

            // 从 待撮合列表里移除
            ArrayUint256.remove(data.orderUnmatchedList[order.sender], _orderId);
            // 添加到 用户撤回订单列表
            ArrayUint256.push(data.orderCanceledList[order.sender], _orderId);
        }
        else if (order.status == OrderStatus.Finished)
        {
            // 完成状态

            // 从 待撮合列表里移除
            ArrayUint256.remove(data.orderUnmatchedList[order.sender], _orderId);
            // 添加到 用户撤回订单列表
            ArrayUint256.push(data.orderFinishedList[order.sender], _orderId);
        }
    }

    function createOrder(address _tokenContract, address _sender, uint256 _price, uint256 _token, uint256 _usdt, uint8 _type) external override returns (uint256 _orderId)
    {
        require(_type == 0 || _type == 1, "_status Parameter exception");

        Data storage data = map[_tokenContract];

        data.autoIncrement++;

        uint256 orderId = data.autoIncrement;
        OrderType orderType = OrderType.Buy;
        if (_type == 1) orderType = OrderType.Sell;

        Order memory order = Order({
             orderId:orderId,
             price:_price,
             tokenTotal:_token,
             tokenSurplus:_token,
             usdtTotal:_usdt,
             usdtSurplus:_usdt,
             createnTime:block.timestamp,
             endTime:0,
             sender:_sender,
             orderType:orderType,
             status:OrderStatus.Waiting
        });

        data.orderList[orderId] = order;

        return orderId;
    }

    // 插入订单
    function insertOrder(address _tokenContract, uint256 _orderId, address _sender) external override returns (bool _flag)
    {
        Data storage data = map[_tokenContract];
        Order storage order = data.orderList[_orderId];

        require(order.status != OrderStatus.Cancelled, "Abnormal order status");

        if (order.status == OrderStatus.Waiting)
        {
            require(order.sender == _sender, "Illegal order");

            if (order.orderType == OrderType.Buy)
            {
                // 添加到 待撮合列表里
                ArrayUint256.push(data.orderUnmatchedList[_sender], _orderId);
                // 买盘订单列表 升序
                if (data.orderBuyMap[order.price].length == 0)
                {
                     ArrayUint256.ascendingInsert(data.orderBuyList, order.price);
                }
                ArrayUint256.push(data.orderBuyMap[order.price], _orderId);
            }
            else if (order.orderType == OrderType.Sell)
            {
                // 添加到 待撮合列表里
                ArrayUint256.push(data.orderUnmatchedList[_sender], _orderId);
                // 卖盘订单列表 降序
                if (data.orderSellMap[order.price].length == 0)
                {
                    ArrayUint256.descendingInsert(data.orderSellList, order.price);
                }
                ArrayUint256.push(data.orderSellMap[order.price], _orderId);
            }
            return true;
        }

        return false;
    }

    // 移除订单
    function removeOrder(address _tokenContract, uint256 _orderId, address _sender) external override returns (bool _flag)
    {
        Data storage data = map[_tokenContract];
        Order storage order = data.orderList[_orderId];

        require(order.sender == _sender, "Illegal order");

        if (order.status != OrderStatus.Waiting)
            return false;

        // 订单状态
        this.setOrderStatus(_tokenContract, _orderId, OrderStatus.Cancelled);

        if (order.orderType == OrderType.Buy)
        {
            // 买盘订单列表
            ArrayUint256.remove(data.orderBuyMap[order.price], _orderId);
            if (data.orderBuyMap[order.price].length == 0)
            {
                ArrayUint256.remove(data.orderBuyList, order.price);
            }
            return true;
        }
        else if (order.orderType == OrderType.Sell)
        {
            // 卖盘订单列表
            ArrayUint256.remove(data.orderSellMap[order.price], _orderId);
            if (data.orderSellMap[order.price].length == 0)
            {
                ArrayUint256.remove(data.orderSellList, order.price);
            }
            return true;
        }
        return false;
    }

    // 创建撮合对
    function createMatch(address _tokenContract, uint256 _buyOrderId, uint256 _sellOrderId, uint256 _price, uint256 _tokenDeal, uint256 _usdtDeal) public returns (uint256 _matchId)
    {
        require(_tokenDeal * _price == _usdtDeal, "parameter exception");

        Data storage data = map[_tokenContract];

                            data.autoMatchId++;


        uint256 tokenFee = _tokenDeal * 2 / 1000;
        uint256 usdtFee = _usdtDeal * 2 / 1000;
        uint256 tokenDeal = _tokenDeal - tokenFee;
        uint256 usdtDeal = _usdtDeal - usdtFee;

        uint256 matchId = data.autoMatchId;

        Match memory order = Match({
             matchId:matchId,
             buyOrderId:_buyOrderId,
             sellOrderId:_sellOrderId,
             price:_price,
             tokenDeal:tokenDeal,
             usdtDeal:usdtDeal,
             tokenFee:tokenFee,
             usdtFee:usdtFee,
             time:block.timestamp
        });

        data.matchMap[matchId] = order;

        return matchId;
    }

    function handleMatchOrder(address _tokenContract, uint256 _orderId) external override
    {
        Data storage data = map[_tokenContract];
        Order storage order = data.orderList[_orderId];

        // mapping(address => uint256) storage finance;
        uint256 amount = 0;

        if (order.orderType == OrderType.Buy)
        {
            if (data.orderSellList.length > 0)
            {
                for (uint i=data.orderSellList.length-1; i>=0; i--)
                {
                    if (order.price < data.orderSellList[i])
                        break;

                    uint256 price = data.orderSellList[i];
                    uint256[] storage orderList = data.orderSellMap[price];

                    for (uint j=orderList.length-1; j>=0; j--)
                    {
                        uint256 matchOrderId = orderList[j];
                        Order storage matchOrder = data.orderList[matchOrderId];

                        uint256 usdt = SafeMath.min(order.usdtSurplus, matchOrder.tokenSurplus * matchOrder.price);
                        uint256 token = SafeMath.min(order.usdtSurplus / matchOrder.price, matchOrder.tokenSurplus);

                        // 创建撮合记录
                        uint256 matchId = this.createMatch(_tokenContract, order.orderId, matchOrder.orderId, price, token, usdt);

                        // 订单添加撮合记录
                        order.usdtSurplus -= usdt;
                        order.tokenSurplus += data.matchMap[matchId].tokenDeal;
                        matchOrder.tokenSurplus -= token;
                        matchOrder.usdtSurplus += data.matchMap[matchId].usdtDeal;

                        data.orderMatchingList[order.orderId].push(matchId);
                        data.orderMatchingList[matchOrder.orderId].push(matchId);

                        // 财务计算
                        // finance[matchOrder.sender] += data.matchMap[matchId].usdtDeal;
                        amount += data.matchMap[matchId].tokenDeal;

                        IERC20(USDT).transfer(
                            matchOrder.sender,
                            data.matchMap[matchId].usdtDeal
                        );

                        if (matchOrder.tokenSurplus == 0)
                        {
                            // 完成的订单 从挂单池移除
                            data.orderSellMap[price].pop();

                            // 订单状态
                            this.setOrderStatus(_tokenContract, matchOrder.orderId, OrderStatus.Finished);
                        }

                        if (order.usdtSurplus == 0)
                        {
                            // 撮合完成

                            // 订单状态
                            order.status = OrderStatus.Finished;
                            break;
                        }
                    }
                    // 该价格订单池消灭
                    if (data.orderSellMap[price].length == 0)
                    {
                        data.orderSellList.pop();
                        delete data.orderSellMap[price];
                    }
                    if (order.usdtSurplus == 0)
                    {
                        break;
                    }
                    if (amount > 0)
                    {
                        IERC20(_tokenContract).transfer(
                        order.sender,
                        amount);
                    }
                }
            }
        }
        else if (order.orderType == OrderType.Sell)
        {
            if (data.orderBuyList.length > 0)
            {
                for (uint i=data.orderBuyList.length-1; i>=0; i--)
                {
                    if (order.price > data.orderBuyList[i])
                        break;

                    uint256 price = data.orderBuyList[i];
                    uint256[] storage orderList = data.orderBuyMap[price];

                    for (uint j=orderList.length-1; j>=0; j--)
                    {
                        uint256 matchOrderId = orderList[j];
                        Order storage matchOrder = data.orderList[matchOrderId];

                        uint256 token = SafeMath.min(matchOrder.usdtSurplus / order.price, order.tokenSurplus);
                        uint256 usdt = SafeMath.min(matchOrder.usdtSurplus, order.tokenSurplus * order.price);

                        // 创建撮合记录
                        uint256 matchId = this.createMatch(_tokenContract, matchOrder.orderId, order.orderId, price, token, usdt);

                        // 订单添加撮合记录
                        order.tokenSurplus -= token;
                        order.usdtSurplus += data.matchMap[matchId].usdtDeal;

                        matchOrder.usdtSurplus -= usdt;
                        matchOrder.tokenSurplus += data.matchMap[matchId].tokenDeal;


                        data.orderMatchingList[order.orderId].push(matchId);
                        data.orderMatchingList[matchOrder.orderId].push(matchId);

                        // 财务计算
                        // finance[matchOrder.sender] += data.matchMap[matchId].tokenDeal;
                        amount += data.matchMap[matchId].usdtDeal;

                        IERC20(_tokenContract).transferFrom(
                            msg.sender,
                            matchOrder.sender,
                            data.matchMap[matchId].tokenDeal
                        );

                        if (matchOrder.usdtSurplus == 0)
                        {
                            // 完成的订单 从挂单池移除
                            data.orderBuyMap[price].pop();

                            // 订单状态
                            this.setOrderStatus(_tokenContract, matchOrder.orderId, OrderStatus.Finished);
                        }

                        if (order.tokenSurplus == 0)
                        {
                            // 撮合完成

                            // 订单状态
                            order.status = OrderStatus.Finished;
                            break;
                        }
                    }
                    // 该价格订单池消灭
                    if (data.orderBuyMap[price].length == 0)
                    {
                        data.orderBuyList.pop();
                        delete data.orderBuyMap[price];
                    }
                    if (order.tokenSurplus == 0)
                    {
                        break;
                    }
                }
                if (amount > 0)
                {
                    IERC20(USDT).transferFrom(
                    msg.sender,
                    order.sender,
                    amount);
                }
            }
        }
    }

    function testBuy(uint256 _price, uint256 _token) public
    {
        address _tokenContract = 0xd10b4C25feA7AC3FE3bf5bC82565d98dfA976cd8;
        uint256 orderId = this.createOrder(_tokenContract, msg.sender, _price, 0, _price*_token, 0);
        if (orderId > 0)
        {
            this.handleMatchOrder(_tokenContract, orderId);
            this.insertOrder(_tokenContract, orderId, msg.sender);
        }
    }

    function testSell(uint256 _price, uint256 _token) public
    {
        address _tokenContract = 0xd10b4C25feA7AC3FE3bf5bC82565d98dfA976cd8;
        uint256 orderId = this.createOrder(_tokenContract, msg.sender, _price, _token, 0, 1);
        if (orderId > 0)
        {
            this.handleMatchOrder(_tokenContract, orderId);
            this.insertOrder(_tokenContract, orderId, msg.sender);
        }
    }
}
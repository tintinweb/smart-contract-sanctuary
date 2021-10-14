pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";

contract Orderbook{

    address public treasury;
    uint feeMatchingByTokenB = 5;// 0.5%

    struct OrderInfo {
        address owner;//identity user to excute transfer ERC20 when matching
        uint256 amountA;
        uint256 amountB;
        uint256 expiryDate;
        bool isMatching;
    }

    struct OwnerOrderInfo {
        uint nonce;//index of listOrders[tokenA][tokenB]
        address tokenA;
        address tokenB;
    }

    mapping(address => OwnerOrderInfo[]) userOrders;
    mapping(address => mapping(address =>  OrderInfo[])) listOrders;

    mapping(address => mapping(address => uint)) liquidity;
    mapping(address => mapping(address => uint)) firstCurrentAvailableOrders;

    event CreateOrder (
        address user, 
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 indexed nonce, 
        uint256 amountA,
        uint64 expiryDate, 
        uint64 timestamp
    );

    event DepositOrder (
        address user, 
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 indexed nonce,
        uint256 amountA,
        uint64 timestamp
    );

    event MatchingMarketOrder (
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 nonceOfTokenAToTokenB,
        uint256 nonceOfTokenBToTokenA,
        uint256 amountAMatching,
        uint256 amountBMatching,
        uint64 indexed timestamp
    );

    event CancelOrder (
        uint256 indexed nonce,
        address indexed tokenA, 
        address indexed tokenB,
        uint256 amountA
    );

    event CloseOrder (
        uint256 indexed nonce,
        address indexed tokenA, 
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint64 timestamp
    );

    constructor(address _treasury) {
        treasury = _treasury;
    }
    
    function getOwnerOrders(address user) external view returns (OwnerOrderInfo[] memory) {
        return userOrders[user];
    }
    
    function getListOrders(address tokenA, address tokenB) external view returns (OrderInfo[] memory) {
        return listOrders[tokenA][tokenB];
    }
    function getOrder(address tokenA, address tokenB, uint nonce) external view returns (OrderInfo memory) {
        return listOrders[tokenA][tokenB][nonce];
    }

    function getLiquidity(address tokenA, address tokenB) external view returns (uint) {
        return liquidity[tokenA][tokenB];
    }

    function createOrder (
        address tokenA, 
        address tokenB, 
        uint256 amountA,
        uint256 expiryDate,
        bool isMatching
    ) external {
        require (expiryDate > block.timestamp, "ORDERBOOK: EXPIRYDATE_NOT_AVAILABLE");
        require (tokenA != address(0) && tokenB != address(0), "ORDERBOOK: TOKEN_NOT AVAILABLE");
        require (tokenA != tokenB, "ORDERBOOK: TOKEN_IS_NOT_SAMPLE");

        uint nonce = listOrders[tokenA][tokenB].length;
        OrderInfo memory order = OrderInfo(msg.sender, amountA, 0, expiryDate, isMatching);
        OwnerOrderInfo memory ownerOrder = OwnerOrderInfo(nonce, tokenA, tokenB);
        userOrders[msg.sender].push(ownerOrder);
        listOrders[tokenA][tokenB].push(order);

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        if (isMatching == true) 
            this.matchingMarketOrderOnBehalf(msg.sender, userOrders[msg.sender].length - 1);
        liquidity[tokenA][tokenB] += amountA;
        emit CreateOrder (msg.sender, tokenA, tokenB, nonce, amountA, uint64(expiryDate), uint64(block.timestamp));
    }

    function depositOrder (OwnerOrderInfo memory ownerOrder, uint256 amountA) external {
        OrderInfo storage order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
        require (order.expiryDate > block.timestamp, "ORDERBOOK: EXPIRYDATE_NOT_AVAILABLE");

        IERC20(ownerOrder.tokenA).transferFrom(msg.sender, address(this), amountA);
        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] += amountA;

        if(ownerOrder.nonce < firstCurrentAvailableOrders[ownerOrder.tokenA][ownerOrder.tokenB]) 
            firstCurrentAvailableOrders[ownerOrder.tokenA][ownerOrder.tokenB] = ownerOrder.nonce;

        emit DepositOrder(msg.sender, ownerOrder.tokenA, ownerOrder.tokenB, ownerOrder.nonce, amountA, uint64(block.timestamp));
    }
        
    function searchOrdersForMatching(address user, uint index) public view returns (
        uint[] memory ordersSuitable, 
        uint price, 
        uint amountARemaining,
        uint amountBRemaining
    ) {
        OwnerOrderInfo memory ownerOrder = userOrders[user][index];
        OrderInfo memory order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
        require (order.expiryDate > block.timestamp);
        require (order.amountA != 0);
        price = _calculatePrice(ownerOrder.tokenA, ownerOrder.tokenB, order.amountA);//default exist Amount B
        if(price == 0)
            return (ordersSuitable, 0, order.amountA, 0);
        OrderInfo[] memory orders = listOrders[ownerOrder.tokenB][ownerOrder.tokenA];
        uint count = 0;
        bool[] memory isSuitableOrders = new bool[](orders.length);
        uint totalAmount = 0;
        uint currentIndex = 0;
        for (uint i = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; i < orders.length; i++) {
            if (orders[i].amountA != 0 && orders[i].expiryDate > block.timestamp && orders[i].isMatching == true) {
                isSuitableOrders[i] = true;
                totalAmount += orders[i].amountA;
                count++;
                if (price <= totalAmount) {
                    ordersSuitable = new uint[](count);
                    for (uint k = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; k < i; k++) {
                        if (isSuitableOrders[k] == true) {
                            ordersSuitable[currentIndex] = k;
                            currentIndex++;
                        }
                    }
                    amountARemaining = 0;
                    amountBRemaining = totalAmount - price;
                    return (ordersSuitable, price, amountARemaining, amountBRemaining);
                }
            }
        }
        ordersSuitable = new uint[](count);
        for (uint k = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; k < orders.length; k++) {
            if (isSuitableOrders[k] == true) {
                ordersSuitable[currentIndex] = k;
                currentIndex++;
            }
        }
        amountARemaining = order.amountA - (totalAmount / price);
        amountBRemaining = totalAmount;
    }

    function startMatching(address _user, uint _index) public {
        OwnerOrderInfo memory ownerOrder = userOrders[_user][_index];
        OrderInfo storage order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
        require(order.expiryDate > uint64(block.timestamp));
        require(order.amountA != 0);
        order.isMatching = true;
    }

    function _updateAmountOrder (
        uint _nonce,
        address _tokenA, 
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) internal {
        listOrders[_tokenA][_tokenB][_nonce].amountA = _amountA;
        listOrders[_tokenA][_tokenB][_nonce].amountB = _amountB;
    }

    function matchingMarketOrderOnBehalf(address user, uint index) external {
        OwnerOrderInfo memory ownerOrder = userOrders[user][index];
        uint nonce = ownerOrder.nonce;
        address tokenA = ownerOrder.tokenA;
        address tokenB = ownerOrder.tokenB;
        OrderInfo memory order = listOrders[tokenA][tokenB][nonce];
        startMatching(user, index);
        (uint[] memory ordersSuitable, uint price, uint amountARemaining, uint amountBRemaining) = searchOrdersForMatching(user, index);
        if(price == 0)
            return;
        uint amountAReceive;
        if(ordersSuitable.length > 0) {
            if(ordersSuitable.length > 1) {
                for (uint i = 0; i < ordersSuitable.length - 1; i++) {
                    OrderInfo memory orderForMatching = listOrders[tokenB][tokenA][ordersSuitable[i]];
                    amountAReceive = order.amountA * orderForMatching.amountA / price;
                    _updateAmountOrder(ordersSuitable[i], tokenB, tokenA, 0, amountAReceive);
                    emit MatchingMarketOrder (
                        tokenA, 
                        tokenB, 
                        nonce, 
                        ordersSuitable[i], 
                        amountAReceive, 
                        orderForMatching.amountA, 
                        uint64(block.timestamp)
                    );
                }
            }

            OrderInfo memory lastOrderForMatching = listOrders[tokenB][tokenA][ordersSuitable[ordersSuitable.length - 1]];
            if (amountARemaining == 0) {
                amountAReceive = order.amountA * (lastOrderForMatching.amountA - amountBRemaining) / price;
                _updateAmountOrder(ordersSuitable[ordersSuitable.length - 1], tokenB, tokenA, amountBRemaining, amountAReceive);
                _updateAmountOrder(nonce, tokenA, tokenB, 0, price);
                emit MatchingMarketOrder (
                    tokenA, 
                    tokenB, 
                    nonce, 
                    ordersSuitable[ordersSuitable.length - 1], 
                    amountAReceive, 
                    lastOrderForMatching.amountA - amountBRemaining, 
                    uint64(block.timestamp)
                );
            }
            else {
                amountAReceive = order.amountA * lastOrderForMatching.amountA / price;
                _updateAmountOrder(ordersSuitable[ordersSuitable.length - 1], tokenB, tokenA, 0, amountAReceive);
                _updateAmountOrder(nonce, tokenA, tokenB, amountARemaining, amountBRemaining);
                emit MatchingMarketOrder (
                    tokenA, 
                    tokenB, 
                    nonce, 
                    ordersSuitable[ordersSuitable.length - 1], 
                    amountAReceive, 
                    lastOrderForMatching.amountA, 
                    uint64(block.timestamp)
                );
            }

            for (uint i = firstCurrentAvailableOrders[tokenA][tokenB]; i < listOrders[tokenA][tokenB].length; i++) {
                if (listOrders[tokenA][tokenB][i].expiryDate > uint64(block.timestamp) || listOrders[tokenA][tokenB][i].amountA != 0) {
                    firstCurrentAvailableOrders[tokenA][tokenB] = i;
                    break;
                }
            }
            for (uint i = firstCurrentAvailableOrders[tokenB][tokenA]; i < listOrders[tokenB][tokenA].length; i++) {
                if (listOrders[tokenB][tokenA][i].expiryDate > uint64(block.timestamp) || listOrders[tokenB][tokenA][i].amountA != 0) {
                    firstCurrentAvailableOrders[tokenB][tokenA] = i;
                    break;
                }
            }
        }
    }
    
    
    
    
    function matchingMarketOrder(uint index) external returns (uint, uint, uint, uint) {
        OwnerOrderInfo memory ownerOrder = userOrders[msg.sender][index];
        uint nonce = ownerOrder.nonce;
        address tokenA = ownerOrder.tokenA;
        address tokenB = ownerOrder.tokenB;
        OrderInfo memory order = listOrders[tokenA][tokenB][nonce];
        //startMatching(msg.sender, index);
        (uint[] memory ordersSuitable, uint price, uint amountARemaining, uint amountBRemaining) = searchOrdersForMatching(msg.sender, index);
        // if(price == 0)
        //     return;
        uint amountAReceive;
        if(ordersSuitable.length > 0) {
            if(ordersSuitable.length > 1) {
                for (uint i = 0; i < ordersSuitable.length - 1; i++) {
                    
                    OrderInfo memory orderForMatching = listOrders[tokenB][tokenA][ordersSuitable[i]];
                    
                    amountAReceive = order.amountA * orderForMatching.amountA / price;
                    _updateAmountOrder(ordersSuitable[i], tokenB, tokenA, 0, amountAReceive);
                    
                    
                    emit MatchingMarketOrder (
                        tokenA, 
                        tokenB, 
                        nonce, 
                        ordersSuitable[i], 
                        amountAReceive, 
                        orderForMatching.amountA, 
                        uint64(block.timestamp)
                    );
                }
            }
            OrderInfo memory lastOrderForMatching = listOrders[tokenB][tokenA][ordersSuitable[ordersSuitable.length - 1]];
            
            if (amountARemaining == 0) {
                amountAReceive = order.amountA * (lastOrderForMatching.amountA - amountBRemaining) / price;
                _updateAmountOrder(ordersSuitable[ordersSuitable.length - 1], tokenB, tokenA, amountBRemaining, amountAReceive);
                _updateAmountOrder(nonce, tokenA, tokenB, 0, price);
                emit MatchingMarketOrder (
                    tokenA, 
                    tokenB, 
                    nonce, 
                    ordersSuitable[ordersSuitable.length - 1], 
                    amountAReceive, 
                    lastOrderForMatching.amountA - amountBRemaining, 
                    uint64(block.timestamp)
                );
            }
            else {
                amountAReceive = order.amountA * lastOrderForMatching.amountA / price;
                _updateAmountOrder(ordersSuitable[ordersSuitable.length - 1], tokenB, tokenA, 0, amountAReceive);
                _updateAmountOrder(nonce, tokenA, tokenB, amountARemaining, amountBRemaining);
                emit MatchingMarketOrder (
                    tokenA, 
                    tokenB, 
                    nonce, 
                    ordersSuitable[ordersSuitable.length - 1], 
                    amountAReceive, 
                    lastOrderForMatching.amountA, 
                    uint64(block.timestamp)
                );
            }

            for (uint i = firstCurrentAvailableOrders[tokenA][tokenB]; i < listOrders[tokenA][tokenB].length; i++) {
                if (listOrders[tokenA][tokenB][i].expiryDate > uint64(block.timestamp) || listOrders[tokenA][tokenB][i].amountA != 0) {
                    firstCurrentAvailableOrders[tokenA][tokenB] = i;
                    break;
                }
            }
            for (uint i = firstCurrentAvailableOrders[tokenB][tokenA]; i < listOrders[tokenB][tokenA].length; i++) {
                if (listOrders[tokenB][tokenA][i].expiryDate > uint64(block.timestamp) || listOrders[tokenB][tokenA][i].amountA != 0) {
                    firstCurrentAvailableOrders[tokenB][tokenA] = i;
                    break;
                }
            }
        }
    }

    function cancelOrder(uint index) external {
        OwnerOrderInfo memory ownerOrder = userOrders[msg.sender][index];
        OrderInfo storage order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
        require (order.amountA != 0, "ORDERBOOK: AMOUNT_TOKEN_IS_NOT_ENOUGH");
        
        order.isMatching = false;
        IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
        order.amountA = 0;
    }

    function closeOrder(uint index) external {
        OwnerOrderInfo memory ownerOrder = userOrders[msg.sender][index];
        OrderInfo storage order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
        require (order.expiryDate <= uint64(block.timestamp), "ORDERBOOK: ORDER_IS_STILL_VALID");
        order.isMatching = false;
        uint debt = (order.amountB * feeMatchingByTokenB) / 1000;
        uint actualAmountB = order.amountB - debt; 
        IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
        IERC20(ownerOrder.tokenB).transfer(msg.sender, actualAmountB);
        IERC20(ownerOrder.tokenB).transfer(treasury, debt);
        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
        liquidity[ownerOrder.tokenB][ownerOrder.tokenA] -= order.amountB;
        order.amountA = 0;
        order.amountB = 0;
    }
    
    function closeAllOrders() external {
        for(uint index = 0; index < userOrders[msg.sender].length; index++) {
            OwnerOrderInfo memory ownerOrder = userOrders[msg.sender][index];
            OrderInfo storage order = listOrders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.nonce];
            require (order.expiryDate <= uint64(block.timestamp), "ORDERBOOK: ORDER_IS_STILL_VALID");
            order.isMatching = false;
            uint debt = (order.amountB * feeMatchingByTokenB) / 1000;
            uint actualAmountB = order.amountB - debt; 
            IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
            IERC20(ownerOrder.tokenB).transfer(msg.sender, actualAmountB);
            IERC20(ownerOrder.tokenB).transfer(treasury, debt);
            liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
            liquidity[ownerOrder.tokenB][ownerOrder.tokenA] -= order.amountB;
            order.amountA = 0;
            order.amountB = 0;
        }
    }
    
    function _calculatePrice(address tokenA, address tokenB, uint amountA) internal view returns (uint price) {
        require (tokenA != address(0) && tokenB != address(0), "ORDERBOOK: TOKEN_NOT AVAILABLE");
        require (tokenA != tokenB, "ORDERBOOK: TOKEN_IS_NOT_SAMPLE");
        require (amountA != 0, "ORDERBOOK: AMOUNT IS NOT AVAILABLE");
        uint reverseA = liquidity[tokenA][tokenB];
        uint reverseB = liquidity[tokenB][tokenA];
        if (reverseA == 0 || reverseB == 0) {
            return 0;
        } else {
            price = amountA * reverseB / reverseA;
            return price;
        } 
    }
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
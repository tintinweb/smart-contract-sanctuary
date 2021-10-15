pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";

contract Cerebral{

    address public treasury;
    address public admin;
    uint public feeMatching = 5;// 0.5%

    struct OrderInfo {
        address owner;
        uint256 amountA;
        uint256 amountB;
        uint64 expiryDate;
        bool isMatching;
    }

    struct OwnerOrderInfo {
        uint orderId; // index of orders[tokenA][tokenB]
        address tokenA;
        address tokenB;
    }

    mapping(address => OwnerOrderInfo[]) ownerOrders;
    mapping(address => mapping(address =>  OrderInfo[])) orders;

    mapping(address => mapping(address => uint)) liquidity;
    mapping(address => mapping(address => uint)) firstCurrentAvailableOrders;

    event CreateOrder (
        address owner,
        address indexed tokenA,
        address indexed tokenB,
        uint256 indexed orderId,
        uint256 amountA,
        uint64 expiryDate,
        uint64 timestamp
    );

    event DepositOrder (
        address owner,
        address indexed tokenA,
        address indexed tokenB,
        uint256 indexed orderId,
        uint256 amountA,
        uint64 timestamp
    );

    event MatchingMarketOrder (
        address indexed tokenA,
        address indexed tokenB,
        uint256 nonceOfTokenAToTokenB,
        uint256 nonceOfTokenBToTokenA,
        uint256 amountAMatching,
        uint256 amountBMatching
    );

    event CancelOrder (
        uint256 indexed orderId,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint64 timestamp
    );

    event CloseOrder (
        uint256 indexed orderId,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint64 timestamp
    );
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV2: NOT_ADMIN_ADDRESS");
        _;
    }
    
    constructor(address _admin, address _treasury) {
        admin = _admin;
        treasury = _treasury;
    }
    
    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
    }

    function setFeeMatching(uint fee) external onlyAdmin {
        feeMatching = fee;
    }
    
    function transferAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
    
    function getOwnerOrders(address owner) external view returns (OwnerOrderInfo[] memory) {
        return ownerOrders[owner];
    }

    function getOrders(address tokenA, address tokenB) external view returns (OrderInfo[] memory) {
        return orders[tokenA][tokenB];
    }

    function getOrder(address tokenA, address tokenB, uint orderId) external view returns (OrderInfo memory) {
        return orders[tokenA][tokenB][orderId];
    }

    function getLiquidity(address tokenA, address tokenB) external view returns (uint) {
        return liquidity[tokenA][tokenB];
    }

    function createOrder (
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint64 expiryDate,
        bool isMatching
    ) external {
        require(expiryDate > block.timestamp, "Cerebral: EXPIRYDATE_NOT_AVAILABLE");
        require(tokenA != address(0) && tokenB != address(0), "Cerebral: TOKEN_NOT AVAILABLE");
        require(tokenA != tokenB, "Cerebral: TOKEN_IS_NOT_SAMPLE");

        uint orderId = orders[tokenA][tokenB].length;
        OrderInfo memory order = OrderInfo(msg.sender, amountA, 0, expiryDate, isMatching);
        OwnerOrderInfo memory ownerOrder = OwnerOrderInfo(orderId, tokenA, tokenB);
        ownerOrders[msg.sender].push(ownerOrder);
        orders[tokenA][tokenB].push(order);

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        if (isMatching == true) {
            _matchingMarketOrder(msg.sender, ownerOrders[msg.sender].length - 1);
        }
        liquidity[tokenA][tokenB] += amountA;
        emit CreateOrder(msg.sender, tokenA, tokenB, orderId, amountA, expiryDate, uint64(block.timestamp));
    }

    function depositOrder(uint ownerOrderId, uint amountA) external {
        OwnerOrderInfo memory ownerOrder = ownerOrders[msg.sender][ownerOrderId];
        OrderInfo storage order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
        require (order.expiryDate > block.timestamp, "Cerebral: EXPIRYDATE_NOT_AVAILABLE");

        IERC20(ownerOrder.tokenA).transferFrom(msg.sender, address(this), amountA);
        order.amountA += amountA;

        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] += amountA;

        if (ownerOrder.orderId < firstCurrentAvailableOrders[ownerOrder.tokenA][ownerOrder.tokenB]) {
            firstCurrentAvailableOrders[ownerOrder.tokenA][ownerOrder.tokenB] = ownerOrder.orderId;
        }

        emit DepositOrder(msg.sender, ownerOrder.tokenA, ownerOrder.tokenB, ownerOrder.orderId, amountA, uint64(block.timestamp));
    }

    function searchOrdersForMatching(address owner, uint ownerOrderId) public view returns (
        uint[] memory ordersSuitable,
        uint price,
        uint amountARemaining,
        uint amountBRemaining
    ) {
        OwnerOrderInfo memory ownerOrder = ownerOrders[owner][ownerOrderId];
        OrderInfo memory order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
        require (order.expiryDate > block.timestamp);
        require (order.amountA != 0);
        price = calculatePrice(ownerOrder.tokenA, ownerOrder.tokenB, order.amountA);//default exist Amount B
        if (price == 0) {
            return (ordersSuitable, 0, order.amountA, 0);
        }
        OrderInfo[] memory listOrders = orders[ownerOrder.tokenB][ownerOrder.tokenA];
        uint count = 0;
        bool[] memory isSuitableOrders = new bool[](listOrders.length);
        uint totalAmount = 0;
        uint currentIndex = 0;
        for (uint i = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; i < listOrders.length; i++) {
            if (listOrders[i].amountA != 0 && listOrders[i].expiryDate > block.timestamp && listOrders[i].isMatching == true) {
                isSuitableOrders[i] = true;
                totalAmount += listOrders[i].amountA;
                count++;
                if (price <= totalAmount) {
                    ordersSuitable = new uint[](count);
                    for (uint k = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; k <= i; k++) {
                        if (isSuitableOrders[k] == true) {
                            ordersSuitable[currentIndex] = k;
                            currentIndex++;
                        }
                    }
                    amountARemaining = 0;
                    amountBRemaining = totalAmount - price;//is amountA of last orderB
                    return (ordersSuitable, price, amountARemaining, amountBRemaining);
                }
            }
        }
        ordersSuitable = new uint[](count);
        for (uint k = firstCurrentAvailableOrders[ownerOrder.tokenB][ownerOrder.tokenA]; k < listOrders.length; k++) {
            if (isSuitableOrders[k] == true) {
                ordersSuitable[currentIndex] = k;
                currentIndex++;
            }
        }
        amountARemaining = order.amountA - (order.amountA * totalAmount) / price;
        amountBRemaining = totalAmount;//is amountB of orderA
        return (ordersSuitable, price, amountARemaining, amountBRemaining);
    }

    function _startMatching(address owner, uint ownerOrderId) internal {
        OwnerOrderInfo memory ownerOrder = ownerOrders[owner][ownerOrderId];
        OrderInfo storage order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
        require (order.expiryDate > uint64(block.timestamp));
        require (order.amountA != 0);
        order.isMatching = true;
    }

    function startMatching(uint ownerOrderId) external {
        _startMatching(msg.sender, ownerOrderId);
    }

    function _updateAmountOrder (
        uint _nonce,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) internal {
        orders[_tokenA][_tokenB][_nonce].amountA = _amountA;
        orders[_tokenA][_tokenB][_nonce].amountB = _amountB;
    }

    function _matchingMarketOrder(address owner, uint ownerOrderId) internal {
        OwnerOrderInfo memory ownerOrder = ownerOrders[owner][ownerOrderId];
        address tokenA = ownerOrder.tokenA;
        address tokenB = ownerOrder.tokenB;
        OrderInfo memory order = orders[tokenA][tokenB][ownerOrder.orderId];
        _startMatching(owner, ownerOrderId);

        uint price = calculatePrice(ownerOrder.tokenA, ownerOrder.tokenB, order.amountA);
        if (price == 0) return;
        uint totalAmountAMatching = 0;
        uint totalAmountBMatching = 0;
        
        for (uint i = firstCurrentAvailableOrders[tokenB][tokenA]; i < orders[tokenB][tokenA].length; i++) {
            OrderInfo memory orderForMatching = orders[tokenB][tokenA][i];
            
            if (orderForMatching.isMatching == false || orderForMatching.amountA == 0 || orderForMatching.expiryDate < uint64(block.timestamp))
                continue;
            uint amountAMatching = order.amountA * orderForMatching.amountA / price;
            uint amountBMatching = orderForMatching.amountA;
            
            if (amountAMatching + totalAmountAMatching > order.amountA) {
                uint actualAmountAMatching = order.amountA - totalAmountAMatching;// amountA remaining orderB can receive
                uint actualAmountBMatching = orderForMatching.amountA * actualAmountAMatching / amountAMatching;
                _updateAmountOrder(i, tokenB, tokenA, orderForMatching.amountA - actualAmountBMatching, actualAmountAMatching);
                
                totalAmountAMatching += actualAmountAMatching;
                totalAmountBMatching += amountBMatching;
                emit MatchingMarketOrder(tokenA, tokenB, ownerOrder.orderId, i, actualAmountAMatching, actualAmountBMatching);
                break;
            }
            
            _updateAmountOrder(i, tokenB, tokenA, 0, amountAMatching);
            totalAmountAMatching += amountAMatching;
            totalAmountBMatching += amountBMatching;
            emit MatchingMarketOrder(tokenA, tokenB, ownerOrder.orderId, i, amountAMatching, amountBMatching);
            
            if (totalAmountAMatching == order.amountA) break;
        }
        _updateAmountOrder(ownerOrder.orderId, tokenA, tokenB, order.amountA - totalAmountAMatching, totalAmountBMatching);
        
        liquidity[tokenA][tokenB] -= totalAmountAMatching;
        liquidity[tokenB][tokenA] -= totalAmountBMatching;
        
        for (uint i = firstCurrentAvailableOrders[tokenA][tokenB]; i < orders[tokenA][tokenB].length; i++) {
            if (orders[tokenA][tokenB][i].expiryDate > uint64(block.timestamp) || orders[tokenA][tokenB][i].amountA != 0) {
                firstCurrentAvailableOrders[tokenA][tokenB] = i;
                break;
            }
        }
        for (uint i = firstCurrentAvailableOrders[tokenB][tokenA]; i < orders[tokenB][tokenA].length; i++) {
            if (orders[tokenB][tokenA][i].expiryDate > uint64(block.timestamp) || orders[tokenB][tokenA][i].amountA != 0) {
                firstCurrentAvailableOrders[tokenB][tokenA] = i;
                break;
            }
        }
    }
    

    function matchingMarketOrder(uint ownerOrderId) external {
        _matchingMarketOrder(msg.sender, ownerOrderId);
    }

    function cancelOrder(uint ownerOrderId) external {
        OwnerOrderInfo memory ownerOrder = ownerOrders[msg.sender][ownerOrderId];
        OrderInfo storage order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
        require (order.amountA != 0, "Cerebral: AMOUNT_TOKEN_IS_NOT_ENOUGH");
        order.isMatching = false;
        IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
        order.amountA = 0;
        emit CancelOrder(ownerOrder.orderId, ownerOrder.tokenA, ownerOrder.tokenB, order.amountA, uint64(block.timestamp));
    }

    function closeOrder(uint ownerOrderId) external {
        OwnerOrderInfo memory ownerOrder = ownerOrders[msg.sender][ownerOrderId];
        OrderInfo storage order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
        require (order.expiryDate <= uint64(block.timestamp), "Cerebral: ORDER_IS_STILL_VALID");
        order.isMatching = false;
        uint debt = (order.amountB * feeMatching) / 1000;
        uint actualAmountB = order.amountB - debt;
        IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
        IERC20(ownerOrder.tokenB).transfer(msg.sender, actualAmountB);
        IERC20(ownerOrder.tokenB).transfer(treasury, debt);
        liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
        order.amountA = 0;
        order.amountB = 0;
        emit CloseOrder(ownerOrder.orderId, ownerOrder.tokenA, ownerOrder.tokenB, order.amountA,order.amountB, uint64(block.timestamp));
    }

    function closeAllOrders() external {
        for (uint index = 0; index < ownerOrders[msg.sender].length; index++) {
            OwnerOrderInfo memory ownerOrder = ownerOrders[msg.sender][index];
            OrderInfo storage order = orders[ownerOrder.tokenA][ownerOrder.tokenB][ownerOrder.orderId];
            require (order.expiryDate <= uint64(block.timestamp), "Cerebral: ORDER_IS_STILL_VALID");
            if(order.amountA != 0 && order.amountB != 0){
                order.isMatching = false;
                uint debt = (order.amountB * feeMatching) / 1000;
                uint actualAmountB = order.amountB - debt;
                IERC20(ownerOrder.tokenA).transfer(msg.sender, order.amountA);
                IERC20(ownerOrder.tokenB).transfer(msg.sender, actualAmountB);
                IERC20(ownerOrder.tokenB).transfer(treasury, debt);
                liquidity[ownerOrder.tokenA][ownerOrder.tokenB] -= order.amountA;
                order.amountA = 0;
                order.amountB = 0;
                emit CloseOrder(ownerOrder.orderId, ownerOrder.tokenA, ownerOrder.tokenB, order.amountA,order.amountB, uint64(block.timestamp));
            }
        }
    }

    function calculatePrice(address tokenA, address tokenB, uint amountA) public view returns (uint price) {
        require (tokenA != address(0) && tokenB != address(0), "Cerebral: TOKEN_NOT AVAILABLE");
        require (tokenA != tokenB, "Cerebral: TOKEN_IS_NOT_SAMPLE");
        require (amountA != 0, "Cerebral: AMOUNT IS NOT AVAILABLE");
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
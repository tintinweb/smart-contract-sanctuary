pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./interface/IBEP20.sol";

/**

    Sniped by the fastest fingers in the Wild West!

    Come on down to the saloon to find out more

    https://t.me/thesal00n

    https://www.quickdraw.finance/

*/

contract Sniper {

    // Only let the sniper backend call the method
    modifier OnlyServer() {
        require(msg.sender == sniperServer);
        _;
    }

    // Only let the deployer call the method
    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Only an admin can call the method
    modifier OnlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    event OrderPlaced(address indexed buyer, address indexed tokenAddress, uint8 transactions, uint8 blockDelay, uint256 timeDelay, uint256 index, uint256 amountIn, uint256 deadline);
    event OrderFulfilled(uint256 indexed index, address indexed tokenAddress, address indexed recipient, uint8 number);
    event OrderFailed(uint256 indexed index, address indexed tokenAddress, address indexed recipient, uint8 number);
    event OrderRefunded(uint256 indexed index, address indexed tokenAddress, address indexed recipient, uint256 amount);

    enum OrderStatus { Pending, Fulfilled, Failed, Refunded, Partial }
    struct Order {
        uint256 id;
        address buyer;
        address token;
        uint256 amountIn;
        uint256 deadline;
        uint8 transactions;
        OrderStatus status;
    }

    struct OrderNode {
        Order order;
        uint256 next;
        uint256 prev;
    }

    uint256 public gasFee = 15000000000000000; // 0.015 bnb
    bool public snipingEnabled = true;

    mapping(uint256 => OrderNode) orderBook;

    mapping(address => uint256[]) userOrders;

    mapping(address => bool) isAdmin;

    uint256 head = 0;
    uint256 public orderBookLength;
    address sniperServer;
    address owner;

    uint8 public batchSize = 5;

    IUniswapV2Router02 uniswapV2Router;

    IBEP20 quickDraw;
    uint256 public minHold = 750000000000000000000;

    constructor (address _uniswapV2RouterAddr, address _sniperServer, address _quickDraw) {

        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddr);
        sniperServer = _sniperServer;
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        quickDraw = IBEP20(_quickDraw);

    }

    function updateGasFee(uint256 _gasFee) external OnlyOwner {
        gasFee = _gasFee;
    }

    function updateBatchSize(uint8 _batchSize) external OnlyOwner {
        batchSize = _batchSize;
    }

    function setSnipingEnabled(bool _snipingEnabled) external OnlyAdmin {
        snipingEnabled = _snipingEnabled;
    }

    function updateMinHold(uint256 _minHold) external OnlyAdmin {
        minHold = _minHold;
    }

    function setIsAdmin(address user, bool value) external OnlyOwner {
        isAdmin[user] = value;
    }

    function placeOrder(
        address tokenAddress,
        uint256 amountIn,
        uint8 transactions,
        uint8 blockDelay,
        uint256 timeDelay,
        uint256 deadline,
        string memory salt
    ) external payable returns(uint256) {

        require(snipingEnabled, 'placeOrder: Sniping has been disabled!');
        require(transactions > 0, 'placeOrder: Must make at least one transaction');
        require(deadline > block.timestamp, 'placeOrder: Deadline must be in the future');
        require(deadline < block.timestamp + 3 days, 'placeOrder: Deadline must be smaller than 3 days');
        require(quickDraw.balanceOf(msg.sender) >= minHold, "placeOrder: You don't hold enough QuickDraw");

        // Charge an extra gas fee per batch filled with transactions
        require(msg.value >= (amountIn * transactions) + gasFee * (1 + (transactions / batchSize)), 'placeOrder: Wrong token amount');

        // Process any refunds that need to be made
        processRefunds();

        // Transfer tax tokens to the sniper server
        payable(sniperServer).transfer(msg.value - amountIn * transactions);

        // Add order to list
        uint256 index = insertOrder(Order({
            id: 0,
            buyer: msg.sender,
            token: tokenAddress,
            amountIn: amountIn,
            deadline: deadline,
            transactions: transactions,
            status: OrderStatus.Pending
        }), salt);

        // Bind the id
        orderBook[index].order.id = index;

        userOrders[msg.sender].push(index);

        // Emit event so that the sniper server picks up the order
        emit OrderPlaced(msg.sender, tokenAddress, transactions, blockDelay, timeDelay, index, amountIn, deadline);

        return index;

    }

    function cancelOrder(uint256 index) external {

        Order storage o = orderBook[index].order;

        require(o.buyer == msg.sender, 'cancelOrder: You are not authorised to cancel this order');

        refund(o);

        o.transactions = 0;

        // Process any refunds that need to be made
        processRefunds();

    }

    function processRefunds() public {

        // As the orderBook is sorted ascending by timestamp we can iterate it
        while (true) {

            if (orderBook[head].order.token == address(0)) { return; }

            // If the order has expired - refund
            if (orderBook[head].order.deadline < block.timestamp) {

                refund(orderBook[head].order);

                head = orderBook[head].next;
                orderBook[head].prev = 0;

                orderBookLength--;

            } else {
                break;
            }

        }

    }

    function getOrderId(address tokenAddress, string memory salt) external view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, tokenAddress, salt)));
    }

    function getOrders(address userAddress) external view returns(uint256[] memory) {
        return userOrders[userAddress];
    }

    function getOrderCount(address userAddress) external view returns(uint256) {
        return userOrders[userAddress].length;
    }

    function getOrderStatuses(address userAddress, uint256 amount, uint256 offset) external view returns(Order[] memory) {

        Order[] memory orders = new Order[](amount);

        for(uint256 i = offset; i < amount; i++) {

            if (i == userOrders[userAddress].length) { break; }

            orders[i - offset] = orderBook[userOrders[userAddress][i]].order;

        }

        return orders;

    }

    function processOrderBatch(uint256[] memory ids) external OnlyServer {

        // Make sure this batch hasn't already fired (This saves gas being wasted as we do a high and a low gas snipe with the same data)
        require (orderBook[ids[0]].order.status == OrderStatus.Pending);

        for (uint256 i = 0; i < ids.length; ++i) {

            Order storage o = orderBook[ids[i]].order;

            // Avoid null data
            if (o.token == address(0)) { continue; }

             // If the user has manually refunded the order before we have processed it
            if (o.transactions == 0) {
                return;
            }

            fulfillOrder(o, ids[i]);

        }

    }

    function recoverBEP20(address _token, uint256 amount) external OnlyOwner {
        IBEP20(_token).transfer(owner, amount);
    }

    function insertOrder(Order memory o, string memory salt) internal returns(uint256) {

        uint256 index = uint256(keccak256(abi.encodePacked(o.buyer, o.token, salt)));

        // Make sure we don't overwrite a pending order (insanely unlikely)
        require(orderBook[index].order.token == address(0) || (
            orderBook[index].order.status != OrderStatus.Pending
            && orderBook[index].order.status != OrderStatus.Partial
        ), 'insertOrder: order collision');

        uint256 next = 0;
        uint256 prev = 0;
        uint256 currentKey = head;

        // Traverse list to find where the deadline fits
        if (orderBookLength == 0) {
            head = index;
        } else {

            // If the timestamp is smaller than the current head
            if (o.deadline <= orderBook[currentKey].order.deadline) {

                next = currentKey;
                head = index;

            } else {

                currentKey = orderBook[currentKey].next;

                if (currentKey == 0) {
                    orderBook[currentKey].next = index;
                    prev = currentKey;
                } else {

                    while (true) {
                        if (orderBook[currentKey].next == 0 || o.deadline <= orderBook[orderBook[currentKey].next].order.deadline) {
                            break;
                        }
                        prev = currentKey;
                        currentKey = orderBook[currentKey].next;
                    }

                    // At this point we have found our insertion point
                    next = orderBook[currentKey].next;
                    orderBook[currentKey].next = index;

                }

            }

        }

        orderBook[index] = OrderNode({
            order: o,
            next: next,
            prev: prev
        });

        orderBookLength++;

        return index;

    }

    function fulfillOrder(Order storage o, uint256 index) internal {

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = o.token;

        try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: o.amountIn }(
            1,
            path,
            o.buyer,
            block.timestamp
        ) {
            o.status = OrderStatus.Partial;
            emit OrderFulfilled(index, o.token, o.buyer, o.transactions);
            o.transactions--;
        } catch {

            // Only set a failure if another transaction of the same batch hasn't gotten through
            if (o.status != OrderStatus.Partial) {
                o.status = OrderStatus.Failed;
            }

            emit OrderFailed(index, o.token, o.buyer, o.transactions);

        }

        if (o.transactions == 0) {

            o.status = OrderStatus.Fulfilled;

            // Remove orders from the order book
            if (head == index) {

                head = orderBook[index].next;
                orderBook[head].prev = 0;

            } else {

                orderBook[orderBook[index].prev].next = orderBook[index].next;
                orderBook[orderBook[index].next].prev = orderBook[index].prev;

            }

            orderBookLength--;

        }

    }

    function refund(Order storage o) internal {
        if (o.transactions == 0) { return; }
        payable(o.buyer).transfer(o.amountIn * o.transactions);
        o.status = OrderStatus.Refunded;
        emit OrderRefunded(o.id, o.token, o.buyer, o.amountIn * o.transactions);
    }

}

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


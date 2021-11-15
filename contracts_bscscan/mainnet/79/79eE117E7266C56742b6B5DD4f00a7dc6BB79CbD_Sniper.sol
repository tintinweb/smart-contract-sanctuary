pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Sniper {

    modifier OnlyServer() {
        require(msg.sender == sniperServer);
        _;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier Whitelist() {
        require(whitelist[msg.sender]);
        _;
    }

    event OrderPlaced(address indexed buyer, address indexed tokenAddress, uint8 transactions, uint8 blockDelay, uint256 timeDelay, uint256 index, uint256 amountIn, uint256 deadline);
    event OrderFulfilled(uint256 indexed index, address indexed tokenAddress, address indexed recipient, uint8 number);
    event OrderFailed(uint256 indexed index, address indexed tokenAddress, address indexed recipient, uint8 number);

    struct Order {
        address buyer;
        address token;
        uint256 amountIn;
        uint256 deadline;
        uint8 transactions;
    }

    struct OrderNode {
        Order order;
        uint256 next;
        uint256 prev;
    }

    uint256 public gasFee = 15000000000000000; // 0.015 bnb

    mapping(uint256 => OrderNode) orderBook;

    enum OrderStatus { Pending, Fulfilled, Failed, Refunded, Partial }
    mapping(uint256 => OrderStatus) public orderStatuses;

    mapping(address => bool) whitelist;
    uint256 head = 0;
    uint256 orderBookLength;
    address sniperServer;
    address owner;

    uint8 public batchSize = 5;

    IUniswapV2Router02 uniswapV2Router;

    constructor (address _uniswapV2RouterAddr, address _sniperServer) {

        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddr);
        sniperServer = _sniperServer;
        owner = msg.sender;
        whitelist[owner] = true;

    }

    function whitelistUser(address user) external OnlyOwner {
        whitelist[user] = true;
    }

    function updateGasFee(uint256 _gasFee) external OnlyOwner {
        gasFee = _gasFee;
    }

    function updateBatchSize(uint8 _batchSize) external OnlyOwner {
        batchSize = _batchSize;
    }

    function placeOrder(
        address tokenAddress,
        uint256 amountIn,
        uint8 transactions,
        uint8 blockDelay,
        uint256 timeDelay,
        uint256 deadline,
        string memory salt
    ) external payable Whitelist returns(uint256) {

        require(transactions > 0, 'placeOrder: Must make at least one transaction');

        // Charge an extra gas fee per batch filled with transactions
        require(msg.value >= (amountIn * transactions) + gasFee * (1 + (transactions / batchSize)), 'placeOrder: Wrong token amount');

        // TODO Check the address is a BEP20 token

        // Transfer tax tokens to the sniper server
        payable(sniperServer).transfer(msg.value - amountIn * transactions);

        // Add order to list
        uint256 index = insertOrder(Order({
            buyer: msg.sender,
            token: tokenAddress,
            amountIn: amountIn,
            deadline: deadline,
            transactions: transactions
        }), salt);

        orderStatuses[index] = OrderStatus.Pending;

        // Emit event so that the sniper server picks up the order
        emit OrderPlaced(msg.sender, tokenAddress, transactions, blockDelay, timeDelay, index, amountIn, deadline);

        // Process any refunds that need to be made
        processRefunds();

        return index;

    }

    function getOrderId(address tokenAddress, string memory salt) external view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, tokenAddress, salt)));
    }

    function getOrderStatus(uint256 index) external view returns(OrderStatus) {
        return orderStatuses[index];
    }

    function processOrderBatch(uint256[] memory ids) external OnlyServer {

        for (uint256 i = 0; i < ids.length; ++i) {

            Order storage o = orderBook[ids[i]].order;

            // Avoid null data
            if (o.token == address(0)) { continue; }

            fulfillOrder(o, ids[i]);

        }

    }

    function insertOrder(Order memory o, string memory salt) internal returns(uint256) {

        uint256 index = uint256(keccak256(abi.encodePacked(o.buyer, o.token, salt)));

        require(orderBook[index].order.token == address(0), 'insertOrder: order collision');

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

    function processRefunds() internal {

        // As the orderBook is sorted ascending by timestamp we can iterate it
        while (true) {

            // If the order has expired - refund
            if (orderBook[head].order.deadline < block.timestamp) {

                uint256 index = head;

                refund(orderBook[head].order);
                orderStatuses[head] = OrderStatus.Refunded;

                head = orderBook[head].next;
                orderBook[head].prev = 0;

                orderBookLength--;

                delete orderBook[index];

            } else {
                break;
            }

        }

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
            orderStatuses[index] = OrderStatus.Partial;
            emit OrderFulfilled(index, o.token, o.buyer, o.transactions);
            o.transactions--;
        } catch {

            // Only set a failure if another transaction of the same batch hasn't gotten through
            if (orderStatuses[index] != OrderStatus.Partial) {
                orderStatuses[index] = OrderStatus.Failed;
            }

            emit OrderFailed(index, o.token, o.buyer, o.transactions);

        }

        if (o.transactions == 0) {

            orderStatuses[index] = OrderStatus.Fulfilled;

            // Remove orders from the order book
            if (head == index) {

                head = orderBook[index].next;
                orderBook[head].prev = 0;

            } else {

                orderBook[orderBook[index].prev].next = orderBook[index].next;
                orderBook[orderBook[index].next].prev = orderBook[index].prev;

            }

            orderBookLength--;

            delete orderBook[index];

        }

    }

    function refund(Order memory o) internal {
        payable(o.buyer).transfer(o.amountIn * o.transactions);
    }

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


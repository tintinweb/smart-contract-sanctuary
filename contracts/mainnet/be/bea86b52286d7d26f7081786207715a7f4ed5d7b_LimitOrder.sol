/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

interface IPeripheryImmutableState {
    function factory() external view returns (address);
    function WETH9() external view returns (address);
}

interface ISwapRouter is IUniswapV3SwapCallback, IPeripheryImmutableState {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IUniswapV3Factory {

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool);
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    function owner() external view returns (address);
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
    function setOwner(address _owner) external;
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
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
        if (a == 0) { return 0; }
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
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library TransferHelper {

    function safeTransferFrom(address token, address from, address to, uint256 value ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LimitOrder is Ownable {
    using SafeMath for uint256;
    
    ISwapRouter public immutable uniswapRouter;
    IUniswapV3Factory public immutable uniswapFactory;
    
    enum OrderState {Created, Cancelled, Finished}
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    
    struct Order {
        OrderState orderState;
        OrderType orderType;
        address payable traderAddress;
        address assetIn;
        address assetOut;
        uint assetInOffered;
        uint assetOutExpected;
        uint executorFee;
        uint stake;
        uint id;
        uint ordersI;
        uint24 poolFee;
    }
    
    uint public STAKE_FEE = 2;
    uint public STAKE_PERCENTAGE = 92;
    uint public EXECUTOR_FEE = 500000000000000;
    uint[] public orders;
    uint public ordersNum = 0;
    address public stakeAddress = address(0xC9f9de264cd16FD0e5b3FB4C1b276549f70814c7);
    address public owAddress = address(0xc56dE69EC711D6E4A48283c346b1441f449eCA5A);
    
    event logOrderCreated(
        uint id,
        OrderState orderState, 
        OrderType orderType, 
        address payable traderAddress, 
        address assetIn, 
        address assetOut,
        uint assetInOffered, 
        uint assetOutExpected, 
        uint executorFee,
        uint24 poolFee
    );
    event logOrderCancelled(uint id, address payable traderAddress, address assetIn, address assetOut, uint refundETH, uint refundToken);
    event logOrderExecuted(uint id, address executor, uint swapResult);
    
    mapping(uint => Order) public orderBook;
    mapping(address => uint[]) private ordersForAddress;
    
    constructor(ISwapRouter _uniswapRouter) {
        uniswapRouter = ISwapRouter(_uniswapRouter);
        uniswapFactory = IUniswapV3Factory(_uniswapRouter.factory());
    }
    
    function setNewStakeFee(uint256 _STAKE_FEE) external onlyOwner {
        STAKE_FEE = _STAKE_FEE;
    }
    
    function setNewStakePercentage(uint256 _STAKE_PERCENTAGE) external onlyOwner {
        require(_STAKE_PERCENTAGE >= 0 && _STAKE_PERCENTAGE <= 100,'STAKE_PERCENTAGE must be between 0 and 100');
        STAKE_PERCENTAGE = _STAKE_PERCENTAGE;
    }
    
    function setNewExecutorFee(uint256 _EXECUTOR_FEE) external onlyOwner {
        EXECUTOR_FEE = _EXECUTOR_FEE;
    }
    
    function setNewStakeAddress(address _stakeAddress) external onlyOwner {
        require(_stakeAddress != address(0), 'Do not use 0 address');
        stakeAddress = _stakeAddress;
    }
    
    function setNewOwAddress(address _owAddress) external onlyOwner {
        require(_owAddress != address(0), 'Do not use 0 address');
        owAddress = _owAddress;
    }
    
    function getPool(address tokenA, address tokenB, uint24 fee) internal view returns (address) {
        address _tokenPair = uniswapFactory.getPool(tokenA, tokenB, fee);
        require(_tokenPair != address(0), "Unavailable token pair");
        return _tokenPair;
    }
    
    function updateOrder(Order memory order, OrderState newState) internal {
        if(orders.length > 1) {
            uint openId = order.ordersI;
            uint lastId = orders[orders.length-1];
            Order memory lastOrder = orderBook[lastId];
            lastOrder.ordersI = openId;
            orderBook[lastId] = lastOrder;
            orders[openId] = lastId;
        }
        orders.pop();
        order.orderState = newState;
        orderBook[order.id] = order;        
    }
    
    function createOrder(
        OrderType orderType, 
        address assetIn, 
        address assetOut, 
        uint assetInOffered, 
        uint assetOutExpected, 
        uint executorFee, 
        uint24 poolFee
    ) external payable {
        
        uint payment = msg.value;
        uint stakeValue = 0;
        
        require(assetInOffered > 0, "Asset in amount must be greater than 0");
        require(assetOutExpected > 0, "Asset out amount must be greater than 0");
        require(executorFee >= EXECUTOR_FEE, "Invalid fee");
        
        if(orderType == OrderType.EthForTokens) {
            require(assetIn == uniswapRouter.WETH9(), "Use WETH as the assetIn");
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            require(payment == assetInOffered.add(executorFee).add(stakeValue), "Payment = assetInOffered + executorFee + stakeValue");
            TransferHelper.safeTransferETH(stakeAddress, stakeValue);
        }
        else {
            require(payment == executorFee, "Transaction value must match executorFee");
            if (orderType == OrderType.TokensForEth) { require(assetOut == uniswapRouter.WETH9(), "Use WETH as the assetOut"); }
            TransferHelper.safeTransferFrom(assetIn, msg.sender, address(this), assetInOffered);
        }
        
        
        uint orderId = ordersNum;
        ordersNum++;
        
        orderBook[orderId] = Order(OrderState.Created, orderType, msg.sender, assetIn, assetOut, assetInOffered, 
        assetOutExpected, executorFee, stakeValue, orderId, orders.length, poolFee);
        
        ordersForAddress[msg.sender].push(orderId);
        orders.push(orderId);
        
        emit logOrderCreated(
            orderId, 
            OrderState.Created, 
            orderType, 
            msg.sender, 
            assetIn, 
            assetOut,
            assetInOffered, 
            assetOutExpected, 
            executorFee,
            poolFee
        );
    }
    
    function executeOrder(uint orderId) external returns (uint) {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Finished);
    
        uint swapResult;
        
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: order.assetIn,
                tokenOut: order.assetOut,
                fee: order.poolFee,
                recipient: order.traderAddress,
                deadline: block.timestamp,
                amountIn:  order.assetInOffered,
                amountOutMinimum: order.assetOutExpected,
                sqrtPriceLimitX96: 0
            });    
        
        if (order.orderType == OrderType.EthForTokens) {
            swapResult = uniswapRouter.exactInputSingle{ value: order.assetInOffered }(params);
            TransferHelper.safeTransferETH(stakeAddress, order.stake.mul(STAKE_PERCENTAGE).div(100));
            TransferHelper.safeTransferETH(owAddress, order.stake.mul(100-STAKE_PERCENTAGE).div(100));
        } else {
            TransferHelper.safeApprove(order.assetIn, address(uniswapRouter), order.assetInOffered);
            swapResult = uniswapRouter.exactInputSingle(params);
        }
        
        TransferHelper.safeTransferETH(msg.sender, order.executorFee);
        emit logOrderExecuted(order.id, msg.sender, swapResult);
        
        return swapResult;
    }
    
    function cancelOrder(uint orderId) external {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(msg.sender == order.traderAddress, 'This order is not yours');
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Cancelled);
        
        uint refundETH = 0;
        uint refundToken = 0;
        
        if (order.orderType != OrderType.EthForTokens) {
            refundETH = order.executorFee;
            refundToken = order.assetInOffered;
            TransferHelper.safeTransferETH(order.traderAddress, refundETH);
            TransferHelper.safeTransfer(order.assetIn, order.traderAddress, refundToken);
        }
        else {
            refundETH = order.assetInOffered.add(order.executorFee).add(order.stake);
            TransferHelper.safeTransferETH(order.traderAddress, refundETH);  
        }
        
        emit logOrderCancelled(order.id, order.traderAddress, order.assetIn, order.assetOut, refundETH, refundToken);        
    }
    
    function calculatePaymentETH(uint ethValue) external view returns (uint valueEth, uint stake, uint executorFee, uint total) {
        uint pay = ethValue;
        uint stakep = pay.mul(STAKE_FEE).div(1000);
        uint totalp = (pay.add(stakep).add(EXECUTOR_FEE));
        return (pay, stakep, EXECUTOR_FEE, totalp);
    }
    
    function getOrdersLength() external view returns (uint) {
        return orders.length;
    }
    
    function getOrdersForAddressLength(address _address) external view returns (uint)
    {
        return ordersForAddress[_address].length;
    }

    function getOrderIdForAddress(address _address, uint index) external view returns (uint)
    {
        return ordersForAddress[_address][index];
    }    
    
    receive() external payable {}
}
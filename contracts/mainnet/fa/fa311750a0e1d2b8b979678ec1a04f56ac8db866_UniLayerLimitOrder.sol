// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

contract UniLayerLimitOrder is Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Factory public immutable uniswapV2Factory;
    
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
        uint executorFee
    );
    event logOrderCancelled(uint id, address payable traderAddress, address assetIn, address assetOut, uint refundETH, uint refundToken);
    event logOrderExecuted(uint id, address executor, uint[] amounts);
    
    mapping(uint => Order) public orderBook;
    mapping(address => uint[]) private ordersForAddress;
    
    constructor(IUniswapV2Router02 _uniswapV2Router) {
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
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
    
    function getPair(address tokenA, address tokenB) internal view returns (address) {
        address _tokenPair = uniswapV2Factory.getPair(tokenA, tokenB);
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
    
    function createOrder(OrderType orderType, address assetIn, address assetOut, uint assetInOffered, uint assetOutExpected, uint executorFee) external payable {
        
        uint payment = msg.value;
        uint stakeValue = 0;
        
        require(assetInOffered > 0, "Asset in amount must be greater than 0");
        require(assetOutExpected > 0, "Asset out amount must be greater than 0");
        require(executorFee >= EXECUTOR_FEE, "Invalid fee");
        
        if(orderType == OrderType.EthForTokens) {
            require(assetIn == uniswapV2Router.WETH(), "Use WETH as the assetIn");
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            require(payment == assetInOffered.add(executorFee).add(stakeValue), "Payment = assetInOffered + executorFee + stakeValue");
            TransferHelper.safeTransferETH(stakeAddress, stakeValue);
        }
        else {
            require(payment == executorFee, "Transaction value must match executorFee");
            if (orderType == OrderType.TokensForEth) { require(assetOut == uniswapV2Router.WETH(), "Use WETH as the assetOut"); }
            TransferHelper.safeTransferFrom(assetIn, msg.sender, address(this), assetInOffered);
        }
        
        
        uint orderId = ordersNum;
        ordersNum++;
        
        orderBook[orderId] = Order(OrderState.Created, orderType, msg.sender, assetIn, assetOut, assetInOffered, 
        assetOutExpected, executorFee, stakeValue, orderId, orders.length);
        
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
            executorFee
        );
    }
    
    function executeOrder(uint orderId) external returns (uint[] memory) {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Finished);
    
        address[] memory pair = new address[](2);
        pair[0] = order.assetIn;
        pair[1] = order.assetOut;

        uint[] memory swapResult;
        
        if (order.orderType == OrderType.EthForTokens) {
            swapResult = uniswapV2Router.swapExactETHForTokens{value:order.assetInOffered}(order.assetOutExpected, pair, order.traderAddress, block.timestamp);
            TransferHelper.safeTransferETH(stakeAddress, order.stake.mul(STAKE_PERCENTAGE).div(100));
            TransferHelper.safeTransferETH(owAddress, order.stake.mul(100-STAKE_PERCENTAGE).div(100));
        } 
        else if (order.orderType == OrderType.TokensForEth) {
            TransferHelper.safeApprove(order.assetIn, address(uniswapV2Router), order.assetInOffered);
            swapResult = uniswapV2Router.swapExactTokensForETH(order.assetInOffered, order.assetOutExpected, pair, order.traderAddress, block.timestamp);
        }
        else if (order.orderType == OrderType.TokensForTokens) {
            TransferHelper.safeApprove(order.assetIn, address(uniswapV2Router), order.assetInOffered);
            swapResult = uniswapV2Router.swapExactTokensForTokens(order.assetInOffered, order.assetOutExpected, pair, order.traderAddress, block.timestamp);
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
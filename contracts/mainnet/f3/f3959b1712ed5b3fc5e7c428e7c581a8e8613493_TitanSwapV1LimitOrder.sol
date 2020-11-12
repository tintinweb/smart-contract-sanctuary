/**
 *Submitted for verification at Etherscan.io on 2020-09-22
*/

pragma solidity =0.6.6;


interface ITitanSwapV1LimitOrder {
    
     // event Transfer(address indexed from, address indexed to, uint value);
     event Deposit(uint orderId,address indexed pair,address indexed user,uint amountIn,uint amountOut,uint fee);
    
     function setDepositAccount(address) external;
     function depositExactTokenForTokenOrder(address sellToken,address pair,uint amountIn,uint amountOut) external payable; 
     // deposit swapExactEthForTokens
     function depositExactEthForTokenOrder(address pair,uint amountIn,uint amountOut) external payable;
      // deposit swapExactTokenForETH
     function depositExactTokenForEth(address sellToken,address pair,uint amountIn,uint amountOut) external payable;
     
     function cancelTokenOrder(uint orderId) external; 
   
     
     function executeExactTokenForTokenOrder(uint orderId, address[] calldata path, uint deadline) external;
     function executeExactETHForTokenOrder(uint orderId, address[] calldata path, uint deadline) external payable;
     function executeExactTokenForETHOrder(uint orderId, address[] calldata path, uint deadline) external;
      
     
     function queryOrder(uint orderId) external view returns(address,address,uint,uint,uint);
     function existOrder(uint orderId) external view returns(bool);
     function withdrawFee(address payable to) external;
     function setEthFee(uint _ethFee) external;
    
   
    
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract TitanSwapV1LimitOrder is ITitanSwapV1LimitOrder {
    
    using SafeMath for uint;
    address public  depositAccount;
    address public immutable router;
    address public immutable  WETH;
    address public immutable factory;
    uint public userBalance;
    mapping (uint => Order) private depositOrders;
    // to deposit order count
    uint public orderCount;
    // total order count
    uint public orderIds;
    // eth fee,defualt 0.01 eth
    uint public ethFee = 10000000000000000;
   
    constructor(address _router,address _depositAccount,address _WETH,address _factory,uint _ethFee) public{
        router = _router;
        depositAccount = _depositAccount;
        WETH = _WETH;
        factory = _factory;
        ethFee = _ethFee;
    }
    
   
    
    struct Order {
        bool exist;
        address pair;
        address payable user; // 用户地址
        address sellToken;
        // uint direct; // 0 或 1,默认根据pair的token地址升序排,0- token0, token1 1- token1 token0
        uint amountIn;
        uint amountOut;
        uint ethValue;
       
    }
    
     function setDepositAccount(address _depositAccount)  external override{
        require(msg.sender == depositAccount, 'TitanSwapV1: FORBIDDEN');
        depositAccount = _depositAccount;
    }
    

    function depositExactTokenForTokenOrder(address sellToken,address pair,uint amountIn,uint amountOut) external override payable {
        // call swap method cost fee.
        uint fee = ethFee;
        require(msg.value >= fee,"TitanSwapV1 : no fee enough");
        orderIds = orderIds.add(1);
        uint _orderId = orderIds;
        // need transfer eth fee. need msg.sender send approve trx first.
        TransferHelper.safeTransferFrom(sellToken,msg.sender,address(this),amountIn);
       
        depositOrders[_orderId] = Order(true,pair,msg.sender,sellToken,amountIn,amountOut,msg.value);
        emit Deposit(_orderId,pair,msg.sender,amountIn,amountOut,msg.value);
        orderCount = orderCount.add(1);
        userBalance = userBalance.add(msg.value);
    }
    
     function depositExactEthForTokenOrder(address pair,uint amountIn,uint amountOut) external override payable {
        uint fee = ethFee;
        uint calFee = msg.value.sub(amountIn);
        require(calFee >= fee,"TitanSwapV1 : no fee enough");
        
        orderIds = orderIds.add(1);
        uint _orderId = orderIds;
        
        depositOrders[_orderId] = Order(true,pair,msg.sender,address(0),amountIn,amountOut,msg.value);
        emit Deposit(_orderId,pair,msg.sender,amountIn,amountOut,msg.value);
        orderCount = orderCount.add(1);
        userBalance = userBalance.add(msg.value);
     }
     
      function depositExactTokenForEth(address sellToken,address pair,uint amountIn,uint amountOut) external override payable {
        uint fee = ethFee;
        require(msg.value >= fee,"TitanSwapV1 : no fee enough");
        orderIds = orderIds.add(1);
        uint _orderId = orderIds;
        
         // need transfer eth fee. need msg.sender send approve trx first.
        TransferHelper.safeTransferFrom(sellToken,msg.sender,address(this),amountIn);
        depositOrders[_orderId] = Order(true,pair,msg.sender,sellToken,amountIn,amountOut,msg.value);
        emit Deposit(_orderId,pair,msg.sender,amountIn,amountOut,msg.value);
        orderCount = orderCount.add(1);
        userBalance = userBalance.add(msg.value);
      }
     
     
     
    
    function cancelTokenOrder(uint orderId) external override {
        Order memory order = depositOrders[orderId];
        require(order.exist,"order not exist.");
        require(msg.sender == order.user,"no auth to cancel.");
        
        // revert eth
        TransferHelper.safeTransferETH(order.user,order.ethValue);
        
        if(order.sellToken != address(0)) {
            // revert token
            TransferHelper.safeTransfer(order.sellToken,order.user,order.amountIn);
        }
        
        userBalance = userBalance.sub(order.ethValue);
      
        delete(depositOrders[orderId]);
        orderCount = orderCount.sub(1);
    }
    
    function queryOrder(uint orderId) external override view returns(address,address,uint,uint,uint) {
        Order memory order = depositOrders[orderId];
        return (order.pair,order.user,order.amountIn,order.amountOut,order.ethValue);
    }
    
    function existOrder(uint orderId) external override view returns(bool) {
        return depositOrders[orderId].exist;
    }
    
     function executeExactTokenForTokenOrder(
        uint orderId,
        address[] calldata path,
        uint deadline
   ) external override {
       require(msg.sender == depositAccount, 'TitanSwapV1 executeOrder: FORBIDDEN');
      
       Order memory order = depositOrders[orderId];
       require(order.exist,"order not exist!");
       // approve to router 
       TransferHelper.safeApprove(path[0],router,order.amountIn);
   
       
       delete(depositOrders[orderId]);
       orderCount = orderCount.sub(1);
       userBalance = userBalance.sub(order.ethValue);
       
       ITitanSwapV1Router01(router).swapExactTokensForTokens(order.amountIn,order.amountOut,path,order.user,deadline);
    }
    
     // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    
    function executeExactETHForTokenOrder(uint orderId, address[] calldata path, uint deadline) external override payable {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        require(msg.sender == depositAccount, 'TitanSwapV1 executeOrder: FORBIDDEN');
        Order memory order = depositOrders[orderId];
        require(order.exist,"order not exist!");
        delete(depositOrders[orderId]);
        orderCount = orderCount.sub(1);
        
        userBalance = userBalance.sub(order.ethValue);
        // call with msg.value = amountIn
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint[]  memory amounts = UniswapV2Library.getAmountsOut(factory, order.amountIn, path);
        require(amounts[amounts.length - 1] >= order.amountOut, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWETH(WETH).deposit{value: order.amountIn}();
         assert(IWETH(WETH).transfer(order.pair, amounts[0]));
        _swap(amounts, path, order.user);
    }
    
    
    function executeExactTokenForETHOrder(uint orderId, address[] calldata path, uint deadline) external override {
         require(msg.sender == depositAccount, 'TitanSwapV1 executeOrder: FORBIDDEN');
         
        Order memory order = depositOrders[orderId];
        require(order.exist,"order not exist!");
        // approve to router 
        TransferHelper.safeApprove(path[0],router,order.amountIn);
        delete(depositOrders[orderId]);
        orderCount = orderCount.sub(1);
        userBalance = userBalance.sub(order.ethValue);
        ITitanSwapV1Router01(router).swapExactTokensForETH(order.amountIn,order.amountOut,path,order.user,deadline);
    }
    
    
    function withdrawFee(address payable to) external override {
        require(msg.sender == depositAccount, 'TitanSwapV1 : FORBIDDEN');
        uint amount = address(this).balance.sub(userBalance);
        require(amount > 0,'TitanSwapV1 : amount = 0');
        TransferHelper.safeTransferETH(to,amount);
    }
    
    function setEthFee(uint _ethFee) external override {
        require(msg.sender == depositAccount, 'TitanSwapV1 : FORBIDDEN');
        require(_ethFee >= 10000000,'TitanSwapV1: fee wrong');
        ethFee = _ethFee;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface ITitanSwapV1Router01 {
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

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = IUniswapV2Factory(factory).getPair(tokenA,tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
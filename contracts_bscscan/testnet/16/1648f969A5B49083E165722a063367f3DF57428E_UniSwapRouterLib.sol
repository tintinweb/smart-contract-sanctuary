/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// File: contracts/PhoenixModules/modules/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    uint256 constant internal calDecimal = 1e18;
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// File: contracts/PhoenixModules/ERC20/IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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





pragma solidity =0.5.16;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }


}

// File: contracts/uniswap/IUniswapV2Router02.sol

pragma solidity =0.5.16;


interface IUniswapV2Router02 {
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



pragma solidity =0.5.16;
interface ILeveragePool {
    function libBorrow(address token, uint256 amount) external returns(uint256);
    function libRepay(address token, uint256 amount) external payable;
}



// File: contracts/PHXSwapRouter/UniSwapRouter.sol

pragma solidity =0.5.16;



contract UniSwapRouterLib {

    constructor()public{}

    uint256 constant internal calDecimal = 1e18;
    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Brrow(address indexed to, uint256 amount);
    event Repay(address indexed from, uint256 amount);
    using SafeMath for uint256;
    using SafeToken for address;

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function getSwapPath(address swapRouter,address token0,address token1) public pure returns (address[] memory path){
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        path = new address[](2);
        path[0] = token0 == address(0) ? IUniswap.WETH() : token0;
        path[1] = token1 == address(0) ? IUniswap.WETH() : token1;
    }
    function calSlit(address swapRouter,address token0,address token1,uint256 sellAmount,uint256[2] memory prices,uint8 id)public view returns (uint256){
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        if(sellAmount>0){
            address[] memory path = getSwapPath(swapRouter,token0,token1);
            uint[] memory amounts = IUniswap.getAmountsOut(sellAmount, path);
            //emit Swap(swapRouter,address(0x22),amounts[0],amounts[1]);
            if(amounts[amounts.length-1]>0){
                return amounts[amounts.length-1].mulPrice(prices,id)/amounts[0];
            }
        }
        return calDecimal;
    }
    function getAmountIn(address swapRouter,address token0,address token1,uint256 amountOut) public view returns (uint256){
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        address[] memory path = getSwapPath(swapRouter,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsIn(amountOut, path);
        return amounts[0];
    }
    function _swap(address _leveragePool, address swapRouter,address token0,address token1,uint256 amount0) public returns (uint256) {
        // (1) 先授权 （2） 后借钱 （3）执行兑换 （4） 把钱还给借钱方
        // todo : lib 工厂合约在代币中授权给路由合约操作
        if (token0 != address(0)){
            safeApprove(token0, address(swapRouter), uint256(-1));
        }
        if (token1 != address(0)){
            safeApprove(token1, address(swapRouter), uint256(-1));
        }
        // todo : 借钱，向杠杆池借取需要兑换的资金, 根据路径判断需要借取的币种名称和数量, 借普通代币和燃料币
        ILeveragePool leveragePool = ILeveragePool(_leveragePool);
        if (token0 == address(0)){
            amount0 = amount0.div(calDecimal);
        }
        leveragePool.libBorrow(token0, amount0);
        emit Brrow(token0, amount0);
        // todo : 执行兑换
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        address[] memory path = getSwapPath(swapRouter,token0,token1);
        uint256[] memory amounts;
        if(token0 == address(0)){
            amounts = IUniswap.swapExactETHForTokens.value(amount0)(0, path,address(_leveragePool), now+30);
        }else if(token1 == address(0)){
            amounts = IUniswap.swapExactTokensForETH(amount0,0, path, address(_leveragePool), now+30);
        }else{
            amounts = IUniswap.swapExactTokensForTokens(amount0,0, path, address(_leveragePool), now+30);
        }
        emit Swap(token0,token1,amounts[0],amounts[amounts.length-1]);
        // todo: 还钱，把兑换得到的钱还给杠杆池
//        // 新增授权操作，lib需要授权给杠杆池才能进行还款操作
//        if (token1 != address(0)){
//            token1.safeApprove(address(_leveragePool), uint256(-1));
//        }
//        leveragePool.libRepay(token1, amounts[amounts.length-1]);
//        emit Repay(token1, amounts[amounts.length-1]);
        return amounts[amounts.length-1];
    }
    function calRate(address swapRouter,address token0,address token1,uint256 sellBig,uint256 sellSmall,uint256[2] memory prices,uint8 id) public view returns (uint256){
        if(sellBig == 0){
            return calDecimal;
        }
        uint256 slit = calSlit(swapRouter,token0,token1,sellBig - sellSmall,prices,id);
        //(Xl + Xg*s)/(Xg+Xl*s)
        uint256 rate = sellSmall.mul(calDecimal).add(sellBig.mul(slit)).mul(calDecimal)/(sellBig.mul(calDecimal).add(sellSmall.mul(slit)));
        return rate;
    }
    function swapRebalance(address _leveragePool,address swapRouter,address token0,address token1,uint256 amountLev,uint256 amountHe,uint256[2] memory prices,uint256 id)payable public returns (uint256,uint256){
        uint256 key = (id>>128);
        if (key == 0){
            uint256 vulue = swapBuyAndBuy(_leveragePool,swapRouter,token0,token1,amountLev,amountHe,prices);
            return (vulue,0);
        }else if(key == 1){
            return swapSellAndSell(_leveragePool,swapRouter,token0,token1,amountLev,amountHe,prices);
        }else{
            uint256 vulue = swapBuyAndSell(_leveragePool,swapRouter,token0,token1,amountLev,amountHe,prices,uint8(id));
            return (vulue,0);
        }
    }
    function swapBuyAndBuySub(address _leveragePool,address swapRouter,address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] memory prices,uint8 id) public returns (uint256){
        uint256 rate = calRate(swapRouter,token0,token1,buyLev,buyHe,prices,id);
        buyHe = buyHe.mul(rate)/calDecimal;
        if (buyLev*100 > buyHe*101){
            buyLev = buyLev - buyHe;
            return _swap(_leveragePool,swapRouter,token0,token1,buyLev);
        }else{
            return 0;
        }
    }
    function swapBuyAndBuy(address _leveragePool,address swapRouter,address token0,address token1,uint256 buyLev,uint256 buyHe,uint256[2] memory prices) payable public returns (uint256){
        uint256 buyLev1 = buyLev.mul(calDecimal);
        uint256 buyHe1 = buyHe.mulPrice(prices, 0);
        if(buyLev1 >= buyHe1){
            return swapBuyAndBuySub(_leveragePool,swapRouter,token0,token1,buyLev,buyHe1/calDecimal,prices,0);
        }else{
            return swapBuyAndBuySub(_leveragePool,swapRouter,token1,token0,buyHe,buyLev1.divPrice(prices,0),prices,1);
        }
    }
    function swapSellAndSellSub(address _leveragePool,address swapRouter,address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] memory prices,uint8 id)
        public returns (uint256,uint256){
        uint256 rate = calRate(swapRouter,token0,token1,sellLev,sellHe,prices,id);
        uint256 selltemp = sellLev.mul(calDecimal)/rate;
        if (selltemp*100 > sellHe*101){
            selltemp = selltemp - sellHe;
            selltemp = _swap(_leveragePool,swapRouter,token0,token1,selltemp);
            return (selltemp.add(sellHe.mul(calDecimal*calDecimal).divPrice(prices,id)/rate),sellHe);
        }else{
            return (sellHe.mul(calDecimal*calDecimal).divPrice(prices,id)/rate,sellHe);
        }
    }
    function swapSellAndSell(address _leveragePool,address swapRouter,address token0,address token1,uint256 sellLev,uint256 sellHe,uint256[2] memory prices) payable public returns (uint256,uint256){
        uint256 sellLev1 = sellLev.mul(calDecimal);
        uint256 sellHe1 = sellHe.mulPrice(prices, 0);
        if(sellLev1 >= sellHe1){
            (sellLev,sellHe) = swapSellAndSellSub(_leveragePool,swapRouter,token1,token0,sellLev1.divPrice(prices,0),sellHe,prices,1);
        }else{
            (sellHe,sellLev) = swapSellAndSellSub(_leveragePool,swapRouter,token0,token1,sellHe1/calDecimal,sellLev,prices,0);
        }
        return (sellLev,sellHe);
    }
    function swapBuyAndSell(address _leveragePool,address swapRouter,address token0,address token1,uint256 buyAmount,uint256 sellAmount,uint256[2] memory prices,uint8 id)payable public returns (uint256){
        uint256 amountSell = sellAmount > 0 ? getAmountIn(swapRouter,token0,token1,sellAmount) : 0;
        return _swap(_leveragePool,swapRouter,token0,token1,buyAmount.add(amountSell));
    }
    function sellExactAmount(address _leveragePool,address swapRouter,address token0,address token1,uint256 amountout) payable public returns (uint256,uint256){
        uint256 amountSell = amountout > 0 ? getAmountIn(swapRouter,token0,token1,amountout) : 0;
        return (amountSell,_swap(_leveragePool,swapRouter,token0,token1,amountSell));
    }
    function swap(address _leveragePool, address swapRouter,address token0,address token1,uint256 amountSell) payable public returns (uint256){
        return _swap(_leveragePool,swapRouter,token0,token1,amountSell);
    }

}
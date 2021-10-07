/**
 *Submitted for verification at polygonscan.com on 2021-10-07
*/

pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

interface IToken {
    function comptroller() external view returns (address);

    function redeem(uint redeemTokens) external returns (uint);

    function underlying() external view returns (address);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);

    function symbol() external view returns (bytes32);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);
}

interface IEthToken is IToken {
    function liquidateBorrow(address borrower, address collateral) external payable;
}

interface IErcToken is IToken {
    function liquidateBorrow(address borrower, uint repayAmount, address collateral) external returns (uint);
}

interface IComptroller {
    function closeFactorMantissa() external view returns (uint256);

    function liquidationIncentiveMantissa() external view returns (uint);

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function getAssetsIn(address account) external view returns (address[] memory);

    function checkMembership(address account, address cToken) external view returns (bool);

    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint repayAmount) external view returns (uint, uint);

    function oracle() external view returns (address);
}

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}


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


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract OecCherryLiquidateLendsV4 {

    using SafeERC20 for IERC20;
    using Address for address;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public owner;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    address public WETH;
    address public defaultAgainstToken;

    address public liquidateLends;
    mapping(address => bool) public ethMarkets;
    address[] public baseTokens;


    struct LiquidateVar{
        address borrower;
        address collateralMarket;
        address borrowMarket;
        uint repayAmount;
        address collateralToken;
        address borrowToken;
        bool    isEthCollateralMarket;
        bool    isEthBorrowMarket;
    }

    constructor(address _router, address _defaultAgainstToken,address[] memory _ethMarkets,address[] memory _baseTokens,address _liquidateLends) {
        owner = msg.sender;
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        WETH = router.WETH();
        
        setEthMarkets(_ethMarkets,true);
        setDefaultAgainstToken(_defaultAgainstToken);
        setBaseTokens(_baseTokens);
        setLiquidateLends(_liquidateLends);
    }

    

    function liquidate(address borrower, address collateralMarket, address borrowMarket, uint repayAmount) external {
        
        LiquidateVar memory vars;
        vars.borrower = borrower;
        vars.collateralMarket = collateralMarket;
        vars.borrowMarket = borrowMarket;
        vars.repayAmount = repayAmount;

        if(vars.repayAmount == 0){
            vars.repayAmount = _getRepayAmount(borrower, collateralMarket, borrowMarket);
        }

        if(_isEthMarket(borrowMarket)){
            vars.borrowToken = WETH;
            vars.isEthBorrowMarket = true;
        }else{
            vars.borrowToken = IErcToken(borrowMarket).underlying();
            vars.isEthBorrowMarket = false;
        }

        if(_isEthMarket(collateralMarket)){
            vars.collateralToken = WETH;
            vars.isEthCollateralMarket = true;
        }else{
            vars.collateralToken = IErcToken(collateralMarket).underlying();
            vars.isEthCollateralMarket = false;
        }
        
        (IUniswapV2Pair borrowPair, uint amount) = _getBorrowPair(vars.borrowToken, vars.collateralToken, vars.repayAmount);
        vars.repayAmount = amount;
        
        uint amount0 = borrowPair.token0() == vars.borrowToken ? amount : 0;
        uint amount1 = borrowPair.token1() == vars.borrowToken ? amount : 0;
        address collateralToken = vars.isEthCollateralMarket ? ETH : vars.collateralToken;
        address borrowToken = vars.isEthBorrowMarket ? ETH : vars.borrowToken;
        bytes memory data = abi.encode(
            vars.borrower, 
            vars.collateralMarket, 
            vars.borrowMarket, 
            vars.repayAmount, 
            vars.collateralToken, 
            vars.borrowToken,
            vars.isEthCollateralMarket,
            vars.isEthBorrowMarket
            );
        borrowPair.swap(amount0, amount1, address(this), data);

        withdrawal(vars.borrowToken, payable(owner), 0);
        withdrawal(vars.collateralToken, payable(owner), 0);
        withdrawal(defaultAgainstToken, payable(owner), 0);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {

        require(msg.sender == factory.getPair(IUniswapV2Pair(msg.sender).token0(), IUniswapV2Pair(msg.sender).token1()));

        (address borrower, 
        address collateralMarket, 
        address borrowMarket,
        uint amount,
        address collateralToken, 
        address borrowToken,
        bool isEthCollateralMarket,
        bool isEthBorrowMarket) = abi.decode(data, (address, address, address, uint, address, address, bool, bool));

        if (isEthBorrowMarket) {
            IWETH(WETH).withdraw(amount);
        }


        IERC20(borrowToken).safeApprove(liquidateLends,amount);
        bytes memory callData = abi.encodeWithSignature("doLiquidate(address,address,address,uint256,address,address)", 
            borrower, 
            collateralMarket, 
            borrowMarket, 
            amount, 
            isEthCollateralMarket ? ETH : collateralToken, 
            isEthBorrowMarket ? ETH : borrowToken
        );
        liquidateLends.call(callData);
        
        
        if (isEthCollateralMarket) {
            IWETH(WETH).deposit{value : address(this).balance}();
        }

        _payBackPair(msg.sender, amount0, amount1, borrowToken, collateralToken);
    }

    function _getRepayAmount(address borrower, address collateralMarket, address borrowMarket) public returns (uint256){
        bytes memory data = abi.encodeWithSignature("calculateLiquidateAmount(address,address,address)", borrower, collateralMarket,borrowMarket);
        (bool success, bytes memory returnData) = liquidateLends.staticcall(data);
        if (success) {
            return abi.decode(returnData, (uint256));
        } else {
            return 0;
        }
    }


    function _getBorrowPair(address borrowToken, address collateralToken, uint repayAmount) internal view returns (IUniswapV2Pair, uint){

        IUniswapV2Pair borrowPair;
        uint[] memory _tmpMaxFlashLoan = new uint[](2);

        // 获得 borrowToken-collateralToken 的交易对，如果存在且流动性可以，那么就直接使用。
        borrowPair = IUniswapV2Pair(factory.getPair(borrowToken, collateralToken));
        if (address(borrowPair) != address(0)) {
            uint maxFlashLoan = _maxFlashLoanInternal(address(borrowPair), borrowToken);
            if (maxFlashLoan > repayAmount) {
                return (borrowPair, repayAmount);
            }
            _tmpMaxFlashLoan[0] = maxFlashLoan;
        }

        // 获得 borrowToken-defaultAgainstToken 的交易对，如果存在且流动性可以，那么就直接使用。
        if (borrowToken != defaultAgainstToken) {
            borrowPair = IUniswapV2Pair(factory.getPair(borrowToken, defaultAgainstToken));
        } else {
            borrowPair = IUniswapV2Pair(factory.getPair(borrowToken, WETH));
        }
        if (address(borrowPair) != address(0)) {
            uint maxFlashLoan = _maxFlashLoanInternal(address(borrowPair), borrowToken);
            if (maxFlashLoan > repayAmount) {
                return (borrowPair, repayAmount);
            }
            _tmpMaxFlashLoan[1] = maxFlashLoan;
        }

        // 1. _tmpMaxFlashLoan[0]有值，那么就使用 borrowToken-collateralToken 交易对 和 它的最大借款额
        // 2. 如果_tmpMaxFlashLoan[1] > 0， 那么就使用 borrowToken-defaultAgainstToken 交易对 和 它的最大借款额
        if (_tmpMaxFlashLoan[0] > _tmpMaxFlashLoan[1]) {
            return (IUniswapV2Pair(factory.getPair(borrowToken, collateralToken)), _tmpMaxFlashLoan[0]);
        } else if (_tmpMaxFlashLoan[1] > 0) {
            return (borrowPair, _tmpMaxFlashLoan[1]);
        }

        require(address(borrowPair) != address(0), "not found borrowPair");

        return (borrowPair, repayAmount);
    }


    function _payBackPair(address pair, uint amount0, uint amount1, address borrowToken, address collateralToken) internal {

        uint amount = amount0 != 0 ? amount0 : amount1;
        uint seizedAmount = IERC20(collateralToken).balanceOf(address(this));

        //1. 如果 borrowToken == collateralToken 那么就不用做交易了
        if (borrowToken == collateralToken) {
            uint amountRequired = (amount * 1000 / 997) + 1;
            IERC20(borrowToken).safeTransfer(pair, amountRequired);
            return;
        }

        //2. 如果 borrowToken 和 collateralToken 在一个交易对，那么就直接使用 collateralToken 还
        if (pair == factory.getPair(borrowToken, collateralToken)) {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = IUniswapV2Pair(pair).token0() == borrowToken ? (reserve1, reserve0) : (reserve0, reserve1);
            uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);
            if(seizedAmount > amountRequired){
                IERC20(collateralToken).safeTransfer(pair, amountRequired);
                return;
            }            
        }

        //3. 计算在不包括闪电贷的pair外，最多能获得的交易金额以及路径；如果合适，就进行交易
        uint amountRequired = (amount * 1000 / 997) + 1;
        (uint amountOut,address[] memory path) = _getEstimateOut(collateralToken,borrowToken,seizedAmount,pair);
        if(amountOut > amountRequired){
            IERC20(collateralToken).safeApprove(address(router), seizedAmount);
            router.swapTokensForExactTokens(amountOut, seizedAmount, path, address(this), block.timestamp);
            IERC20(borrowToken).safeTransfer(pair, amountRequired);
            return;
        }

        //4. 如果 borrowToken 和 collateralToken 不在一个交易对，那么需要通过 collateralToken/USDT 将collateralToken交易为USDT，然后还USDT。
        if (borrowToken != defaultAgainstToken) {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = IUniswapV2Pair(pair).token0() == borrowToken ? (reserve1, reserve0) : (reserve0, reserve1);
            amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);
        }
        path = new address[](2);
        path[0] = collateralToken;
        path[1] = defaultAgainstToken;
        IERC20(collateralToken).safeApprove(address(router), seizedAmount);
        router.swapTokensForExactTokens(amountRequired, seizedAmount, path, address(this), block.timestamp);
        IERC20(defaultAgainstToken).safeTransfer(pair, amountRequired);

    }
    

    function _maxFlashLoanInternal(address pairAddress, address token) internal view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(pairAddress);
        if (balance > 0) {
            return balance - 1;
        }
        return 0;
    }


    function _getEstimateOut(address tokenIn, address tokenOut, uint256 amountIn, address ignorePair) internal view returns (uint256, address[] memory){

        uint256 resultAmount = 0;
        address[] memory resultPath;

        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == tokenIn || baseTokens[i] == tokenOut) {
                continue;
            }
            if (factory.getPair(tokenIn, baseTokens[i]) == address(0)) {
                continue;
            }
            if (factory.getPair(baseTokens[i], tokenOut) != address(0)) {
                address[] memory tempPath = new address[](3);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = tokenOut;
                if(factory.getPair(tempPath[0], tempPath[1]) == ignorePair || factory.getPair(tempPath[1], tempPath[2]) == ignorePair){
                    continue;
                }

                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }

            for (uint256 j = 0; j < baseTokens.length; j++) {
                if (baseTokens[i] == baseTokens[j]) {
                    continue;
                }
                if (baseTokens[j] == tokenIn || baseTokens[j] == tokenOut) {
                    continue;
                }
                if (factory.getPair(baseTokens[i], baseTokens[j]) == address(0)) {
                    continue;
                }
                if (factory.getPair(baseTokens[j], tokenOut) == address(0)) {
                    continue;
                }
                address[] memory tempPath = new address[](4);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = baseTokens[j];
                tempPath[3] = tokenOut;
                if(factory.getPair(tempPath[0], tempPath[1]) == ignorePair || factory.getPair(tempPath[1], tempPath[2]) == ignorePair || factory.getPair(tempPath[2], tempPath[3]) == ignorePair){
                    continue;
                }

                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }
   
        }

        return (resultAmount, resultPath);

    }


    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory) {
        bytes memory data = abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, path);
        (bool success, bytes memory returnData) = address(router).staticcall(data);
        if (success) {
            return abi.decode(returnData, (uint256[]));
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = 0;
            return result;
        }
    }


    function _isEthMarket(address _market) internal view returns (bool){
        return ethMarkets[_market];
    }

    // 设置eth代币
    function setEthMarkets(address[] memory tokens, bool status) public {
        require(msg.sender == owner);
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            ethMarkets[token] = status;
        }
    }
    
    // 设置默认中间代币
    function setDefaultAgainstToken(address _defaultAgainstToken) public {
        require(msg.sender == owner);
        defaultAgainstToken = _defaultAgainstToken;
    }

    // 设置基础代币
    function setBaseTokens(address[] memory tokens) public {
        require(msg.sender == owner);
        baseTokens = tokens;
    }

    // 设置清算合约
    function setLiquidateLends(address _liquidateLends) public {
        require(msg.sender == owner);
        liquidateLends = _liquidateLends;
    }

    function withdrawal(address asset, address payable to, uint amount) public {
        require(msg.sender == owner);
        if (amount == 0) {
            if (asset == ETH) {
                amount = address(this).balance;
            }
            amount = IERC20(asset).balanceOf(address(this));
        }
        
        if (asset == ETH) {
            (bool success,) = to.call{value : amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(asset).safeTransfer(to, amount);

    }

    function call(uint256 callType, address target, bytes memory data, uint256 value) external returns (bytes memory){
        if(callType == 1){
            return target.functionDelegateCall(data);
        }else if(callType == 2){
            return target.functionCallWithValue(data,value);
        }else if(callType == 3){
            return target.functionStaticCall(data);
        }
        return target.functionCall(data);
    }

    receive() payable external {}

}


contract LiquidateLends{

    using SafeERC20 for IERC20;
    using Address for address;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;


    function calculateLiquidateAmount(address borrower, address collateralMarket, address borrowMarket) public returns (uint256){

        IComptroller comptroller = _getComptroller(borrowMarket);

        uint closeFact = comptroller.closeFactorMantissa();
        uint liqIncent = comptroller.liquidationIncentiveMantissa();

        uint repayMax = IToken(borrowMarket).borrowBalanceCurrent(borrower) * closeFact / uint(10 ** 18);
        uint seizeMax = IErcToken(collateralMarket).balanceOfUnderlying(borrower) * uint(10 ** 18) / liqIncent;
        uint uPriceBorrow = _getUnderlyingPrice(borrowMarket);

        repayMax *= uPriceBorrow;
        seizeMax *= _getUnderlyingPrice(collateralMarket);

        return ((repayMax < seizeMax) ? repayMax : seizeMax) / uPriceBorrow;
    }

    function quickLiquidate(address borrower, address collateralMarket, address borrowMarket, uint repayAmount, bool isEthCollateral, bool isEthBorrow) public payable{

        if(repayAmount == 0){
            repayAmount = calculateLiquidateAmount(borrower, collateralMarket, borrowMarket);
        }
        address tokenCollateral = isEthCollateral ? ETH : IErcToken(collateralMarket).underlying();
        address tokenBorrow = isEthBorrow ? ETH : IErcToken(borrowMarket).underlying();

        doLiquidate(borrower,collateralMarket,borrowMarket,repayAmount,tokenCollateral,tokenBorrow);

    }

    function doLiquidate(address borrower, address collateralMarket, address borrowMarket, uint repayAmount, address tokenCollateral, address tokenBorrow) public payable{
        
        if(tokenBorrow != ETH){
            IERC20(tokenBorrow).safeTransferFrom(msg.sender, address(this), repayAmount);
        }
        
        _liquidateInternal(borrower,collateralMarket,borrowMarket,repayAmount,tokenCollateral,tokenBorrow);
        
        _transferInternal(tokenCollateral, payable(msg.sender), _balanceOfInternal(tokenCollateral));
    }

    function _liquidateInternal(address borrower, address collateralMarket, address borrowMarket, uint repayAmount, address tokenCollateral, address tokenBorrow) internal{

        _enterMarket(borrowMarket, collateralMarket);

        if (tokenBorrow == ETH) {
            IEthToken(borrowMarket).liquidateBorrow{value : repayAmount}(borrower, collateralMarket);
        } else {
            _approveInternal(IErcToken(borrowMarket).underlying(), borrowMarket, repayAmount);
            IErcToken(borrowMarket).liquidateBorrow(borrower, repayAmount, collateralMarket);
        }

        uint collateralBalance = IToken(collateralMarket).balanceOf(address(this));
        require(collateralBalance > 0, "collateralBalance is zero");
        IToken(collateralMarket).redeem(collateralBalance);

    }


    function _getComptroller(address market) internal view returns (IComptroller){
        return IComptroller(IToken(market).comptroller());
    }


    function _getUnderlyingPrice(address market) internal view returns (uint){
        IPriceOracle priceOracle = IPriceOracle(_getComptroller(market).oracle());
        return priceOracle.getUnderlyingPrice(market);
    }


    function _enterMarket(address tokenBorrow, address tokenCollateral) internal {
        address[] memory pTokens = new address[](2);
        pTokens[0] = tokenBorrow;
        pTokens[1] = tokenCollateral;
        _getComptroller(tokenBorrow).enterMarkets(pTokens);
    }


    function _balanceOfInternal(address asset) internal view returns (uint) {
        if (asset == ETH) {
            return address(this).balance;
        }
        return IERC20(asset).balanceOf(address(this));
    }


    function _transferInternal(address asset, address payable to, uint amount) internal {
        if(amount == 0) {
            return;
        }
        if (asset == ETH) {
            (bool success,) = to.call{value : amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(asset).safeTransfer(to, amount);
    }


    function _approveInternal(address asset, address spender, uint amount) internal {
        IERC20 erc20 = IERC20(asset);
        uint allowance = erc20.allowance(address(this), spender);
        if (allowance < amount) {
            erc20.safeApprove(spender, MAX_INT);
        }
    }

    function call(address target, bytes memory data, uint256 value,uint256 callType) external returns (bytes memory){
        if(callType == 1){
            return target.functionDelegateCall(data);
        }else if(callType == 2){
            return target.functionCallWithValue(data,value);
        }else if(callType == 3){
            return target.functionStaticCall(data);
        }
        return target.functionCall(data);
    }

    receive() payable external {}

}
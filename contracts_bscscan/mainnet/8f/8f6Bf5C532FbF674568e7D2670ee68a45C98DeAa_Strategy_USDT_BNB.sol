/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;


library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (~d+1);
        d /= pow2;
        l /= pow2;
        l += h * ((~pow2+1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}


library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


interface IWBNB is IERC20 {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function withdraw(uint wad) external;
}


interface IRouter {
    function factory() external view returns (address);
    function WBNB() external view returns (address);

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


interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function blockTimestampLast() external view returns (uint);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function MINIMUM_LIQUIDITY() external view returns (uint256);
    function mint(address to) external returns (uint256);
}


// ------------> Important interface for farm. Must be changed for every farm <--------------
interface IFarm{
    function cake() external view returns (address);
    function deposit(uint256 _pid, uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}


// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IPair(pair).price0CumulativeLast();
        price1Cumulative = IPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


contract Strategy_USDT_BNB {
    // This strategy is for FTM network. USDT - BNB pair. RewardToken = "spirit"
    using SafeERC20 for IERC20;
    using Address for address;
    using FixedPoint for *;

    uint256 public constant withdrawFee = 15; // 15%
    uint256 public constant toleranceLevelPercent = 1; // 1%
    uint256 private constant PERIOD = 10 seconds;
    uint256 private constant percentCheckDifference = 5;

    uint256 public pendingFee; // in wrapped tokens
    uint256 public pendingUSDTFee; // in USDT tokens
    uint256 public pendingRewardsFee; // in reward tokens from farm
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant yelLiquidityRouter = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    address public constant YELtoken = 0xD3b71117E6C1558c1553305b44988cd944e97300;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public token0; // BUSD-T
    address public token1; // WBNB
    address public vault;

    // ------------> Important constants <--------------
    uint256 public constant pid = 264;
    bool public constant hasPid = true;
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant lpToken = 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;
    address public constant farm = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    // ------------>        END          <--------------

    mapping(address => uint256) public pendingYel;
    uint private price0CumulativeLast;
    uint private price1CumulativeLast;
    uint32 private blockTimestampLast;
    uint256 public token1TWAP;
    uint256 public token0TWAP;
    uint256 public token1Price;
    uint256 public token0Price;

    event AutoCompound();
    event Earn(uint256 amount);
    event YELswapped(uint256 percent);
    event WithdrawFromStrategy(uint256 amount);
    event TakeFee(uint256 rewardsFeeInWBNB, uint256 amountWBNB);

    modifier onlyVault() {
        require(msg.sender == vault, "The sender is not vault");
        _;
    }

    constructor(address _vault) {
        require(_vault != address(0), "Vault can not be zero address");
        vault = _vault;
        token0 = IPair(lpToken).token0();
        token1 = IPair(lpToken).token1();

        _approveToken(lpToken, farm);
        _approveToken(WBNB, router);
        _approveToken(token0, router);
        _approveToken(token1, router);

        // fetch the current accumulated price value (1 / 0)
        price0CumulativeLast = IPair(lpToken).price0CumulativeLast();
        // fetch the current accumulated price value (0 / 1)
        price1CumulativeLast = IPair(lpToken).price1CumulativeLast();
        (,,blockTimestampLast) = IPair(lpToken).getReserves();
    }

    receive() external payable onlyVault {
        deposit();
    }

    // ------------> Important functions for farm <--------------
    function getRewardToken() public view returns (address){
        return IFarm(farm).cake();
    }

    function _withdrawFromFarm(uint256 _amount) internal {
        IFarm(farm).withdraw(pid, _amount);
    }

    function _getRewardsFromFarm() internal {
        IFarm(farm).leaveStaking(0);
    }

    function getAmountLPFromFarm() public view returns (uint256 amount) {
        (amount,) = IFarm(farm).userInfo(pid, address(this));
    }

    function withdrawUSDTFee(address _owner) public onlyVault {
        if(pendingUSDTFee > 0) {
            IERC20(USDT).transfer(_owner, pendingUSDTFee);
        }
    }
    
    function earn() public returns(uint256 _balance){
        _balance = getBalanceOfToken(lpToken);
        if(_balance > 0) {
            IFarm(farm).deposit(pid, _balance);
            emit Earn(getBalanceOfToken(lpToken));
        }
    }
    //  -------------------------> END <---------------------------

    // each farm has own autoCompound logic, pay attention 
    // what tokens can be returned from the farm
    function autoCompound() external {
        address[] memory path = new address[](2);
        uint256 amount = getAmountLPFromFarm();
        address rewardToken = getRewardToken();

        _approveToken(rewardToken, router);
        _approveToken(WBNB, router);
        _approveToken(USDT, router);

        if (amount > 0) {
            // rewards and LP
            _getRewardsFromFarm();

            uint256 _balance = getBalanceOfToken(rewardToken);
            if(_balance > 0){
                path[0] = rewardToken;
                path[1] = WBNB; // WFTM 
                amount = _getAmountsOut(_balance+pendingRewardsFee, path);
                if(amount > 100) {
                    _swapExactTokensForTokens(router, _balance+pendingRewardsFee, amount, path);
                    pendingRewardsFee = 0;
                } else{
                    pendingRewardsFee += _calculateAmountFee(_balance);
                }
                _takeFee();
            }
            _addLiquidityFromAllTokens();
            earn();
        }
        
        emit AutoCompound();
    }

    
    function claimYel(address _receiver) public onlyVault {
        uint256 yelAmount = getPendingYel(_receiver);
        if(yelAmount > 0) {
            _transfer(YELtoken, _receiver, yelAmount);
            pendingYel[_receiver] = 0;
        }
    }

    function emergencyWithdraw(address _receiver) public onlyVault {
        uint256 amount = getAmountLPFromFarm();
        address _token = getRewardToken();
        _withdrawFromFarm(amount);
        _transfer(lpToken, _receiver, getBalanceOfToken(lpToken));
        _transfer(_token, _receiver, getBalanceOfToken(_token));
        _transfer(USDT, _receiver, getBalanceOfToken(USDT));
        _transfer(WBNB, _receiver, getBalanceOfToken(WBNB));
    }

    function requestWithdraw(address _receiver, uint256 _percent) public onlyVault {
        if (getAmountLPFromFarm() > 0) {
            uint256 yelAmount = _swapToYELs(_percent);
            if(yelAmount > 0) {
                pendingYel[_receiver] += yelAmount;
            } 
            emit WithdrawFromStrategy(yelAmount);
        }
    }

    function migrate(uint256 _percent) public onlyVault {
        _swapLPtoWBNB(_percent * 10 ** 12);
        _transfer(WBNB, vault, getBalanceOfToken(WBNB));
    }

    function deposit() public payable onlyVault returns (uint256) {
        _approveToken(token0, router);
        _approveToken(token1, router);
        _updateAveragePrices();
        _addLiquidityFromETH(address(this).balance);
        uint256 lpBalance = earn();
        return _getSimpleTCI(lpBalance);
    }

    function depositAsMigrate() public onlyVault {
        require(getBalanceOfToken(WBNB) > 0, "Not enough WBNB to make migration");
        _approveToken(token0, router);
        _approveToken(token1, router);
        _approveToken(token0, lpToken);
        _approveToken(token1, lpToken);
        _approveToken(lpToken, farm);
        _approveToken(WBNB, router);
        _addLiquidityFromAllTokens();
        earn();
    }

    function setRouter(address _address) public onlyVault {
        require(_address != address(0), "The address can not be zero address");
        router = _address;
        _approveToken(WBNB, router);
        _approveToken(token0, router);
        _approveToken(token1, router);
    }

    function getTotalCapitalInternal() public view returns (uint256) {
        return _getSimpleTCI(getAmountLPFromFarm());
    }

    function getTotalCapital() public view returns (uint256) {
        return _getSimpleTC();
    }

    function getPendingYel(address _receiver) public view returns(uint256) {
        return pendingYel[_receiver];
    }

    function getBalanceOfToken(address _token) public view returns (uint256) {
        if(_token == USDT) {
            return IERC20(_token).balanceOf(address(this)) - pendingUSDTFee;
        }
        if(_token == WBNB) {
            return IERC20(_token).balanceOf(address(this)) - pendingFee;
        }
        if(_token == getRewardToken()) {
            return IERC20(_token).balanceOf(address(this)) - pendingRewardsFee;
        }
        return IERC20(_token).balanceOf(address(this));
    }

    function _getAmountsOut(uint256 _amount, address[] memory path) internal view returns (uint256){
        uint256[] memory amounts = IRouter(router).getAmountsOut(_amount, path);
        return amounts[amounts.length-1];
    }

    function _getTokenValues(
        uint256 _amountLP
    ) public view returns (uint256 token0Value, uint256 token1Value) {
        (uint256 _reserve0, uint256 _reserve1,) = IPair(lpToken).getReserves();
        uint256 LPRatio = _amountLP * 1e12 / IPair(lpToken).totalSupply();
        token0Value = LPRatio * _reserve0 / 1e12;
        token1Value = LPRatio * _reserve1 / 1e12;
    }

    function _transfer(address _token, address _to, uint256 _amount) internal {
        IERC20(_token).transfer(_to, _amount);
    }

    function _calculateAmountFee(uint256 amount) internal pure returns(uint256) {
        /*
        As the contract takes fee percent from the amount,
        so amount needs to multiple by percent and divide by 100

        example: amount = 50 LP, percent = 2%
        fee calculates: 50 * 2 / 100
        fee result: 1 LP
        */
        return (amount * withdrawFee) / 100;
    }

    function _approveToken(address _token, address _who) internal {
        IERC20(_token).safeApprove(_who, 0);
        IERC20(_token).safeApprove(_who, type(uint256).max);
    }

    function _takeFee() internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = USDT;
        uint256 rewardsFeeInWBNB = _calculateAmountFee(getBalanceOfToken(WBNB));
        if(rewardsFeeInWBNB > 0) {
            uint256 amount = _getAmountsOut(rewardsFeeInWBNB + pendingFee, path);
            if(amount > 100) {
                uint256 _balanceUSDT = getBalanceOfToken(USDT);
                _swapExactTokensForTokens(router, rewardsFeeInWBNB + pendingFee, amount, path);
                pendingUSDTFee += getBalanceOfToken(USDT) - _balanceUSDT;
                pendingFee = 0;
                emit TakeFee(rewardsFeeInWBNB, amount);
            } else {
                pendingFee += rewardsFeeInWBNB;
            }
        }
    }

    function _getLiquidityAmounts(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB,) = IPair(lpToken).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = IRouter(router).quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if(amountBOptimal >= amountBMin) {
                    (amountA, amountB) = (amountADesired, amountBOptimal);
                } else {
                    (amountA, amountB) = (0, 0);
                }
            } else {
                uint amountAOptimal = IRouter(router).quote(amountBDesired, reserveB, reserveA);
                if(amountAOptimal <= amountADesired && amountAOptimal >= amountAMin) {
                    (amountA, amountB) = (amountAOptimal, amountBDesired);
                } else {
                    (amountA, amountB) = (0, 0);
                }
            }
        }
    }

    function _addLiquidity(uint256 _desired0, uint256 _desired1) internal {
        if(_canAddLiquidity(_desired0, _desired1)) {
            _transfer(token0, lpToken, _desired0);
            _transfer(token1, lpToken, _desired1);
            IPair(lpToken).mint(address(this));
        }
    }

    function _addLiquidityFromAllTokens() internal {
        _swapWBNBToTokens();

        uint256 _balance0 = getBalanceOfToken(token0);
        uint256 _balance1 = getBalanceOfToken(token1);

        if(_balance0 > 100 && _balance1 > 100) {
            (uint256 amount0, uint256 amount1) = _getLiquidityAmounts(
                _balance0,
                _balance1,
                _balance0 - (_balance0*toleranceLevelPercent)/100,
                _balance1 - (_balance1*toleranceLevelPercent)/100
            );
            if(amount0 != 0 && amount1 !=0)
                _addLiquidity(amount0, amount1);
        }            
    }

    function _canAddLiquidity(uint256 amount0, uint256 amount1) internal view returns (bool) {
        (uint112 _reserve0, uint112 _reserve1,) = IPair(lpToken).getReserves(); // gas savings
        uint256 _totalSupply = IPair(lpToken).totalSupply();
        uint256 liquidity;
        uint256 minLiquidity = IPair(lpToken).MINIMUM_LIQUIDITY();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - minLiquidity;
        } else {
            liquidity = Math.min(
                amount0 * _totalSupply / _reserve0,
                amount1 * _totalSupply / _reserve1
            );
        }
        return liquidity > 0;
    }

    function _swapWBNBToTokens() internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        uint256 _balance = getBalanceOfToken(WBNB) / 2;
        if (_balance > 0) {
            path[1] = token0; // here should be not a wrapped token 
            uint256 amount = _getAmountsOut(_balance, path);
            if(amount > 100) {
                _swapExactTokensForTokens(router, _balance, amount, path);
            }
        }
    }

    function _removeLiquidity() internal {
        _approveToken(lpToken, router);
        IRouter(router).removeLiquidity(
            token0, // tokenA
            token1, // tokenB
            getBalanceOfToken(lpToken), // liquidity
            0, // amountAmin0
            0, // amountAmin1
            address(this), // to 
            block.timestamp + 1 minutes // deadline
        );
    }

    function updateTWAP() public onlyVault {
        _updateTWAP();
    }

    function _updateAveragePrices() internal {
        _updateTWAP();
        _check0Price();
        _check1Price();
    }

    function _updateTWAP() internal {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(lpToken));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        token0TWAP = uint256(FixedPoint
            .uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed))
            .mul(1e36)
            .decode144()) / 1e18;

        token1TWAP = uint256(FixedPoint
            .uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed))
            .mul(1e36)
            .decode144()) / 1e18;

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function _check0Price() internal {
        // check that price difference no more than 5 percent
        token0Price = _getTokenPrice();
        string memory msgError = "Prices have more than 5 percent difference for token0";
        if(token0TWAP >= token0Price) {
            require(100 - (token0Price * 100 / token0TWAP) <= percentCheckDifference, msgError);
        } else {
            require(100 - (token0TWAP * 100 / token0Price) <= percentCheckDifference, msgError);
        }
    }

    function _check1Price() internal {
        // check that price difference no more than 5 percent
        token1Price = _getTokenPrice1();
        string memory msgError = "Prices have more than 5 percent difference for token1";
        if(token1TWAP >= token1Price) {
            require(100 - (token1Price * 100 / token1TWAP) <= percentCheckDifference, msgError);
        } else {
            require(100 - (token1TWAP * 100 / token1Price) <= percentCheckDifference, msgError);
        }
    }

    function _swapExactETHForTokens(address _token, uint256 _amountETH) internal {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = WBNB;
        if(_token != WBNB) {
            path[1] = _token;
            amounts = IRouter(router).getAmountsOut(_amountETH/2, path);
            uint256 desiredAmountToken = amounts[1];
            if(desiredAmountToken > 100){
                IRouter(router).swapExactETHForTokens{value:_amountETH/2}(
                    desiredAmountToken - (desiredAmountToken*toleranceLevelPercent/100), // amountOutMin
                    path,
                    address(this),
                    block.timestamp + 1 minutes // deadline
                );
            }
        }
    }

    function _addLiquidityFromETH(uint256 _amountETH) internal {
        _swapExactETHForTokens(token0, _amountETH);
        __addLiquidityETH(token0, _amountETH / 2);
    }

    function __addLiquidityETH(address _token, uint256 desiredAmountETH) internal {
        uint256 desiredAmountToken = getBalanceOfToken(_token);
        (uint256 amount0, uint256 amount1) = _getLiquidityAmounts(
            desiredAmountETH,
            desiredAmountToken,
            desiredAmountETH - (desiredAmountETH*toleranceLevelPercent)/100,
            desiredAmountToken - (desiredAmountToken*toleranceLevelPercent)/100
        );
        if(amount0 != 0 && amount1 !=0 && _canAddLiquidity(amount0, amount1)) {
            _transfer(_token, lpToken, amount0); // here should not be a wrapped token 
            IWBNB(WBNB).deposit{value: amount1}(); // here should be wrapped token 
            IWBNB(WBNB).transfer(lpToken, amount1); // here should be wrapped token 
            IPair(lpToken).mint(address(this));
        }
    }

    function _swapLPtoWBNB(uint256 _percent) internal {
        uint256 _totalLP = getAmountLPFromFarm();
        if (_totalLP > 0) {
            _withdrawFromFarm((_percent * _totalLP) / (100 * 10 ** 12));
            address rewardToken = getRewardToken();

            _approveToken(rewardToken, router);
            _approveToken(WBNB, router);

            // swap rewards to WBNB
            _swapTokenToWBNB(rewardToken);

            // swap LPs to token0 and token1
            _removeLiquidity();

            // swap token to WBNB
            _swapTokenToWBNB(token0); // here should not be a wrapped token 
        }
    }

    function _swapTokenToWBNB(address _token) internal {
        address[] memory path = new address[](2);
        uint256[] memory amounts;
        // swap _token and token1 to WBNB
        path[1] = WBNB;
        if(_token != WBNB) {
            path[0] = _token;
            uint256 _balance = getBalanceOfToken(path[0]);
            if(_balance > 0) {
                amounts = IRouter(router).getAmountsOut(_balance, path);
                if(amounts[1] > 100) {
                    _swapExactTokensForTokens(router, _balance, amounts[1], path);
                }
            }
        }
    }

    function _swapToYELs(uint256 _percent) internal returns (uint256 newYelBalance){ 
        _swapLPtoWBNB(_percent);

        // swap to YEL
        uint256 _oldYelBalance = getBalanceOfToken(YELtoken);
        _approveToken(YELtoken, yelLiquidityRouter);
        _approveToken(WBNB, yelLiquidityRouter);
        _swapWBNBToToken(yelLiquidityRouter, YELtoken);
        // return an amount of YEL that the user can claim
        newYelBalance = getBalanceOfToken(YELtoken) - _oldYelBalance;
        emit YELswapped(newYelBalance);
    }

    function _swapWBNBToToken(address _router, address _token) internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = _token;
        uint256 _balanceWBNB = getBalanceOfToken(WBNB);
        uint256[] memory amounts = IRouter(_router).getAmountsOut(_balanceWBNB, path);
        if(amounts[1] > 100) {
            _swapExactTokensForTokens(_router, _balanceWBNB, amounts[1], path);  
        }
    }

    function _swapExactTokensForTokens(
        address _router,
        uint256 _amount,
        uint256 _amount2,
        address[] memory _path) internal {
        
        IRouter(_router).swapExactTokensForTokens(
            _amount,
            _amount2 - (_amount2*toleranceLevelPercent)/100,
            _path,
            address(this),
            block.timestamp+1 minutes
        );
    }

    function _getTokenPrice() internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return __getTokenPrice(path);
    }

    function _getTokenPrice1() internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        return __getTokenPrice(path);
    }

    function __getTokenPrice(address[] memory path) internal view returns (uint256) {
        return 1e36 / (_getAmountsOut(100 * 1e18, path) / 100);
    }
    

    function _getSimpleTCI(uint256 _amount) internal view returns (uint256 tCI) {
        uint256 d = 1e18;
        if(_amount > 0) {
            // t0V - token0 value
            // t1V - token1 value
            (uint256 t0V, uint256 t1V) = _getTokenValues(_amount);

            // calculates how many wrapped tokens for token0
            tCI = _getTokenPrice() * t0V / d + t1V;
        }

        // calculates total Capital from tokens that exist in the contract
        uint256 _balance = getBalanceOfToken(token0);
        if (_balance > 0) {
            tCI += _getTokenPrice() * _balance / d;
        }

        // calculates total Capital from Wrapped tokens that exist in the contract
        tCI += getBalanceOfToken(WBNB);
    }

    function _getSimpleTC() internal view returns (uint256 TC) {
        address[] memory path = new address[](2);
        uint256 _totalLP = getAmountLPFromFarm();
        path[1] = WBNB;

        if(_totalLP > 0) {
            (uint256 t0V, uint256 t1V) = _getTokenValues(_totalLP);

            // calculates how many wrapped tokens for tokens
            if(t0V != 0) {
                path[0] = token0;
                TC = _getAmountsOut(t0V, path) + t1V;
            }
        }

        // calculates total Capital from tokens that exist on the contract
        uint256 _balance = getBalanceOfToken(token0);
        if (_balance > 0) {
            path[0] = token0;
            TC += _getAmountsOut(_balance, path);
        }

        // calculates total Capital from WBNB tokens that exist on the contract
        TC += getBalanceOfToken(WBNB);
    }
}
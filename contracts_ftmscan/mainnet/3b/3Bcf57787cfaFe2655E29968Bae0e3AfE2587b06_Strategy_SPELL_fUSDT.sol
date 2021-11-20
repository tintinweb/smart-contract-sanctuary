/**
 *Submitted for verification at FtmScan.com on 2021-11-16
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


interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function withdraw(uint wad) external;
}


interface IRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
    function spirit() external view returns (address);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256) external view returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accSpiritPerShare, uint16 depositFeeBP);
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


contract Strategy_SPELL_fUSDT {
    // This strategy is for FTM network. SPELL - fUSDT pair. RewardToken = "spirit"
    using SafeERC20 for IERC20;
    using Address for address;
    using FixedPoint for *;

    uint256 public constant withdrawFee = 15; // 15%
    uint256 public constant toleranceLevelPercent = 1; // 1%
    uint256 private constant PERIOD = 10 seconds;
    uint256 private constant percentCheckDifference = 5;

    uint256 public pendingFee; // in native tokens
    uint256 public pendingUSDTFee; // in USDT tokens
    uint256 public pendingRewardsFee; // in reward tokens from farm
    address public constant USDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address public constant yelLiquidityRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant YELtoken = 0xD3b71117E6C1558c1553305b44988cd944e97300;
    address public constant WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address public token0; // fUSDT
    address public token1; // SPELL
    address public vault;

    // ------------> Important constants <--------------
    uint256 public constant pid = 52;
    bool public constant hasPid = true;
    address public router = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address public constant lpToken = 0x31c0385DDE956f95D43Dac80Bd74FEE149961f4c;
    address public constant farm = 0x9083EA3756BDE6Ee6f27a6e996806FBD37F6F093;
    // ------------>        END          <--------------

    mapping(address => uint256) public pendingYel;
    uint private price0CumulativeLast;
    uint private price1CumulativeLast;
    uint32 private blockTimestampLast;
    uint256 public price1Average;
    uint256 public price0Average;
    uint256 public price1;
    uint256 public price0;

    event AutoCompound();
    event Earn(uint256 amount);
    event YELswapped(uint256 percent);
    event WithdrawFromStrategy(uint256 amount);
    event TakeFee(uint256 rewardsFeeInWETH, uint256 amountWETH);

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
        _approveToken(WETH, router);
        _approveToken(token0, router);
        _approveToken(token1, router);

        price0CumulativeLast = IPair(lpToken).price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = IPair(lpToken).price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        (,,blockTimestampLast) = IPair(lpToken).getReserves();
    }

    receive() external payable onlyVault {
        deposit();
    }

    // ------------> Important functions for farm <--------------
    function getRewardToken() public view returns (address){
        return IFarm(farm).spirit();
    }

    function _withdrawFromFarm(uint256 _amount) internal {
        IFarm(farm).withdraw(pid, _amount);
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
        _approveToken(WETH, router);
        _approveToken(USDT, router);

        if (amount > 0) {
            // rewards and LP
            _withdrawFromFarm(amount);

            uint256 _balance = getBalanceOfToken(rewardToken);
            if(_balance > 0){
                path[0] = rewardToken;
                path[1] = WETH; // WFTM 
                amount = _getAmountsOut(_balance+pendingRewardsFee, path);
                if(amount > 100) {
                    _swapExactTokensForTokens(router, _balance+pendingRewardsFee, amount, path);
                    pendingRewardsFee = 0;
                } else{
                    pendingRewardsFee += _calculateAmountFee(_balance);
                }
            }  
        }
        // its important to take fee here because all
        // usdt have to be recalculated at first
        _takeFee();
        _addLiquidityFromAllTokens();
        earn();
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
        _transfer(WETH, _receiver, getBalanceOfToken(WETH));
    }

    function requestWithdraw(address _receiver, uint256 _percent) public onlyVault {
        uint256 _totalLP = getAmountLPFromFarm();
        if (_totalLP > 0) {
            uint256 yelAmount = _swapToYELs(_percent);
            if(yelAmount > 0) {
                pendingYel[_receiver] += yelAmount;
            } 
            emit WithdrawFromStrategy(yelAmount);
        }
    }

    function migrate(uint256 _percent) public onlyVault {
        _swapLPtoWETH(_percent * 10 ** 12);
        _transfer(WETH, vault, getBalanceOfToken(WETH));
    }

    function deposit() public payable onlyVault returns (uint256) {
        _approveToken(token0, router);
        _approveToken(token1, router);
        uint256 lpBalanceBefore = getAmountLPFromFarm();
        _addLiquidityFromETH(msg.value);
        uint256 lpBalance = earn();
        return _getSimpleTCI(lpBalance - lpBalanceBefore);
    }

    function depositAsMigrate() public onlyVault {
        require(getBalanceOfToken(WETH) > 0, "Not enough WETH to make migration");
        _approveToken(token0, router);
        _approveToken(token1, router);
        _approveToken(token0, lpToken);
        _approveToken(token1, lpToken);
        _approveToken(lpToken, farm);
        _approveToken(WETH, router);
        _addLiquidityFromAllTokens();
        earn();
    }

    function setRouter(address _address) public onlyVault {
        require(_address != address(0), "The address can not be zero address");
        router = _address;
        _approveToken(WETH, router);
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
        if(_token == WETH) {
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

    function _getAmountsIn(uint256 _amount, address[] memory path) internal view returns (uint256){
        uint256[] memory amounts = IRouter(router).getAmountsIn(_amount, path);
        return amounts[0];
    }

    function _getTokenValues(
        uint256 _amountLP
    ) internal view returns (uint256 token0Value, uint256 token1Value) {
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
        path[0] = WETH;
        path[1] = USDT;
        uint256 rewardsFeeInWETH = _calculateAmountFee(getBalanceOfToken(WETH));
        if(rewardsFeeInWETH > 0) {
            uint256 amount = _getAmountsOut(rewardsFeeInWETH + pendingFee, path);
            if(amount > 100) {
                uint256 _balanceUSDT = getBalanceOfToken(USDT);
                _swapExactTokensForTokens(router, rewardsFeeInWETH + pendingFee, amount, path);
                pendingUSDTFee += getBalanceOfToken(USDT) - _balanceUSDT;
                pendingFee = 0;
                emit TakeFee(rewardsFeeInWETH, amount);
            } else {
                pendingFee += rewardsFeeInWETH;
            }
        }
    }

    function _addLiquidity(uint256 _desired0, uint256 _desired1MIN) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256 desired1;
        uint256 amount = _getAmountsOut(_desired0, path);
        if(amount <= _desired1MIN) {
            desired1 = amount;
        } else {
            desired1 = _desired1MIN;
        }

        if(_canAddLiquidity(_desired0, desired1)) {
            _transfer(token0, lpToken, _desired0);
            _transfer(token1, lpToken, desired1);
            IPair(lpToken).mint(address(this));
        }
    }

    function _addLiquidityFromAllTokens() internal {
        _swapWETHToTokens();

        uint256 _potentialBalance0 = getBalanceOfToken(token0);
        uint256 _potentialBalance1 = getBalanceOfToken(token1);

        if(_potentialBalance0 > 0 && _potentialBalance1 > 0)
            _addLiquidity(_potentialBalance0, _potentialBalance1);
    }

    function _canAddLiquidity(uint256 amount0, uint256 amount1) internal view returns (bool) {
        (uint112 _reserve0, uint112 _reserve1,) = IPair(lpToken).getReserves(); // gas savings
        uint256 _totalSupply = IPair(lpToken).totalSupply();
        uint256 liquidity;
        uint256 minLiquidity = IPair(lpToken).MINIMUM_LIQUIDITY();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - minLiquidity;
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        return liquidity > 0;
    }

    function _swapWETHToTokens() internal {
        // uses only for adding liquidity
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token0;
        uint256 amount;
        uint256 _balance = getBalanceOfToken(WETH);
        if (_balance > 0) {
            amount = _getAmountsOut(_balance, path);
            if(amount > 100) {
                _swapExactTokensForTokens(router, _balance, amount, path);
            }
        }
        
        _balance = getBalanceOfToken(token0) / 2;
        path[1] = token1;
        if (_balance > 0) {
            amount = _getAmountsOut(_balance, path);
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

    function _updateAveragePrices() internal {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(lpToken));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        price0Average = uint256(FixedPoint
            .uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144()) / 1e12;

        price1Average = uint256(FixedPoint
            .uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed))
            .mul(1e36)
            .decode144()) / 1e18;

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function _check0Price(address[] memory path) internal {
        // check that price difference no more than 5 percent
        
        // price per one token
        price0 = _getToken0Price(path);
        // string memory msgError;

        // if(path[1] == token1){
        //      msgError = "Prices have more than 5 percent difference for token1";
        //     if(price1Average >= price) {
        //         require(100 - (price * 100 / price1Average) <= percentCheckDifference, msgError);
        //     } else {
        //         require(100 - (price1Average * 100 / price) <= percentCheckDifference, msgError);
        //     }
        // }
        // if(path[1] == token0){
        //     msgError = "Prices have more than 5 percent difference for token0";
        //     if(price0Average >= price) {
        //         require(100 - (price * 100 / price0Average) <= percentCheckDifference, msgError);
        //     } else {
        //         require(100 - (price0Average * 100 / price) <= percentCheckDifference, msgError);
        //     }
        // }
        
    }

    function _check1Price(address[] memory path) internal {
        // check that price difference no more than 5 percent
        
        // price per one token
        price1 = _getToken1Price(path);
    }

    function _swapExactETHForFUSDT(uint256 _amountETH) internal {
        // to swap FTM to fUSDT it needs to have wFTM token in the path
        // FTM -> wFTM -> fUSDT
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token0;
        _check0Price(path);
        uint256 amount = _getAmountsOut(_amountETH, path);
        if(amount > 100){
            IRouter(router).swapExactETHForTokens{value:_amountETH}(
                amount - (amount*toleranceLevelPercent/100), // amountOutMin
                path,
                address(this),
                block.timestamp + 1 minutes // deadline
            );
        }
    }

    function _swapFUSDTToSPELL() internal {
        // a half of USDT swap to SPELL
        // fUSDT -> SPELL
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = token1;
        _check1Price(path);
        uint256 balanceSpell = getBalanceOfToken(USDT) / 2;
        uint256 amount = _getAmountsOut(balanceSpell, path);
        if(amount > 100){
            _swapExactTokensForTokens(router, balanceSpell, amount, path);
        }
    }

    function _swapSPELLToFUSDT() internal {
        // SPELL -> fUSDT
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = USDT;
        uint256 balanceSpell = getBalanceOfToken(token1);
        uint256 amount = _getAmountsOut(balanceSpell, path);
        if(amount > 100){
            _swapExactTokensForTokens(router, balanceSpell, amount, path);
        }
    }

    function _addLiquidityFromETH(uint256 _amountETH) internal {
        _updateAveragePrices();
        // swap all native tokens to fUSDT
        _swapExactETHForFUSDT(_amountETH);
        // a half of USDT swap to SPELL
        _swapFUSDTToSPELL();
        // add Liquidity for tokens
        _addLiquidity(getBalanceOfToken(token0), getBalanceOfToken(token1));
    }

    function _swapLPtoWETH(uint256 _percent) internal {
        uint256 _totalLP = getAmountLPFromFarm();
        if (_totalLP > 0) {
            _withdrawFromFarm((_percent * _totalLP) / (100 * 10 ** 12));
            address rewardToken = getRewardToken();

            _approveToken(rewardToken, router);
            _approveToken(WETH, router);

            // swap rewards to WETH
            _swapTokenToWETH(rewardToken);

            // swap LPs to token0 and token1
            _removeLiquidity();

            // swap token0 and token1 to WETH
            _swapTokensToWETH();
        }
    }

    function _swapToYELs(uint256 _percent) internal returns (uint256 newYelBalance){ 
        _swapLPtoWETH(_percent);

        // swap to YEL
        uint256 _oldYelBalance = getBalanceOfToken(YELtoken);
        _approveToken(YELtoken, yelLiquidityRouter);
        _approveToken(WETH, yelLiquidityRouter);
        _swapWETHToToken(yelLiquidityRouter, YELtoken);
        // return an amount of YEL that the user can claim
        newYelBalance = getBalanceOfToken(YELtoken) - _oldYelBalance;
        emit YELswapped(newYelBalance);
    }

    function _swapTokenToWETH(address _token) internal {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint256 _balance = getBalanceOfToken(_token);
        if(_balance > 0) {
            uint256[] memory amounts = IRouter(router).getAmountsOut(_balance, path);
            if(amounts[1] > 100) {
                _swapExactTokensForTokens(router, _balance, amounts[1], path);
            }
        }
    }

    function _swapTokensToWETH() internal {
        // swap SPELL to fUSDC
        _swapSPELLToFUSDT();
        // swap all fUSDC to wFTM
        _swapTokenToWETH(token0);
    }

    function _swapWETHToToken(address _router, address _token) internal {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        uint256 _balanceWETH = getBalanceOfToken(WETH);
        uint256[] memory amounts = IRouter(_router).getAmountsOut(_balanceWETH, path);
        if(amounts[1] > 100) {
            _swapExactTokensForTokens(_router, _balanceWETH, amounts[1], path);  
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

    function _getToken0Price(address[] memory path) internal view returns (uint256) {
        return 1e36 / (_getAmountsOut(100 * 1e18, path) / 1e12);
    }

    function _getToken1Price(address[] memory path) internal view returns (uint256) {
        return 1e36 / (_getAmountsOut(100 * 1e18, path) / 100);
    }

    function _getSimpleTCI(uint256 _amount) internal view returns (uint256 tCI) {
        address[] memory path3 = new address[](3);
        address[] memory path2 = new address[](2);
        if(_amount > 0) {
            (uint256 t0V, uint256 t1V) = _getTokenValues(_amount);

            // calculates how many wrapped Tokens for token0 and token0 using price
            // calculate SPELL to wFTM through fUSDC
            if(t1V != 0) {
                path3[2] = token1;
                path3[1] = token0;
                path3[0] = WETH;
                tCI = _getAmountsOut(t1V, path3);
            }
            // calculate fUSDC to wFTM 
            if(t0V != 0) {
                path2[1] = token0;
                path2[0] = WETH;
                tCI += _getAmountsOut(t0V, path2);
            }
        }

        // calculates total Capital from tokens that exist on the contract
        
        // ----> calculates SPELL to wFTM through fUSDC <----
        uint256 _balance = getBalanceOfToken(token1);
        if(_balance != 0) {
            path3[2] = token1;
            path3[1] = token0;
            path3[0] = WETH;
            tCI = _getAmountsOut(_balance, path3);
        }

        // ----> calculates fUSDC to wFTM <-----
        _balance = getBalanceOfToken(token0);
        if(_balance != 0) {
            path2[1] = token0;
            path2[0] = WETH;
            tCI += _getAmountsOut(_balance, path2);
        }

        // calculates total Capital from Wrapped tokens that exist in the contract
        tCI += getBalanceOfToken(WETH);
    }

    function _getSimpleTC() internal view returns (uint256 TC) {
        address[] memory path3 = new address[](3);
        address[] memory path2 = new address[](2);
        uint256 _totalLP = getAmountLPFromFarm();
        if(_totalLP > 0) {
            (uint256 t0V, uint256 t1V) = _getTokenValues(_totalLP);

            // calculates how many wrapped Tokens for token0 and token0
            // calculate SPELL to wFTM through fUSDC
            if(t1V != 0) {
                path3[0] = token1;
                path3[1] = token0;
                path3[2] = WETH;
                TC = _getAmountsOut(t1V, path3);
            }
            // calculate fUSDC to wFTM 
            if(t0V != 0) {
                path2[0] = token0;
                path2[1] = WETH;
                TC += _getAmountsOut(t0V, path2);
            }
        }

        // calculates total Capital from tokens that exist on the contract
        
        // ----> calculates SPELL to wFTM through fUSDC <----
        uint256 _balance = getBalanceOfToken(token1);
        if(_balance != 0) {
            path3[0] = token1;
            path3[1] = token0;
            path3[2] = WETH;
            TC = _getAmountsOut(_balance, path3);
        }

        // ----> calculates fUSDC to wFTM <-----
        _balance = getBalanceOfToken(token0);
        if(_balance != 0) {
            path2[0] = token0;
            path2[1] = WETH;
            TC += _getAmountsOut(_balance, path2);
        }

        // calculates total Capital from WETH tokens that exist on the contract
        TC += getBalanceOfToken(WETH);
    }
}
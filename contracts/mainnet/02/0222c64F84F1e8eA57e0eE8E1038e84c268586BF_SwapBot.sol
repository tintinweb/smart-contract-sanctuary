/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    // function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     unchecked {
    //         uint256 oldAllowance = token.allowance(address(this), spender);
    //         require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    //         uint256 newAllowance = oldAllowance - value;
    //         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    //     }
    // }

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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _dev;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _dev = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function dev() public view returns (address) {
        return _dev;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDev() {
        require(_dev == _msgSender(), "Ownable: caller is not the dev");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferDevship(address newDev) public virtual onlyDev {
        require(newDev != address(0), "Ownable: new dev is the zero address");
        _dev = newDev;
    }
}

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Token interface
interface TokenInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract SwapBot is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenInterface;

    uint256 private _ownerAmount;
    uint256 private _devAmount;
    // States
    uint16 private _devFee;

    TokenInterface private _weth;

    address[] public _routers;
    address[] private _runners;

    struct Root {
        uint8[] routerIds;
        address[] inTokens;
        uint256 startAmount;
    }

    modifier onlyRunner() {
        (bool exist, ) = checkRunner(_msgSender());
        require(exist, "caller is not the runner");
        _;
    }

    event BadRoots(uint256 startAmount);
    event BadRoot(
        address indexed startToken,
        address indexed endToken,
        uint256 startAmount
    );
    event GoldRoot(
        address indexed startToken,
        address indexed endToken,
        uint256 startAmount
    );
    event TestRun(
        uint8 routerId,
        address inToken,
        address outToken,
        uint256 expectedOutAmount,
        uint256 realAmountOut
    );

    constructor() {
        _weth = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        _routers.push(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        _routers.push(address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F));

        _runners.push(_msgSender());

        _ownerAmount = 0;
        _devAmount = 0;
        _devFee = 3000; // dev fee is 10%, must be divided by 10,000 when calculating
    }

    receive() external payable {}

    function routerLength() public view returns (uint8) {
        return uint8(_routers.length);
    }

    function checkRouter(address routerAddress)
        public
        view
        returns (bool exist, uint8 index)
    {
        uint8 length = routerLength();
        exist = false;
        for (uint8 i = 0; i < length; i++) {
            if (_routers[i] == routerAddress) {
                exist = true;
                index = i;
                break;
            }
        }
    }

    function addRouter(address routerAddress) external onlyDev {
        (bool exist, ) = checkRouter(routerAddress);
        require(!exist, "This router address already exists.");
        require(routerAddress != address(0), "Invalid router address.");

        _routers.push(address(routerAddress));
    }

    function setRouter(uint8 index, address routerAddress) external onlyDev {
        uint8 length = routerLength();
        require(index < length, "Invalid index of router");
        require(routerAddress != address(0), "Invalid router address.");

        _routers[index] = routerAddress;
    }

    function removeRouter(address routerAddress) external onlyDev {
        require(routerAddress != address(0), "Invalid router address.");

        uint8 length = routerLength();
        for (uint8 i = 0; i < length; i++) {
            if (_routers[i] == routerAddress) {
                _routers[i] = address(0);
                break;
            }
        }
    }

    function runnerLength() public view returns (uint8) {
        return uint8(_runners.length);
    }

    function checkRunner(address runner)
        public
        view
        returns (bool exist, uint8 index)
    {
        uint8 length = runnerLength();
        exist = false;
        for (uint8 i = 0; i < length; i++) {
            if (_runners[i] == runner) {
                exist = true;
                index = i;
                break;
            }
        }
    }

    function addRunner(address runner) external onlyDev {
        (bool exist, ) = checkRunner(runner);
        require(!exist, "This runner address already exists.");
        require(runner != address(0), "Invalid runner address.");

        _runners.push(address(runner));
    }

    function setRunner(uint8 index, address runner) external onlyDev {
        uint8 length = runnerLength();
        require(index < length, "Invalid index of runner");
        require(runner != address(0), "Invalid runner address.");

        _runners[index] = runner;
    }

    function removeRunner(address runner) external onlyDev {
        require(runner != address(0), "Invalid runner address.");

        uint8 length = runnerLength();
        for (uint8 i = 0; i < length; i++) {
            if (_runners[i] == runner) {
                _runners[i] = address(0);
                break;
            }
        }
    }

    function getDevFee() public view returns (uint16) {
        return _devFee;
    }

    function setDevFee(uint16 fee) external onlyOwner {
        _devFee = fee;
    }

    function ownerProfit() public view returns (uint256) {
        return _ownerAmount;
    }

    function withdrawProfitOwner(address owner)
        external
        onlyOwner
        returns (bool sent)
    {
        require(_ownerAmount > 0, "Withdraw amount should be more than zero.");

        if (owner != address(0)) {
            (sent, ) = owner.call{value: _ownerAmount}("");
            require(sent, "Failed to send Ether");
            _ownerAmount = 0;
        }
    }

    function devProfit() public view returns (uint256) {
        return _devAmount;
    }

    function withdrawProfitDev(address dev)
        external
        onlyDev
        returns (bool sent)
    {
        require(_devAmount > 0, "Withdraw amount should be more than zero.");
        if (dev != address(0)) {
            (sent, ) = dev.call{value: _devAmount}("");
            require(sent, "Failed to send Ether");
            _devAmount = 0;
        }
    }

    function emergencyWithdraw() external onlyDev {
        require(_msgSender() != address(0), "Invalid dev");
        msg.sender.transfer(address(this).balance);
    }

    function removeOddTokens(address[] memory tokens, address to)
        external
        onlyOwner
        returns (bool)
    {
        require(to != address(0), "Invalid address to send odd tokens");
        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 balance =
                TokenInterface(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (tokens[i] == address(_weth)) {
                    _weth.withdraw(balance);
                    (bool sent, ) = to.call{value: balance}("");
                    require(sent, "Failed to send ether");
                } else {
                    TokenInterface(tokens[i]).transfer(to, balance);
                }
            }
        }

        return true;
    }

    function checkEstimatedProfit(
        uint8[] memory routerIds,
        uint256 startAmount,
        address[] memory inTokens
    ) public view returns (uint256 profit, uint256 endAmount) {
        require(routerIds.length > 1, "Est: Invalid router id array.");
        require(inTokens.length > 1, "Est: Invalid token array.");
        require(
            routerIds.length + 1 == inTokens.length,
            "Est: Rotuers and tokens must have same length."
        );

        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Router02 router =
                IUniswapV2Router02(_routers[routerIds[i]]);
            IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

            address inToken = inTokens[i];
            address outToken = inTokens[i + 1];

            IUniswapV2Pair pair =
                IUniswapV2Pair(factory.getPair(inToken, outToken));

            amountIn = getAmountOutFor(pair, amountIn, inToken);
        }

        profit = amountIn <= startAmount ? 0 : amountIn.sub(startAmount);
        endAmount = amountIn;
    }

    function testCheckEstimatedOutPut(
        uint8 routerId,
        uint256 amountIn,
        address inToken,
        address outToken
    ) public view returns (uint256 outAmount) {
        IUniswapV2Router02 router = IUniswapV2Router02(_routers[routerId]);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(inToken, outToken));

        outAmount = getAmountOutFor(pair, amountIn, inToken);
    }

    function getAmountOutFor(
        IUniswapV2Pair pair,
        uint256 amountIn,
        address inToken
    ) internal view returns (uint256 outAmount) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (pair.token0() == inToken) {
            outAmount = UniswapV2Library.getAmountOut(
                amountIn,
                reserve0,
                reserve1
            );
        } else {
            outAmount = UniswapV2Library.getAmountOut(
                amountIn,
                reserve1,
                reserve0
            );
        }
    }

    function run(
        uint8[] memory routerIds,
        address[] memory inTokens,
        uint256 startAmount
    ) public onlyRunner returns (uint256) {
        TokenInterface startToken = TokenInterface(inTokens[0]);
        uint256 balanceForStartToken;
        uint256 newBalanceForStartToken;

        if (address(startToken) != address(_weth)) {
            balanceForStartToken = startToken.balanceOf(address(this));
        } else {
            balanceForStartToken = address(this).balance;
        }

        require(
            balanceForStartToken > 0 && balanceForStartToken >= startAmount,
            "run: Invalid swap amount"
        );

        uint256 len = inTokens.length;
        uint256 amountIn = startAmount;

        for (uint256 i = 0; i < len - 1; i++) {
            IUniswapV2Router02 iRouter =
                IUniswapV2Router02(_routers[routerIds[i]]);
            address inToken = inTokens[i];
            address outToken = inTokens[i + 1];

            if (inToken == address(_weth)) {
                amountIn = _swapEthToToken(iRouter, amountIn, outToken);
            } else if (outToken == address(_weth)) {
                amountIn = _swapTokenToEth(iRouter, amountIn, inToken);
            } else {
                amountIn = _swapTokenToToken(
                    iRouter,
                    amountIn,
                    inToken,
                    outToken
                );
            }
        }

        if (address(startToken) != address(_weth)) {
            newBalanceForStartToken = startToken.balanceOf(address(this));
        } else {
            newBalanceForStartToken = address(this).balance;
        }

        uint256 profit = newBalanceForStartToken.sub(balanceForStartToken);

        return profit;
    }

    function bulkRun(Root[] memory roots)
        external
        onlyRunner
        returns (bool)
    {
        uint256 length = roots.length;
        require(length > 0, "Invalid root data");

        uint256 maxProfit = 0;
        uint256 goalRoot = 0;
        for (uint256 i = 0; i < length; i++) {
            Root memory root = roots[i];

            (uint256 profit, ) =
                checkEstimatedProfit(
                    root.routerIds,
                    root.startAmount,
                    root.inTokens
                );

            uint256 len = root.inTokens.length;

            if (profit > 0) {
                emit GoldRoot(
                    root.inTokens[0],
                    root.inTokens[len - 1],
                    root.startAmount
                );
            } else {
                emit BadRoot(
                    root.inTokens[0],
                    root.inTokens[len - 1],
                    root.startAmount
                );
            }

            if (profit > maxProfit) {
                maxProfit = profit;
                goalRoot = i;
            }
        }

        if (maxProfit > 0) {
            Root memory root = roots[goalRoot];
            uint256 len = root.inTokens.length;
            run(root.routerIds, root.inTokens, root.startAmount);
            emit GoldRoot(
                root.inTokens[0],
                root.inTokens[len - 1],
                root.startAmount
            );
        } else {
            emit BadRoots(roots[0].startAmount);
        }

        return true;
    }

    function swapEthToToken(
        uint8 routerId,
        uint256 ethAmount,
        address token
    ) external onlyRunner {
        IUniswapV2Router02 iRouter = IUniswapV2Router02(_routers[routerId]);

        _swapEthToToken(iRouter, ethAmount, token);
    }

    function swapTokenToETH(
        uint8 routerId,
        uint256 tokenAmount,
        address tokenAddress
    ) external onlyRunner {
        IUniswapV2Router02 iRouter = IUniswapV2Router02(_routers[routerId]);

        _swapTokenToEth(iRouter, tokenAmount, tokenAddress);
    }

    function swapTokenToToken(
        uint8 routerId,
        uint256 tokenInAmount,
        address tokenIn,
        address tokenOut
    ) external onlyRunner {
        IUniswapV2Router02 iRouter = IUniswapV2Router02(_routers[routerId]);

        _swapTokenToToken(iRouter, tokenInAmount, tokenIn, tokenOut);
    }

    function _swapEthToToken(
        IUniswapV2Router02 router,
        uint256 ethAmount,
        address token
    ) private returns (uint256 amountOut) {
        uint256 oldBalance = TokenInterface(token).balanceOf(address(this));

        _swapETHForTokenOut(router, ethAmount, token);

        amountOut = TokenInterface(token).balanceOf(address(this)).sub(
            oldBalance
        );
    }

    function _swapTokenToEth(
        IUniswapV2Router02 router,
        uint256 tokenAmount,
        address token
    ) private returns (uint256 amountOut) {
        uint256 oldEthAmount = address(this).balance;

        uint256 oldWEthAmount = _weth.balanceOf(address(this));
        _swapTokenToETHOut(router, tokenAmount, token);
        uint256 newWEthAmount = _weth.balanceOf(address(this));
        _weth.withdraw(newWEthAmount.sub(oldWEthAmount));

        uint256 newEthAmount = address(this).balance;
        amountOut = newEthAmount.sub(oldEthAmount);
    }

    function _swapTokenToToken(
        IUniswapV2Router02 router,
        uint256 tokenInAmount,
        address tokenIn,
        address tokenOut
    ) private returns (uint256 amountOut) {
        uint256 oldTokenOutAmount =
            TokenInterface(tokenOut).balanceOf(address(this));

        _swapTokenForTokenOut(router, tokenInAmount, tokenIn, tokenOut);

        uint256 newTokenOutAmount =
            TokenInterface(tokenOut).balanceOf(address(this));
        amountOut = newTokenOutAmount.sub(oldTokenOutAmount);
    }

    function _swapSupportingFeeOnTransferTokens(
        IUniswapV2Pair pair,
        address input,
        address output,
        address _to
    ) internal virtual {
        (address token0, ) = UniswapV2Library.sortTokens(input, output);

        uint256 amountInput;
        uint256 amountOutput;
        {
            // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) =
                input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = TokenInterface(input).balanceOf(address(pair)).sub(
                reserveInput
            );
            amountOutput = UniswapV2Library.getAmountOut(
                amountInput,
                reserveInput,
                reserveOutput
            );
        }
        (uint256 amount0Out, uint256 amount1Out) =
            input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
        pair.swap(amount0Out, amount1Out, _to, new bytes(0));
    }

    function _swapETHForTokenOut(
        IUniswapV2Router02 router,
        uint256 ethAmount,
        address token
    ) internal {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(router.WETH(), token));

        _weth.deposit{value: ethAmount}();

        _weth.safeTransfer(address(pair), ethAmount);
        _swapSupportingFeeOnTransferTokens(
            pair,
            router.WETH(),
            token,
            address(this)
        );
    }

    function _swapTokenToETHOut(
        IUniswapV2Router02 router,
        uint256 tokenAmount,
        address token
    ) internal {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(token, router.WETH()));

        TokenInterface(token).safeTransfer(address(pair), tokenAmount);

        _swapSupportingFeeOnTransferTokens(
            pair,
            token,
            router.WETH(),
            address(this)
        );
    }

    function _swapTokenForTokenOut(
        IUniswapV2Router02 router,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(tokenIn, tokenOut));

        TokenInterface(tokenIn).safeTransfer(address(pair), amountIn);
        _swapSupportingFeeOnTransferTokens(
            pair,
            tokenIn,
            tokenOut,
            address(this)
        );
    }

    function sendProfit(uint256 amount) external onlyDev {
        _sendProfit(_weth, amount);
    }

    function _sendProfit(TokenInterface token, uint256 amount)
        private
        returns (bool sent)
    {
        uint256 devAmount = amount.mul(_devFee).div(10000);

        if (address(token) == address(_weth)) {
            (sent, ) = dev().call{value: devAmount}("");
            require(sent, "Failed to send Ether");
            (sent, ) = owner().call{value: amount.sub(devAmount)}("");
            require(sent, "Failed to send Ether");
        } else {
            token.transfer(dev(), devAmount);
            token.transfer(owner(), amount.sub(devAmount));
        }
    }
}
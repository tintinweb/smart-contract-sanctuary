// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IController.sol";
import "./IPancakeCallee.sol";
import "./IUniswapV2Callee.sol";
import "./DexSwapper.sol";
import "./DexSwapperWithCallback.sol";
import "./IUniswapV2Pair.sol";

// TODO 考虑开仓平仓从 swapper 发起
// TODO 短期先approve swapper使用controller的资产
contract DexSwapperUniswapV2 is DexSwapper, DexSwapperWithCallback, IUniswapV2Callee, IPancakeCallee{
    using SafeERC20 for IERC20;

    address public immutable factory;
    bytes32 public immutable codeHash;

    constructor(
        address controller_,
        address factory_,
        bytes32 codeHash_
    ) DexSwapper(controller_) {
        factory = factory_;
        codeHash = codeHash_;
    }

    struct CallbackData {
        address[] path;
        uint256[] amounts;
    }

    // returns the position id
    // TODO 考虑发起位置改为swapper，考虑信用贷的形式（即钱不可以出系统）是否可以由swapper发起
    // TODO 校验collateral underlying必须是position pair中的一个
    // TODO 校验path和position underlying address是不是一致
    function openPosition(OpenPositionParams calldata params) external override returns (uint256 positionId){
        // TODO add check swapper function 在最开始, 避免攻击者传入自己的swapper

        // user stake ibtoken and controller borrow and send to swapper
        (uint256 amountBorrow, uint256 debtShare) = controller.openPositionBorrow(
            msg.sender,
            params.collateralIBToken,
            params.collateralIBTokenAmount,
            params.leverage,
            params.debtUnderlying
        );

        uint256[] memory amounts = _getAmountsOut(amountBorrow, params.path);
        uint256 finalAmountOut = amounts[amounts.length - 1];
        require(finalAmountOut >= params.amountOutMin, 'not-enough-out');

        // TODO check swapUnderlying balance of Controller before and after swap, revert if not >= expected amounts out
        _ammSwapAndSend(params.path, amounts, address(controller));

//        positionId = controller.openPositionMint(
//            params.positionUnderlying,
//            finalAmountOut,
//            msg.sender,
//            params.collateralIBToken,
//            params.collateralIBTokenAmount,
//            params.debtUnderlying,
//            debtShare,
//            params.leverage
//        );
    }

    // 平仓：选择平成哪一种资产，如果是position资产，则swap出debt的数量，还债，剩余的给用户，如果是debt资产，则全部换出，还债，剩余的给用户
    // 并给出一个选项 是否需要同时赎回
    // 目前简化版先只还债
    // TODO 添加close position想要看到的相关信息event
    // TODO 考虑多种平仓可能，比如保留ibtoken
    // TODO 考虑部分平仓（后期）
    // TODO positionMarkToDebtAmount 的作用想一下，要不要做校验，没用就不要了
    function closePosition(ClosePositionParams calldata params) external override {
        (
            address debtUnderlying,
            uint256 currentDebtUnderlyingAmount,
            uint256 positionMarkToDebtAmount,
            address positionIBToken,
            uint256 positionIBTokenAmount
        ) = controller.getClosePositionInfo(params.positionId);

        uint256[] memory amounts = _getAmountsIn(currentDebtUnderlyingAmount, params.path);
        uint256 finalAmountsOut = amounts[amounts.length - 1];
        require(finalAmountsOut <= params.amountInMax, 'too-much-in');

        // 有amount之后withdraw部分的position拿到 underlying 资产
        uint256 burnedAmount = controller.closePositionWithdraw(debtUnderlying, currentDebtUnderlyingAmount, positionIBToken, positionIBTokenAmount);

        // swap and transfer to controller to repay debt
        _ammSwapAndSend(params.path, amounts, address(controller));
        // TODO 完善平仓的检查，包括可能的平仓手续费收取，以及margin rate的检查

        controller.closePositionRepayAndBurn(debtUnderlying, currentDebtUnderlyingAmount, params.positionId, positionIBToken, positionIBTokenAmount - burnedAmount, msg.sender);
    }

    function _ammSwapAndSend(address[] memory path, uint256[] memory amounts, address to) internal {
        // swap and send to controller for lending
        IUniswapV2Pair(_pairFor(path[0], path[1])).swap(
            path[0] < path[1] ? 0 : amounts[1],
            path[0] < path[1] ? amounts[1] : 0,
            to,
            abi.encode(
                CallbackData({path: path, amounts: amounts})
            )
        );
    }

    /// @dev Continues the action (uniswap / sushiswap)
    function uniswapV2Call(
        address sender,
        uint,
        uint,
        bytes calldata data
    ) external override isCallback {
        require(sender == address(this), 'uniswapV2Call/bad-sender');
        _pairCallback(data);
    }

    /// @dev Continues the action (pancakeswap)
    function pancakeCall(
        address sender,
        uint,
        uint,
        bytes calldata data
    ) external override isCallback {
        require(sender == address(this), 'pancakeCall/bad-sender');
        _pairCallback(data);
    }

    /// @dev Continues the action (uniswap / sushiswap / pancakeswap)
    function _pairCallback(bytes calldata data) internal {
        CallbackData memory cb = abi.decode(data, (CallbackData));
        require(msg.sender == _pairFor(cb.path[0], cb.path[1]), '_pairCallback/bad-caller');
        uint len = cb.path.length;
        if (len > 2) {
            address pair = _pairFor(cb.path[1], cb.path[2]);
            IERC20(cb.path[1]).safeTransfer(pair, cb.amounts[1]);
            for (uint idx = 1; idx < len - 1; idx++) {
                (address input, address output) = (cb.path[idx], cb.path[idx + 1]);
                address to = idx < len - 2 ? _pairFor(output, cb.path[idx + 2]) : address(this);
                uint amount0Out = input < output ? 0 : cb.amounts[idx + 1];
                uint amount1Out = input < output ? cb.amounts[idx + 1] : 0;
                IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
                pair = to;
            }
        }

        // after flashloan, return input
        IERC20(cb.path[0]).safeTransfer(msg.sender, cb.amounts[0]);
    }

    /// Internal UniswapV2 library functions
    /// See https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    function _sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        return address(uint160(uint(keccak256(abi.encodePacked(hex'ff', factory, salt, codeHash)))));
    }

    function _getReserves(address tokenA, address tokenB)
    internal
    view
    returns (uint reserveA, uint reserveB)
    {
        (address token0, ) = _sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(_pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function _getAmountsOut(uint amountIn, address[] memory path)
    internal
    view
    returns (uint[] memory amounts)
    {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = _getReserves(path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function _getAmountsIn(uint amountOut, address[] memory path)
    internal
    view
    returns (uint[] memory amounts)
    {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = _getReserves(path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

import "./INonFungiblePosition.sol";

interface IController {
    function openPositionBorrow(
        address trader,
        address collateralIBToken,
        uint256 collateralIBTokenAmount,
        uint256 leverage,
        address debtUnderlying
    ) external returns (uint256 amountBorrow, uint256 debtShare);

    function openPositionMint(
        address positionUnderlying,
        uint256 amount,
        address recipient,
        address collateralIBToken,
        uint256 collateralIBTokenAmount,
        address debtUnderlying,
        uint256 debtShare,
        uint256 leverage) external returns (uint256 positionId);

    //    function close(uint256 positionId) external;

    function getClosePositionInfo(uint256 positionId) external
    returns (
        address debtUnderlying,
        uint256 currentDebtUnderlyingAmount,
        uint256 positionMarkToDebtAmount,
        address positionIBToken,
        uint256 positionIBTokenAmount);

    function closePositionWithdraw(
        address debtUnderlying,
        uint256 currentDebtUnderlyingAmount,
        address positionIBToken,
        uint256 positionIBTokenAmount) external returns (uint256);

    function closePositionRepayAndBurn(
        address debtUnderlying,
        uint256 repayAmount,
        uint256 closePositionId,
        address positionIBToken,
        uint256 positionLeftAmount,
        address recipient) external;

    function ibTokens(address underlying) external view returns (address);

    /// @dev Returns the address of the underlying of the given ibToken, or 0 if not exists.
    function underlyings(address ibToken) external view returns (address);

    /// @dev Returns the address of the config contract.
    function config() external view returns (address);

    /// @dev Returns the interest rate model smart contract.
    function interestModel() external view returns (address);

    /// @dev Returns the address of the oracle contract.
    function oracle() external view returns (address);

    /// @dev Returns the address of the position NFT contract.
    function positionToken() external view returns (INonFungiblePosition);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IPancakeCallee {
  function pancakeCall(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

import "./IController.sol";

abstract contract DexSwapper {

    struct OpenPositionParams {
        address[] path;
        uint256 amountOutMin;
        address collateralIBToken;
        uint256 collateralIBTokenAmount;
        address debtUnderlying;
        uint256 leverage;
        address positionUnderlying;
    }

    struct ClosePositionParams {
        address[] path;
        uint256 amountInMax;
        uint256 positionId;
    }

    IController public controller;

    constructor(address controller_){
        controller = IController(controller_);
    }

    function openPosition(OpenPositionParams calldata params) external virtual returns (uint256 positionId);

    function closePosition(ClosePositionParams calldata params) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

contract DexSwapperWithCallback {
  address private constant NO_CALLER = address(42); // nonzero so we don't repeatedly clear storage
  address private caller = NO_CALLER;

  modifier withCallback() {
    require(caller == NO_CALLER);
    caller = msg.sender;
    _;
    caller = NO_CALLER;
  }

  // TODO, 现在swapper是由controller 发起故此处不通过，后续考虑是否需要
  modifier isCallback() {
//    require(caller == tx.origin, "not from tx origin");
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IUniswapV2Pair {
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

interface INonFungiblePosition {
    struct Position {
        address collateralIBToken;
        //        uint256 collateralIBTokenAmount;
        address debtUnderlying;
        uint256 debtShare;
        uint256 leverage;
        address positionIBToken;
        uint256 totalPositionIBTokenAmount;
    }

    struct MintParams {
        address recipient;
        address collateralIBToken;
        //        uint256 collateralIBTokenAmount;
        address debtUnderlying;
        uint256 debtShare;
        uint256 leverage;
        address positionIBToken;
        uint256 totalPositionIBTokenAmount;
    }

    function getPosition(uint256 tokenId) external view
    returns (
        address collateralIBToken,
        address debtUnderlying,
        uint256 debtShare,
        uint256 leverage,
        address positionIBToken,
        uint256 totalPositionIBTokenAmount);

    function mint(MintParams calldata params) external payable returns (uint256 tokenId);

    function burn(uint256 tokenId) external payable;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}
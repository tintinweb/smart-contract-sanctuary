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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {GelatoString} from "../../lib/GelatoString.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/uniswap/IUniswapV2Router02.sol";
import {ETH} from "../../constants/Tokens.sol";

function _swapExactXForX(
    address WETH, // solhint-disable-line var-name-mixedcase
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path,
    address _to,
    uint256 _deadline
) returns (uint256) {
    if (_path[0] == ETH) {
        _path[0] = WETH;
        return
            _swapExactETHForTokens(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    SafeERC20.safeIncreaseAllowance(
        IERC20(_path[0]),
        address(_uniRouter),
        _amountIn
    );

    if (_path[_path.length - 1] == ETH) {
        _path[_path.length - 1] = WETH;
        return
            _swapExactTokensForETH(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    return
        _swapExactTokensForTokens(
            _uniRouter,
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        );
}

function _swapExactETHForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactETHForTokens{value: _amountIn}(
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactETHForTokens:");
    } catch {
        revert("_swapExactETHForTokens:undefined");
    }
}

function _swapExactTokensForETH(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForETH:");
    } catch {
        revert("_swapExactTokensForETH:undefined");
    }
}

function _swapExactTokensForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForTokens:");
    } catch {
        revert("_swapExactTokensForTokens:undefined");
    }
}

function _swapTokensForExactETH(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountOut,
    uint256 _amountInMax,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountIn) {
    SafeERC20.safeIncreaseAllowance(
        IERC20(_path[0]),
        address(_uniRouter),
        _amountInMax
    );

    try
        _uniRouter.swapTokensForExactETH(
            _amountOut,
            _amountInMax,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        return amounts[0];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapTokensForExactETH:");
    } catch {
        revert("_swapTokensForExactETH:undefined");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import {
    IUniswapV2Router02,
    UniswapV2Router02Handler
} from "../uniswap/UniswapV2Router02Handler.sol";

contract PancakeSwapHandler is UniswapV2Router02Handler {
    constructor(IUniswapV2Router02 _pancakeswapRouter, address _weth)
        UniswapV2Router02Handler(_pancakeswapRouter, _weth)
    {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import {IHandler} from "../../interfaces/IHandler.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/uniswap/IUniswapV2Router02.sol";
import {TokenUtils} from "../../lib/TokenUtils.sol";
import {ETH} from "../../constants/Tokens.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {
    _swapExactXForX,
    _swapTokensForExactETH
} from "../../functions/uniswap/FUniswapV2.sol";

/// @notice UniswapV2 Handler used to execute an order via UniswapV2Router02
/// @dev This does NOT implement the standard IHANDLER
contract UniswapV2Router02Handler is IHandler {
    using TokenUtils for address;

    // solhint-disable var-name-mixedcase
    IUniswapV2Router02 public UNI_ROUTER;
    address public immutable WETH;

    // solhint-enable var-name-mixedcase

    constructor(IUniswapV2Router02 _uniRouter, address _weth) {
        UNI_ROUTER = _uniRouter;
        WETH = _weth;
    }

    /// @notice receive ETH from UniV2Router02 during swapXForEth
    receive() external payable override {
        require(
            msg.sender != tx.origin,
            "UniswapV2Router02Handler#receive: NO_SEND_ETH_PLEASE"
        );
    }

    /**
     * @notice Handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountOutMin - Address of the output token
     * @param _data - (module, relayer, fee, intermediatePath, intermediateFeePath)
     * @return bought - Amount of output token bought
     */
    // solhint-disable-next-line function-max-lines
    function handle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external payable override returns (uint256 bought) {
        (
            address inToken,
            address outToken,
            uint256 amountIn,
            address[] memory path,
            address relayer,
            uint256 fee,
            address[] memory feePath
        ) = _handleInputData(_inToken, _outToken, _data);

        // Swap and charge fee in ETH
        if (inToken == WETH || inToken == ETH) {
            if (inToken == WETH) IWETH(WETH).withdraw(fee);
            bought = _swap(amountIn - fee, _amountOutMin, path, msg.sender);
        } else if (outToken == WETH || outToken == ETH) {
            bought = _swap(amountIn, _amountOutMin + fee, path, address(this));
            if (outToken == WETH) IWETH(WETH).withdraw(fee);
            outToken.transfer(msg.sender, bought - fee);
        } else {
            uint256 feeAmountIn = _swapTokensForExactETH(
                UNI_ROUTER,
                fee, // amountOut (in ETH)
                amountIn, // amountInMax (in inputToken)
                feePath,
                address(this),
                block.timestamp + 1 // solhint-disable-line not-rely-on-time
            );
            _swap(amountIn - feeAmountIn, _amountOutMin, path, msg.sender);
        }

        // Send fee to relayer
        (bool successRelayer, ) = relayer.call{value: fee}("");
        require(
            successRelayer,
            "UniswapV2Router02Handler#handle: TRANSFER_ETH_TO_RELAYER_FAILED"
        );
    }

    /**
     * @notice Check whether can handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - (module, relayer, fee, intermediatePath)
     * @return bool - Whether the execution can be handled or not
     */
    // solhint-disable-next-line code-complexity
    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _minReturn,
        bytes calldata _data
    ) external view override returns (bool) {
        (
            address inToken,
            address outToken,
            ,
            address[] memory path,
            ,
            uint256 fee,
            address[] memory feePath
        ) = _handleInputData(_inToken, _outToken, _data);

        if (inToken == WETH || inToken == ETH) {
            if (_amountIn <= fee) return false;
            return _getAmountOut(_amountIn - fee, path) >= _minReturn;
        } else if (outToken == WETH || outToken == ETH) {
            uint256 bought = _getAmountOut(_amountIn, path);
            if (bought <= fee) return false;
            return bought - fee >= _minReturn;
        } else {
            uint256 inTokenFee = _getAmountIn(fee, feePath);
            if (inTokenFee >= _amountIn) return false;
            return _getAmountOut(_amountIn - inTokenFee, path) >= _minReturn;
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recipient
    ) private returns (uint256 bought) {
        bought = _swapExactXForX(
            WETH,
            UNI_ROUTER,
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        );
    }

    function _getAmountOut(uint256 _amountIn, address[] memory _path)
        private
        view
        returns (uint256 amountOut)
    {
        uint256[] memory amountsOut = UNI_ROUTER.getAmountsOut(
            _amountIn,
            _path
        );
        amountOut = amountsOut[amountsOut.length - 1];
    }

    function _getAmountIn(uint256 _amountOut, address[] memory _path)
        private
        view
        returns (uint256 amountIn)
    {
        uint256[] memory amountsIn = UNI_ROUTER.getAmountsIn(_amountOut, _path);
        amountIn = amountsIn[0];
    }

    function _handleInputData(
        IERC20 _inToken,
        IERC20 _outToken,
        bytes calldata _data
    )
        private
        view
        returns (
            address inToken,
            address outToken,
            uint256 amountIn,
            address[] memory path,
            address relayer,
            uint256 fee,
            address[] memory feePath
        )
    {
        inToken = address(_inToken);
        outToken = address(_outToken);

        // Load real initial balance, don't trust provided value
        amountIn = inToken.balanceOf(address(this));

        // Decode extra data;
        (, relayer, fee, path, feePath) = abi.decode(
            _data,
            (address, address, uint256, address[], address[])
        );
    }
}

// "SPDX-License-Identifier: GPL-3.0"
pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _amountOutMin - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external payable returns (uint256 bought);

    /**
     * @notice Check whether can handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _amountOutMin - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// "SPDX-License-Identifier: GPL-3.0"
pragma solidity 0.8.7;

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);
}

// "SPDX-License-Identifier: GPL-3.0"
pragma solidity 0.8.7;

library GelatoString {
    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(string memory _second, string memory _first)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(string memory _first, string memory _second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import {
    Address,
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ETH} from "../constants/Tokens.sol";

library TokenUtils {
    using Address for address payable;
    using SafeERC20 for IERC20;

    function transfer(
        address _token,
        address _to,
        uint256 _amt
    ) internal {
        if (_token == ETH) payable(_to).sendValue(_amt);
        else IERC20(_token).safeTransfer(_to, _amt);
    }

    function balanceOf(address _token, address _account)
        internal
        view
        returns (uint256)
    {
        return
            ETH == _token
                ? _account.balance
                : IERC20(_token).balanceOf(_account);
    }
}
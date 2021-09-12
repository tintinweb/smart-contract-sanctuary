// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../tokens/interfaces/IWETH.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";
import "../tokens/interfaces/IDeltaYieldTracker.sol";

contract Router is IRouter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public gov;

    address public weth;
    address public override nusd;
    address public override vault;
    address public deltaYieldTracker;

    mapping(address => bool) public plugins;
    mapping(address => mapping(address => bool)) public approvedPlugins;

    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Router: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _nusd,
        address _weth
    ) {
        vault = _vault;
        nusd = _nusd;
        weth = _weth;

        gov = msg.sender;
    }

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setDeltaYieldTracker(address _deltaYieldTracker) external onlyGov {
        deltaYieldTracker = _deltaYieldTracker;
    }

    function addPlugin(address _plugin) external override onlyGov {
        plugins[_plugin] = true;
    }

    function removePlugin(address _plugin) external onlyGov {
        plugins[_plugin] = false;
    }

    function approvePlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = true;
    }

    function denyPlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = false;
    }

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external {
        _validatePlugin(_account);
        IERC20(_token).safeTransferFrom(_account, _receiver, _amount);
    }

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external {
        _validatePlugin(_account);
        IVault(vault).increasePosition(
            _account,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong
        );
    }

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256) {
        _validatePlugin(_account);
        return
            IVault(vault).decreasePosition(
                _account,
                _collateralToken,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                _receiver
            );
    }

    function directPoolDeposit(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(_sender(), vault, _amount);
        IVault(vault).directPoolDeposit(_token);
    }

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) public override {
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, _receiver, _amountIn);
        emit Swap(
            msg.sender,
            _path[0],
            _path[_path.length - 1],
            _amountIn,
            amountOut
        );
    }

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        _transferETHToVault();
        uint256 amountOut = _swap(_path, _minOut, _receiver, msg.value);
        emit Swap(
            msg.sender,
            _path[0],
            _path[_path.length - 1],
            msg.value,
            amountOut
        );
    }

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external {
        require(_path[_path.length - 1] == weth, "Router: invalid _path");
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, address(this), _amountIn);
        _transferOutETH(amountOut, _receiver);
        emit Swap(
            msg.sender,
            _path[0],
            _path[_path.length - 1],
            _amountIn,
            amountOut
        );
    }

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external {
        if (_amountIn > 0) {
            IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        }
        if (_path.length > 1 && _amountIn > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this), _amountIn);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(
            _path[_path.length - 1],
            _indexToken,
            _sizeDelta,
            _isLong,
            _price
        );
    }

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        if (msg.value > 0) {
            _transferETHToVault();
        }
        if (_path.length > 1 && msg.value > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this), msg.value);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(
            _path[_path.length - 1],
            _indexToken,
            _sizeDelta,
            _isLong,
            _price
        );
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external {
        _decreasePosition(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _price
        );
    }

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external {
        uint256 amountOut = _decreasePosition(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            address(this),
            _price
        );
        _transferOutETH(amountOut, _receiver);
    }

    function _increasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) private {
        if (_isLong) {
            require(
                IVault(vault).getMaxPrice(_indexToken) <= _price,
                "Router: mark price higher than limit"
            );
        } else {
            require(
                IVault(vault).getMinPrice(_indexToken) >= _price,
                "Router: mark price lower than limit"
            );
        }

        IVault(vault).increasePosition(
            _sender(),
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong
        );

        if (deltaYieldTracker != address(0)) {
            // Denominate in tokenDecimals amount rather than USD
            uint256 _normalisedSizeDelta = _sizeDelta
                .mul(10**(IVault(vault).tokenDecimals(_collateralToken)))
                .div(
                    _isLong
                        ? IVault(vault).getMaxPrice(_collateralToken)
                        : IVault(vault).getMinPrice(_collateralToken)
                );

            // Track long supplied margin collateral to distribute claimable yield token for
            IDeltaYieldTracker(deltaYieldTracker).updateDeltaRewards(
                _sender(),
                _collateralToken,
                _normalisedSizeDelta,
                _isLong,
                true
            );
        }
    }

    function _decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) private returns (uint256) {
        if (_isLong) {
            require(
                IVault(vault).getMinPrice(_indexToken) >= _price,
                "Router: mark price lower than limit"
            );
        } else {
            require(
                IVault(vault).getMaxPrice(_indexToken) <= _price,
                "Router: mark price higher than limit"
            );
        }

        uint256 amountOut = IVault(vault).decreasePosition(
            _sender(),
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver
        );

        if (deltaYieldTracker != address(0)) {
            // Denominate in tokenDecimals amount rather than USD
            uint256 _normalisedSizeDelta = _sizeDelta
                .mul(10**(IVault(vault).tokenDecimals(_collateralToken)))
                .div(
                    _isLong
                        ? IVault(vault).getMaxPrice(_collateralToken)
                        : IVault(vault).getMinPrice(_collateralToken)
                );

            // Track removed margin collateral to distribute claimable yield token for
            IDeltaYieldTracker(deltaYieldTracker).updateDeltaRewards(
                _sender(),
                _collateralToken,
                _normalisedSizeDelta,
                _isLong,
                false
            );
        }

        return amountOut;
    }

    function _transferETHToVault() private {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).safeTransfer(vault, msg.value);
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver)
        private
    {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _swap(
        address[] memory _path,
        uint256 _minOut,
        address _receiver,
        uint256 _amountIn
    ) private returns (uint256) {
        if (_path.length == 2) {
            return
                _vaultSwap(_path[0], _path[1], _minOut, _receiver, _amountIn);
        }
        if (_path.length == 3) {
            uint256 midOut = _vaultSwap(
                _path[0],
                _path[1],
                0,
                address(this),
                _amountIn
            );
            IERC20(_path[1]).safeTransfer(vault, midOut);
            return _vaultSwap(_path[1], _path[2], _minOut, _receiver, midOut);
        }

        revert("Router: invalid _path.length");
    }

    function _vaultSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _minOut,
        address _receiver,
        uint256 _amountIn
    ) private returns (uint256) {
        uint256 _amountOut;

        if (_tokenOut == nusd) {
            // buyNUSD
            _amountOut = IVault(vault).buyNUSD(_tokenIn, _receiver);
        } else if (_tokenIn == nusd) {
            // sellNUSD
            _amountOut = IVault(vault).sellNUSD(_tokenOut, _receiver);
        } else {
            // swap
            _amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        }

        require(_amountOut >= _minOut, "Router: insufficient amountOut");

        /* Minting means contributing collateral for lending */
        if (deltaYieldTracker != address(0)) {
            if (_tokenOut == nusd) {
                IDeltaYieldTracker(deltaYieldTracker).updateMintedRewards(
                    _sender(),
                    _tokenIn,
                    _amountIn,
                    true
                );
                /* Burning means removing collateral from lending */
            } else if (_tokenIn == nusd) {
                IDeltaYieldTracker(deltaYieldTracker).updateMintedRewards(
                    _sender(),
                    _tokenOut,
                    _amountOut,
                    false
                );
            }
        }

        return _amountOut;
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }

    function _validatePlugin(address _account) private view {
        require(plugins[msg.sender], "Router: invalid plugin");
        require(
            approvedPlugins[_account][msg.sender],
            "Router: plugin not approved"
        );
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IVault {
    function getRedemptionCollateralUsd(address _token)
        external
        view
        returns (uint256);

    function setIsMintingEnabled(bool _isMintingEnabled) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setFees(
        uint256 _swapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function setRewardRedemptionBasisPoints(
        uint256 _rewardRedemptionBasisPoints
    ) external;

    function setMaxNUSD(uint256 _maxNUSDBatchSize, uint256 _maxNUSDBuffer)
        external;

    function directPoolDeposit(address _token) external;

    function redeemReward(uint256 _amount, address _receiver)
        external
        returns (uint256[] memory);

    function buyNUSD(address _token, address _receiver)
        external
        returns (uint256);

    function sellNUSD(address _token, address _receiver)
        external
        returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token)
        external
        view
        returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function rewardRedemptionBasisPoints() external view returns (uint256);

    function rewardDistributor() external view returns (address);

    function swapFeeBasisPoints() external view returns (uint256);

    function feeReserves(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function nusdAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _nusdAmount)
        external
        view
        returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getUtilisation(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function withdrawFees(address _token, address _receiver)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRouter {
    function addPlugin(address _plugin) external;

    function nusd() external view returns (address);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;

    function vault() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDeltaYieldTracker {
    function claim(address _account) external;

    function getCollaterals() external view returns (address[] memory);

    function updateDeltaRewards(
        address _account,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        bool _isIncreasePosition
    ) external;

    function updateMintedRewards(
        address _account,
        address _tokenIn,
        uint256 _amountIn,
        bool _isMinting
    ) external;

    function getTokensPerIntervalPerCollateral(address _collateralToken)
        external
        view
        returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function _getPositiveTotalCollateralDeltaForAccount(address _account)
        external
        view
        returns (uint256);

    function _getTotalCollateralMintedForAccount(address _account)
        external
        view
        returns (uint256);

    function transferMintedRewards(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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
  "libraries": {}
}
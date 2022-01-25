// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./gelato/GelatoTask.sol";
import "./router/IRouter.sol";
import "./TokenHandler.sol";

interface IHundredERC20 is IERC20 {
    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint);
}

interface IGauge is IERC20 {
    function deposit(uint _value) external;
}

interface TokenMinter {
    function mint_for(address gauge_addr, address _for) external;
}

/**
 * @dev Stakes MIM in hundred.finance.
 * @notice Needs approval for MIM, HND, and any added source token.
 * Wallet also needs to call `toggle_approve_mint` on the `MINTER`
 * to allow this contract to claim/compound the rewards.
 */
contract MIM100 is GelatoTask, TokenHandler {

    using SafeERC20 for IERC20;

    address constant MIM = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address constant hMIM = 0xa8cD5D59827514BCF343EC19F531ce1788Ea48f8;
    address constant hMIMg = 0x26596af66A10Cb6c6fe890273eD37980D50f2448;
    address constant HND = 0x10010078a54396F62c96dF8532dc2B4847d47ED3;
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant SPOOKY = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address private immutable _minter;

    address[] private _HNDSwapPath;

    struct TokenInfo {
        IHundredERC20 underlying;
        IGauge gauge;
        address[] swapPath;
    }

    mapping (address => TokenInfo) _tokens;

    constructor(
        address minter,
        address pokeMe,
        uint maxGasPrice
    )
        GelatoTask(pokeMe, maxGasPrice)
    {
        _minter = minter;
        _HNDSwapPath = new address[](3);
        _HNDSwapPath[0] = HND;
        _HNDSwapPath[1] = WFTM;
        _HNDSwapPath[2] = MIM;
    }

    mapping (address => bool) _compounding;
    mapping (address => address[]) _sourceTokens;
    mapping (address => mapping (address => address[])) _swapPaths;

    function setHNDSwapPath(address[] memory path) external onlyOwner {
        require(path[0] == HND, "path not starting with HND");
        require(path[path.length - 1] == MIM, "path not ending with MIM");
        _HNDSwapPath = path;
    }

    function getSourceTokens() external view returns (address[] memory) {
        return _sourceTokens[msg.sender];
    }

    function addSourceToken(address token, address[] memory swapPath) external {
        require(swapPath[swapPath.length - 1] == MIM, "not swapping to MIM");
        address wallet = msg.sender;
        address[] memory sourceTokens = _sourceTokens[wallet];
        uint numSourceTokens = sourceTokens.length;
        bool tracked;
        for (uint i = 0; i < numSourceTokens; i++) {
            if (sourceTokens[i] == token) {
                tracked = true;
                break;
            }
        }
        if (!tracked) {
            _sourceTokens[wallet].push(token);
        }
        _swapPaths[wallet][token] = swapPath;
    }

    function removeSourceToken(address token) external {
        address wallet = msg.sender;
        address[] storage sourceTokens = _sourceTokens[wallet];
        uint numSourceTokens = sourceTokens.length;
        for (uint i = 0; i < numSourceTokens; i++) {
            if (sourceTokens[i] == token) {
                uint lastIndex = numSourceTokens - 1;
                if (i < lastIndex) {
                    sourceTokens[i] = sourceTokens[lastIndex];
                }
                delete sourceTokens[lastIndex];
                break;
            }
        }
        delete _swapPaths[wallet][token];
    }

    function toggleCompounding() external {
        _compounding[msg.sender] = !_compounding[msg.sender];
    }

    function supply(address wallet) external onlyManager(wallet) validGasPrice {
        _swapAll(wallet);
        uint amount = _transferableAmount(wallet, MIM);
        require(amount > 0, "no tokens available");
        IERC20(MIM).safeTransferFrom(wallet, address(this), amount);
        _supply(wallet, amount, _compounding[wallet]);
        IGauge(hMIMg).transfer(wallet, IGauge(hMIMg).balanceOf(address(this)));
    }

    function _swapAll(address wallet) private {
        address[] memory sourceTokens = _sourceTokens[wallet];
        uint numSourceTokens = sourceTokens.length;
        for (uint i = 0; i < numSourceTokens; i++) {
            address token = sourceTokens[i];
            uint amount = _transferableAmount(wallet, token);
            if (amount > 0) {
                IERC20(token).safeTransferFrom(wallet, address(this), amount);
                _approveMaxIfNecessary(token, SPOOKY, amount);
                IRouter(SPOOKY).swapExactTokensForTokens(amount, 0, _swapPaths[wallet][token], wallet, block.timestamp);
            }
        }
    }

    function _supply(address wallet, uint amount, bool compound) private {
        _approveMaxIfNecessary(MIM, hMIM, amount);
        uint err = IHundredERC20(hMIM).mint(amount);
        require(err == 0, "failed to supply");
        _stake(wallet, compound);
    }

    function _stake(address wallet, bool compound) private {
        uint amount = IERC20(hMIM).balanceOf(address(this));
        if (amount > 0) {
            _approveMaxIfNecessary(hMIM, hMIMg, amount);
            IGauge(hMIMg).deposit(amount);
            if (compound) _compound(wallet);
        }
    }

    function _compound(address wallet) private {
        TokenMinter(_minter).mint_for(hMIMg, wallet);
        uint amount = _transferableAmount(wallet, HND);
        if (amount > 0) {
            IERC20(HND).safeTransferFrom(wallet, address(this), amount);
            _approveMaxIfNecessary(HND, SPOOKY, amount);
            uint[] memory amountsOut = IRouter(SPOOKY).swapExactTokensForTokens(amount, 0, _HNDSwapPath, address(this), block.timestamp);
            uint amountOut = amountsOut[amountsOut.length - 1];
            _supply(wallet, amountOut, false);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../util/Ownable.sol";

abstract contract GelatoTask is Ownable {

    uint private _maxGasPrice;

    address internal immutable _pokeMe;

    constructor(address pokeMe, uint maxGasPrice) {
        _pokeMe = pokeMe;
        _maxGasPrice = maxGasPrice;
    }

    function setMaxGasPrice(uint maxGasPrice) external onlyOwner {
        _maxGasPrice = maxGasPrice;
    }

    modifier validGasPrice() {
        require(tx.gasprice <= _maxGasPrice, "gas price too high");
        _;
    }

    modifier onlyManager(address wallet) {
        require(msg.sender == _pokeMe || msg.sender == wallet);
        _;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IRouter {

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

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TokenHandler {

    function _approveMaxIfNecessary(
        address token,
        address spender,
        uint amount
    ) internal {
        uint allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            IERC20(token).approve(spender, type(uint).max);
        }
    }

    function _transferableAmount(address wallet, address token)
        internal
        view
        returns (uint amount)
    {
        uint balance = IERC20(token).balanceOf(wallet);
        uint allowance = IERC20(token).allowance(wallet, address(this));
        amount = balance < allowance ? balance : allowance;
    }

    function _transferableAmount(address wallet, address token, uint maxAmount)
        internal
        view
        returns (uint amount)
    {
        amount = _transferableAmount(wallet, token);
        if (amount > maxAmount) {
            amount = maxAmount;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

contract Ownable {

    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender== _owner, "caller is not the owner");
        _;
    }
}
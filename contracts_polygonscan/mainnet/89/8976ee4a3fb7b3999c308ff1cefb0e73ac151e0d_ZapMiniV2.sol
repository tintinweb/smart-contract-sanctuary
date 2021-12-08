// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWMATIC.sol";

interface ICurvePool {
    function underlying_coins(uint256) external returns (address);

    function lp_token() external returns (address);
}

interface ICurveSwap2 {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;
}

interface ICurveSwap3 {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;
}

interface ICurveSwap4 {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[4] memory amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;
}

interface ICurveSwap5 {
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[5] memory amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;
}

contract ZapMiniV2 is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct ProtocolStats {
        mapping(bytes32 => address) intermediateTokens;
        address router;
        address factory;
    }

    struct ZapInCurveForm {
        address from;
        uint256 amount;
        address curvePool;
        uint256 poolLength;
        address depositToken;
        uint8 depositTokenIndex;
        address to;
        bool use_underlying;
    }

    struct ZapInCurveMultiTokenForm {
        address[] from;
        uint256[] amount;
        address curvePool;
        uint256 poolLength;
        address depositToken;
        uint8 depositTokenIndex;
        address to;
        bool use_underlying;
    }

    struct ZapInForm {
        bytes32 protocolType;
        address from;
        uint256 amount;
        address to;
        address receiver;
    }

    struct ZapInMultiTokenForm {
        bytes32 protocolType;
        address[] from;
        uint256[] amount;
        address to;
        address receiver;
    }

    /* ========== CONSTANT VARIABLES ========== */

    address public USDT;
    address public DAI;
    address public WMATIC;
    address public USDC;
    address public WETH;

    /* ========== STATE VARIABLES ========== */

    mapping(bytes32 => ProtocolStats) public protocols; // ex protocol: quickswap, sushiswap

    event ZapIn(
        address indexed token,
        address indexed lpToken,
        uint256 indexed amount,
        bytes32 protocol
    );

    /* ========== INITIALIZER ========== */

    function initialize(
        address _USDT,
        address _DAI,
        address _WMATIC,
        address _USDC,
        address _WETH
    ) external initializer {
        __Ownable_init();
        require(owner() != address(0), "ZapETH: owner must be set");

        USDC = _USDC;
        USDT = _USDT;
        WMATIC = _WMATIC;
        WETH = _WETH;
        DAI = _DAI;
    }

    // solhint-disable-next-line
    receive() external payable {}

    /* ========== View Functions ========== */

    /// @notice get router pair address for protocol
    /// @param _type protocol type
    /// @param _token0 token0 address
    /// @param _token1 token1 address
    /// @return address
    function getIntermediateToken(
        bytes32 _type,
        address _token0,
        address _token1
    ) external view returns (address) {
        return
            protocols[_type].intermediateTokens[
                _getBytes32Key(_token0, _token1)
            ];
    }

    /// @notice zap in for token ERC20
    /// @dev in V1, token will convert to ETH, then ETH => token0, token1 => LP
    /// but in this version, we do not convert to ETH, A => token0, token1 => LP
    /// @param _params zapIn params
    function zapInMultiToken(ZapInMultiTokenForm calldata _params)
        public
        returns (uint256 liquidity)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_params.to);
        address token0 = pair.token0();
        address token1 = pair.token1();

        _swapMultiTokenToLPPairToken(
            _params.protocolType,
            _params.from,
            _params.amount,
            token0,
            token1,
            _params.to
        );

        liquidity = _addLiquidity(
            protocols[_params.protocolType].router,
            token0,
            token1,
            _params.receiver
        );

        // send excess amount to msg.sender
        _transferExcessBalance(token0, msg.sender);
        _transferExcessBalance(token1, msg.sender);
    }

    /// @notice zap in for token ERC20
    /// @dev in V1, token will convert to ETH, then ETH => token0, token1 => LP
    /// but in this version, we do not convert to ETH, A => token0, token1 => LP
    /// @param _params zapIn params
    function zapInToken(ZapInForm calldata _params)
        public
        returns (uint256 liquidity)
    {
        IERC20(_params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _params.amount
        );
        address router = protocols[_params.protocolType].router;

        _approveTokenIfNeeded(router, _params.from);

        IUniswapV2Pair pair = IUniswapV2Pair(_params.to);
        address token0 = pair.token0();
        address token1 = pair.token1();

        _swapTokenToLPPairToken(
            _params.protocolType,
            _params.from,
            _params.amount,
            token0,
            token1,
            _params.to
        );
        liquidity = _addLiquidity(
            protocols[_params.protocolType].router,
            token0,
            token1,
            _params.receiver
        );
        // send excess amount to msg.sender
        _transferExcessBalance(token0, msg.sender);
        _transferExcessBalance(token1, msg.sender);
    }

    /// @notice zap in token with custom route
    /// @dev in V1, token will convert to ETH, then ETH => token0, token1 => LP
    /// but in this version, we do not convert to ETH, A => token0, token1 => LP
    /// @param _params zapIn params
    /// @param _path0 path1
    /// @param _path1 path2
    function zapInTokenV2(
        ZapInForm memory _params,
        address[] calldata _path0,
        address[] calldata _path1
    ) public returns (uint256 liquidity) {
        IERC20(_params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _params.amount
        );
        address router = protocols[_params.protocolType].router;
        _approveTokenIfNeeded(router, _params.from);

        IUniswapV2Pair pair = IUniswapV2Pair(_params.to);
        address token0 = pair.token0();
        address token1 = pair.token1();

        _swapTokenToLPPairTokenByPath(
            _params.protocolType,
            _params.from,
            _params.amount,
            token0,
            token1,
            _params.to,
            _path0,
            _path1
        );
        liquidity = _addLiquidity(
            protocols[_params.protocolType].router,
            token0,
            token1,
            _params.receiver
        );

        // send excess amount to msg.sender
        _transferExcessBalance(token0, msg.sender);
        _transferExcessBalance(token1, msg.sender);
    }

    /// @notice zap in for multi token ERC20 - curve protocol
    function zapInTokenCurve(ZapInCurveForm memory _params)
        public
        returns (uint256 liquidity)
    {
        IERC20(_params.from).safeTransferFrom(
            msg.sender,
            address(this),
            _params.amount
        );

        // convert _from to first token of _params.curvePool by sushi protocol
        {
            if (_params.from != _params.depositToken) {
                bytes32 sushi = keccak256("SUSHISWAP");
                address router = protocols[sushi].router;
                _approveTokenIfNeeded(router, _params.from);
                _swap(
                    sushi,
                    _params.from,
                    _params.amount,
                    _params.depositToken,
                    address(this)
                );
            }
        }

        uint256 tokenBalance = IERC20(_params.depositToken).balanceOf(
            address(this)
        );
        _approveTokenIfNeeded(_params.curvePool, _params.depositToken);

        if (_params.use_underlying) {
            if (_params.poolLength == 2) {
                uint256[2] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap2(_params.curvePool).add_liquidity(amounts, 0, true);
            } else if (_params.poolLength == 3) {
                uint256[3] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap3(_params.curvePool).add_liquidity(amounts, 0, true);
            } else if (_params.poolLength == 4) {
                uint256[4] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap4(_params.curvePool).add_liquidity(amounts, 0, true);
            }
            // max = 5 coins
            else {
                uint256[5] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap5(_params.curvePool).add_liquidity(amounts, 0, true);
            }
        } else {
            if (_params.poolLength == 2) {
                uint256[2] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap2(_params.curvePool).add_liquidity(amounts, 0);
            } else if (_params.poolLength == 3) {
                uint256[3] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap3(_params.curvePool).add_liquidity(amounts, 0);
            } else if (_params.poolLength == 4) {
                uint256[4] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap4(_params.curvePool).add_liquidity(amounts, 0);
            }
            // max = 5 coins
            else {
                uint256[5] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap5(_params.curvePool).add_liquidity(amounts, 0);
            }
        }

        liquidity = IERC20(_params.to).balanceOf(address(this));
        IERC20(_params.to).safeTransfer(msg.sender, liquidity);
    }

    /// @notice zap in for token ERC20 - curve protocol
    function zapInMultiTokenCurve(ZapInCurveMultiTokenForm memory _params)
        public
        returns (uint256 liquidity)
    {
        require(
            _params.from.length == _params.amount.length,
            "Zap: Invalid input params"
        );

        uint256 length = _params.from.length;
        for (uint256 i = 0; i < length; i++) {
            address from = _params.from[i];
            uint256 amount = _params.amount[i];

            IERC20(from).safeTransferFrom(msg.sender, address(this), amount);

            // convert _from to first token of _params.curvePool by sushi protocol
            {
                if (from != _params.depositToken) {
                    bytes32 sushi = keccak256("SUSHISWAP");
                    address router = protocols[sushi].router;
                    _approveTokenIfNeeded(router, from);
                    _swap(
                        sushi,
                        from,
                        amount,
                        _params.depositToken,
                        address(this)
                    );
                }
            }
        }

        uint256 tokenBalance = IERC20(_params.depositToken).balanceOf(
            address(this)
        );
        _approveTokenIfNeeded(_params.curvePool, _params.depositToken);

        if (_params.use_underlying) {
            if (_params.poolLength == 2) {
                uint256[2] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap2(_params.curvePool).add_liquidity(amounts, 0, true);
            } else if (_params.poolLength == 3) {
                uint256[3] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap3(_params.curvePool).add_liquidity(amounts, 0, true);
            } else if (_params.poolLength == 4) {
                uint256[4] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap4(_params.curvePool).add_liquidity(amounts, 0, true);
            }
            // max = 5 coins
            else {
                uint256[5] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap5(_params.curvePool).add_liquidity(amounts, 0, true);
            }
        } else {
            if (_params.poolLength == 2) {
                uint256[2] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap2(_params.curvePool).add_liquidity(amounts, 0);
            } else if (_params.poolLength == 3) {
                uint256[3] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap3(_params.curvePool).add_liquidity(amounts, 0);
            } else if (_params.poolLength == 4) {
                uint256[4] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap4(_params.curvePool).add_liquidity(amounts, 0);
            }
            // max = 5 coins
            else {
                uint256[5] memory amounts;
                amounts[_params.depositTokenIndex] = tokenBalance;

                ICurveSwap5(_params.curvePool).add_liquidity(amounts, 0);
            }
        }

        liquidity = IERC20(_params.to).balanceOf(address(this));
        IERC20(_params.to).safeTransfer(msg.sender, liquidity);
    }

    /// @notice zap in ETH to LP
    /// @param _type protocol type
    /// @param _to lp token out
    /// @param _receiver receiver address
    function zapIn(
        bytes32 _type,
        address _to,
        address _receiver
    ) external payable {
        _swapETHToLP(_type, _to, msg.value, _receiver);

        // send excess amount to msg.sender
        IUniswapV2Pair pair = IUniswapV2Pair(_to);
        address token0 = pair.token0();
        address token1 = pair.token1();

        _transferExcessBalance(token0, msg.sender);
        _transferExcessBalance(token1, msg.sender);

        emit ZapIn(WMATIC, _to, msg.value, _type);
    }

    // @notice zap out LP to token
    /// @param _type protocol type
    /// @param _from lp token in
    /// @param _amount amount LP in
    /// @param _receiver receiver address
    function zapOut(
        bytes32 _type,
        address _from,
        uint256 _amount,
        address _receiver
    ) external {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        address router = protocols[_type].router;
        _approveTokenIfNeeded(router, _from);

        IUniswapV2Pair pair = IUniswapV2Pair(_from);
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (token0 == WMATIC || token1 == WMATIC) {
            IUniswapV2Router02(router).removeLiquidityETH(
                token0 != WMATIC ? token0 : token1,
                _amount,
                0,
                0,
                _receiver,
                block.timestamp
            );
        } else {
            IUniswapV2Router02(router).removeLiquidity(
                token0,
                token1,
                _amount,
                0,
                0,
                _receiver,
                block.timestamp
            );
        }
    }

    // @notice zap out LP to token
    /// @param _type protocol type
    /// @param _from lp token in
    /// @param _amount amount LP in
    /// @param _receiver receiver address
    function zapOutMultipleToken(
        bytes32 _type,
        address _from,
        uint256 _amount,
        address[] calldata _toTokens,
        uint8[] calldata _toRatios,
        address _receiver
    ) external {
        uint256 length = _toTokens.length;

        uint8 totalRatio;
        for (uint256 i = 0; i < length; i++) {
            totalRatio = totalRatio + _toRatios[i];
        }
        require(totalRatio == uint8(100), "Zap: Invalid ratio");

        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        address router = protocols[_type].router;
        _approveTokenIfNeeded(router, _from);

        IUniswapV2Pair pair = IUniswapV2Pair(_from);
        address token0 = pair.token0();
        address token1 = pair.token1();
        IUniswapV2Router02(router).removeLiquidity(
            token0,
            token1,
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        // convert token0 to token 1
        {
            address[] memory path = new address[](2);
            path[0] = token0;
            path[1] = token1;
            _approveTokenIfNeeded(router, token0);
            IUniswapV2Router02(router).swapExactTokensForTokens(
                _amount,
                0,
                path,
                _receiver,
                block.timestamp
            );
        }

        uint256 token1Balance = IERC20(token1).balanceOf(address(this));
        for (uint256 i = 0; i < length; i++) {
            address[] memory tempPath = new address[](2);
            tempPath[0] = token1;
            tempPath[1] = _toTokens[i];

            uint256 amount = (_toRatios[i] * token1Balance) / 100;

            if (token1 == _toTokens[i]) {
                IERC20(token1).transfer(_receiver, amount);
                continue;
            }
            if (i == length - 1) {
                amount = IERC20(token1).balanceOf(address(this));
            }

            IUniswapV2Router02(router).swapExactTokensForTokens(
                amount,
                0,
                tempPath,
                _receiver,
                block.timestamp
            );
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice withdraw token that contract hold
    /// @param _token token address
    function withdraw(address _token) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(_token).transfer(
            owner(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    // @notice set factory and router for protocol
    /// @param _type protocol type
    /// @param _factory factory address
    /// @param _router router address
    function setFactoryAndRouter(
        bytes32 _type,
        address _factory,
        address _router
    ) external onlyOwner {
        protocols[_type].router = _router;
        protocols[_type].factory = _factory;
    }

    /// @notice set intermediate token for  token0 - token1
    /// @param _type protocol type
    /// @param _token0 token0 address
    /// @param _token1 token1 address
    /// @param _intermediateAddress intermediate token address
    function addIntermediateToken(
        bytes32 _type,
        address _token0,
        address _token1,
        address _intermediateAddress
    ) external onlyOwner {
        bytes32 key = _getBytes32Key(_token0, _token1);
        protocols[_type].intermediateTokens[key] = _intermediateAddress;
    }

    /// @notice unset intermediate token for  token0 - token1
    /// @param _type protocol type
    /// @param _token0 token0 address
    /// @param _token1 token1 address
    function removeIntermediateToken(
        bytes32 _type,
        address _token0,
        address _token1
    ) external onlyOwner {
        bytes32 key = _getBytes32Key(_token0, _token1);
        protocols[_type].intermediateTokens[key] = address(0);
    }

    /* ========== Private Functions ========== */

    /// @notice swap ETH to LP token, ETH is MATIC in polygon
    /// @param _type protocol type
    /// @param _lp lp address
    /// @param _amount amount to swap
    /// @param _receiver receiver address
    function _swapETHToLP(
        bytes32 _type,
        address _lp,
        uint256 _amount,
        address _receiver
    ) private {
        IUniswapV2Pair pair = IUniswapV2Pair(_lp);
        address router = protocols[_type].router;
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (token0 == WMATIC || token1 == WMATIC) {
            address token = token0 == WMATIC ? token1 : token0;
            uint256 swapValue = _amount / 2;
            uint256 tokenAmount = _swapETHForToken(
                _type,
                token,
                swapValue,
                address(this)
            );

            _approveTokenIfNeeded(router, token);
            IUniswapV2Router02(router).addLiquidityETH{
                value: _amount - swapValue
            }(token, tokenAmount, 0, 0, _receiver, block.timestamp);
        } else {
            uint256 swapValue = _amount / 2;
            uint256 token0Amount = _swapETHForToken(
                _type,
                token0,
                swapValue,
                address(this)
            );
            uint256 token1Amount = _swapETHForToken(
                _type,
                token1,
                _amount - swapValue,
                address(this)
            );

            _approveTokenIfNeeded(router, token0);
            _approveTokenIfNeeded(router, token1);
            IUniswapV2Router02(router).addLiquidity(
                token0,
                token1,
                token0Amount,
                token1Amount,
                0,
                0,
                _receiver,
                block.timestamp
            );
        }
    }

    /// @notice swap ETH to token, ETH is MATIC in polygon
    /// @param _type protocol type
    /// @param _token token address
    /// @param _value amount to swap
    /// @param _receiver receiver address
    function _swapETHForToken(
        bytes32 _type,
        address _token,
        uint256 _value,
        address _receiver
    ) private returns (uint256) {
        address[] memory path;

        bytes32 keyPair = _getBytes32Key(WMATIC, _token);

        if (protocols[_type].intermediateTokens[keyPair] != address(0)) {
            path = new address[](3);
            path[0] = WMATIC;
            path[1] = protocols[_type].intermediateTokens[keyPair];
            path[2] = _token;
        } else {
            path = new address[](2);
            path[0] = WMATIC;
            path[1] = _token;
        }

        uint256[] memory amounts = IUniswapV2Router02(protocols[_type].router)
            .swapExactETHForTokens{ value: _value }(
            0,
            path,
            _receiver,
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }

    /// @notice swap token to token
    /// @param _type protocol type
    /// @param _from from token address
    /// @param _amount amount to swap
    /// @param _to to token address
    /// @param _receiver receiver address
    function _swap(
        bytes32 _type,
        address _from,
        uint256 _amount,
        address _to,
        address _receiver
    ) private returns (uint256) {
        // get pair of two token
        address factory = protocols[_type].factory;

        address pair = IUniswapV2Factory(factory).getPair(_from, _to);
        address[] memory path;

        if (pair != address(0)) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[2] = _to;

            address intermediateToken = protocols[_type].intermediateTokens[
                _getBytes32Key(_from, _to)
            ];
            if (intermediateToken != address(0)) {
                path[1] = intermediateToken;
            } else if (
                _hasPair(factory, _from, WETH) && _hasPair(factory, WETH, _to)
            ) {
                path[1] = WETH;
            } else if (
                _hasPair(factory, _from, USDC) && _hasPair(factory, USDC, _to)
            ) {
                path[1] = USDC;
            } else if (
                _hasPair(factory, _from, DAI) && _hasPair(factory, DAI, _to)
            ) {
                path[1] = DAI;
            } else if (
                _hasPair(factory, _from, USDT) && _hasPair(factory, USDT, _to)
            ) {
                path[1] = USDT;
            } else {
                revert("ZAP: NEP"); // not exist path
            }
        }

        _approveTokenIfNeeded(protocols[_type].router, path[0]);
        uint256[] memory amounts = IUniswapV2Router02(protocols[_type].router)
            .swapExactTokensForTokens(
                _amount,
                0,
                path,
                _receiver,
                block.timestamp
            );
        return amounts[amounts.length - 1];
    }

    /// @notice swap token to token with custom route
    /// @param _router router address
    /// @param _amount amount to swap
    /// @param _path route path
    /// @param _receiver receiver address
    function _swapByPath(
        address _router,
        uint256 _amount,
        address[] memory _path,
        address _receiver
    ) private returns (uint256) {
        _approveTokenIfNeeded(_router, _path[0]);
        uint256[] memory amounts = IUniswapV2Router02(_router)
            .swapExactTokensForTokens(
                _amount,
                0,
                _path,
                _receiver,
                block.timestamp
            );
        return amounts[amounts.length - 1];
    }

    /// @notice get key for pair token0 - token1 with key(token0, token1) === key(token1, token0)
    /// @param _token0 token0
    /// @param _token1 token1
    function _getBytes32Key(address _token0, address _token1)
        private
        pure
        returns (bytes32)
    {
        (_token0, _token1) = _token0 < _token1
            ? (_token0, _token1)
            : (_token1, _token0);
        return keccak256(abi.encodePacked(_token0, _token1));
    }

    /// @notice approve if needed
    /// @param _spender spender address
    /// @param _token token to approve
    function _approveTokenIfNeeded(address _spender, address _token) private {
        if (IERC20(_token).allowance(address(this), address(_spender)) == 0) {
            IERC20(_token).safeApprove(address(_spender), type(uint256).max);
        }
    }

    /// @notice check is has pair of token0 - token1
    /// @param _factory factory address
    /// @param _token0 token0 address
    /// @param _token1 token1 address
    function _hasPair(
        address _factory,
        address _token0,
        address _token1
    ) private view returns (bool) {
        return
            IUniswapV2Factory(_factory).getPair(_token0, _token1) != address(0);
    }

    /// @notice transfer excess balance to user, when user call zap func
    /// @param _token token to transfer
    /// @param _user receiver
    function _transferExcessBalance(address _token, address _user) private {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            IERC20(_token).safeTransfer(_user, amount);
        }
    }

    function _swapMultiTokenToLPPairToken(
        bytes32 _type,
        address[] memory _fromTokens,
        uint256[] memory _amounts,
        address _token0,
        address _token1,
        address _to
    ) private {
        uint256 length = _fromTokens.length;

        for (uint256 i = 0; i < length; i++) {
            _swapTokenToLPPairToken(
                _type,
                _fromTokens[i],
                _amounts[i],
                _token0,
                _token1,
                _to
            );
        }
    }

    function _swapTokenToLPPairToken(
        bytes32 _type,
        address _from,
        uint256 _amount,
        address _token0,
        address _token1,
        address _to
    ) private {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        // swap half amount for other
        if (_from == _token0 || _from == _token1) {
            address other = _from == _token0 ? _token1 : _token0;
            uint256 sellAmount = _amount / 2;
            _swap(_type, _from, sellAmount, other, address(this));
        } else {
            uint256 sellAmount = _amount / 2;
            _swap(_type, _from, sellAmount, _token0, address(this));
            _swap(_type, _from, _amount - sellAmount, _token1, address(this));
        }
        emit ZapIn(_from, _to, _amount, _type);
    }

    function _swapTokenToLPPairTokenByPath(
        bytes32 _type,
        address _from,
        uint256 _amount,
        address _token0,
        address _token1,
        address _to,
        address[] memory _path0,
        address[] memory _path1
    ) private {
        address router = protocols[_type].router;
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);
        // swap half amount for other
        if (_from == _token0 || _from == _token1) {
            address[] memory path = _from == _token0 ? _path1 : _path0;
            uint256 sellAmount = _amount / 2;
            _swapByPath(router, sellAmount, path, address(this));
        } else {
            uint256 sellAmount = _amount / 2;
            _swapByPath(router, sellAmount, _path0, address(this));
            _swapByPath(router, _amount - sellAmount, _path1, address(this));
        }
        emit ZapIn(_from, _to, _amount, _type);
    }

    function _addLiquidity(
        address _router,
        address _token0,
        address _token1,
        address _receiver
    ) private returns (uint256 liquidity) {
        _approveTokenIfNeeded(_router, _token0);
        _approveTokenIfNeeded(_router, _token1);
        (, , liquidity) = IUniswapV2Router02(_router).addLiquidity(
            _token0,
            _token1,
            IERC20(_token0).balanceOf(address(this)),
            IERC20(_token1).balanceOf(address(this)),
            0,
            0,
            _receiver,
            block.timestamp
        );
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IWMATIC {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}
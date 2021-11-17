/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// File: ForgePad-BackEnd/contracts/Tokens/SharedStructures.sol



pragma solidity ^0.8.4;


/**
 * Collection of structs for use with the token launcher
 */
library SharedStructures {
    struct TokenInfo {
        string name;
        string symbol;
        string tokenType;
        uint256 totalSupplyWithoutDecimals;
        uint256 bnbForLiquidity;
        uint8 decimals;
        uint8 initialMarketingPercent;
        uint8 initialBurnPercent;
        bool lockMarketingTokens;
        uint16 maxWalletPermille;
        uint16 maxTxPermille;
    }
    
    struct RewardInfo {
        uint256 minTokensForDividendsWithoutDecimals;
        uint24 claimWait; 
        address rewardToken;
        uint8 buyFee;
        uint8 sellFee;
    }
    
    struct FeeInfo {
        uint8 marketingFee;
        uint8 liquidityFee;
        uint8 burnFee;
        uint8 platformFee;
        bool marketingFundsInTokens;
    }
    
    struct AddressInfo {
        address marketingWallet;
        address tokenCreator;
        address router;
        address platformWallet;
        address tokenLocker;
        address lpLocker;
        address cloneFactory;
    }
    
    struct LaunchInfo {
        TokenInfo tokenInfo;
        RewardInfo[] rewardInfo;
        AddressInfo addressInfo;
        FeeInfo[2] feeInfo;
    }
    
    struct LockerInfo {
        address[] rewardTokens;
        address[2] lpTokenParts;
        address lockToken;
        bool isDoughLaunched;
        bool isLPToken;
        uint64 lockFee;
        address lockOwner;
        uint48 unlockTime;
        uint48 minLockPeriod;
        address platformWallet;
        uint16 rewardsClaimFeePermille;
        uint16 tokenLockFeePermille;
        uint16 numberOfTimesToVest;
        uint48 cliffEndTime;
        uint48 vestingPeriod;
        uint256 lockedTokenAmount;
        string lockerType;
    }
    
    /*
    bool[10] public test;
    
    function setTest(bool[10] memory _test) external {
        test = _test;
    }
    
    event Debug (string debugText, uint256 debugNum);
    */
}
// File: ForgePad-BackEnd/contracts/Tokens/IRewardLockerCloneable.sol



pragma solidity ^0.8.4;


interface IRewardLockerCloneable {
    function lock (SharedStructures.LockerInfo memory _lockerInfo, address _WETH) external payable; // Initial lock - may require a fee
    function lock (uint256 amount) external payable; // Additional token lock - must come from the lock owner
    function getLockerInfo() external view returns (SharedStructures.LockerInfo memory); // LockerInfo - can only be called by the contract creator (management contract)
    function transferLockOwnership (address newLockOwner) external; // transfer lock ownership to a different account - can only be called by the lock owner
    function getClaimableTokenAmount() external view returns (uint256); // how many tokens are currently available to be claimed
    function claimTokens (uint256 amount) external; // can only be called by the lock owner - claims avaiable tokens. This also claims rewards if available
    function claimRewards() external; // can only be called by the lock owner - claims available rewards
    function extendLockTime (uint48 newUnlockTime) external payable; // can only be called by the lock owner - extends the lock time - this may require a fee
    function getTokenBalance (address _token) external view returns (uint256); // returns the balance of _token in the contract
}
// File: ForgePad-BackEnd/contracts/Router/SwapInterfaces.sol



pragma solidity ^0.8.4;


interface ISwapFactory {
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

interface ISwapPair {
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

interface ISwapRouter01 {
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


interface ISwapRouter02 is ISwapRouter01 {
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
// File: ForgePad-BackEnd/contracts/Utils/Address.sol



pragma solidity ^0.8.4;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
// File: ForgePad-BackEnd/contracts/ERC20/SafeERC20.sol



pragma solidity ^0.8.4;



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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: ForgePad-BackEnd/contracts/ERC20/IERC20.sol



pragma solidity ^0.8.4;

interface IERC20 {

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
// File: ForgePad-BackEnd/contracts/Utils/Initializable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// File: ForgePad-BackEnd/contracts/Utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (utils/Context.sol)

pragma solidity ^0.8.0;


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
// File: ForgePad-BackEnd/contracts/Utils/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (access/Ownable.sol)

pragma solidity ^0.8.0;



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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
// File: ForgePad-BackEnd/contracts/Tokens/RewardLockerCloneable.sol



pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;







contract RewardLockerCloneable is Initializable, OwnableUpgradeable, IRewardLockerCloneable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    
    SharedStructures.LockerInfo private lockerInfo;
    address private WETH;
    bool public initialised;
    
    event LockOwnerChanged (address indexed oldLockOwner, address indexed newLockOwner);
    event RewardsClaimed (uint256[] amountsClaimed);
    event Lock (uint256 amountLocked);
    event Claimed (uint256 amountClaimed);
    event LockTimeExtended (uint256 oldUnlockTime, uint256 newUnlockTime);

    modifier onlyLockOwner {
        require (msg.sender == lockerInfo.lockOwner, "RL: Not authorised");
        require (initialised, "RL: Not initialised");
        _;
    }

    constructor () { }
    
    function lock (SharedStructures.LockerInfo memory _lockerInfo, address _WETH) external override payable initializer {
        require (_lockerInfo.lockOwner != address(0), "RL: Owner can't be the 0 address");
        require (_lockerInfo.lockToken != address(0), "RL: Lock token can't be the 0 address");
        require (_lockerInfo.platformWallet != address(0), "RL: Platform wallet can't be the 0 address");
        require (_WETH != address(0), "RL: WETH can't be the 0 address");
        
        __Ownable_init();
        lockerInfo = _lockerInfo;
        WETH = _WETH;
        
        if (_lockerInfo.lockToken != _WETH)
            _lock (_lockerInfo.lockedTokenAmount); //optimistically transfer tokens
            
        initialised = _lockerInfo.isDoughLaunched ? true : takeLockFee();
           
        require (initialised, "RL: Failed to take fees for lock");
    }
    
    receive() external payable {}
    
    function getLockerInfo() external view override returns (SharedStructures.LockerInfo memory) {
        return lockerInfo;
    }
    
    function takeLockFee() private returns (bool feePaid) {
        uint256 _lockFee = lockerInfo.lockFee;
        address _lockToken = lockerInfo.lockToken;
        address _WETH = WETH;
        uint16 _tokenLockFeePermille = lockerInfo.tokenLockFeePermille;
            
        if (_lockFee == 0 && _tokenLockFeePermille == 0)
            feePaid = true;
        else {
            if (_lockFee > 0) { // If there's a BNB fee that has been paid by the sender
                if (msg.value > _lockFee)
                    payable(lockerInfo.lockOwner).sendValue (msg.value - _lockFee);
                
                if (msg.value >= _lockFee) {
                    payable(lockerInfo.platformWallet).sendValue (_lockFee);
                    feePaid = true;
                }
            }
            
            if (_tokenLockFeePermille > 0 && !feePaid) { // If there's no BNB fee or one has not been paid by the sender
                uint256 feeAmount = lockerInfo.lockedTokenAmount * _tokenLockFeePermille / 1000;
                
                if (_lockToken != _WETH)
                    IERC20(_lockToken).safeTransferFrom (address(this), lockerInfo.platformWallet, feeAmount);
                else
                    payable(lockerInfo.platformWallet).sendValue (feeAmount);
                
                feePaid = true;
            }
            
            if (feePaid)
                lockerInfo.lockedTokenAmount = getTokenBalance (_lockToken);
        }
    }
    
    function transferLockOwnership (address newLockOwner) external override onlyLockOwner {
        address _lockOwner = lockerInfo.lockOwner;
        
        require (newLockOwner != address(0), "RL: New owner can't be the 0 address");
        require (newLockOwner != _lockOwner, "RL: Owner address is already set to this");
        
        emit LockOwnerChanged (_lockOwner, newLockOwner);
        lockerInfo.lockOwner = newLockOwner;
    }

    function lock (uint256 amount) public payable override onlyLockOwner {
        require (lockerInfo.numberOfTimesToVest == 0, "RL: Can't increase tokens in a vesting contract");
        _lock (amount);
    }
    
    function _lock (uint256 amount) private {
        require (amount > 0, "RL: Can't lock 0 tokens");
        
        _claimRewards (lockerInfo.rewardTokens);
        address _lockToken = lockerInfo.lockToken;
        
        // On creation, assumes management contract has the tokens, this address should be whitelisted once created
        if (_lockToken != WETH)
            IERC20(_lockToken).safeTransferFrom (lockerInfo.lockOwner, address(this), amount);
            
        // In case fees have been taken as part of the transfer store the contract balance NOT amount
        lockerInfo.lockedTokenAmount = getTokenBalance (_lockToken);
        emit Lock (amount);
    }
    
    function getTokenBalance (address _token) public view override returns (uint256) {
        if (_token != WETH)
            return IERC20(_token).balanceOf (address(this));
        else
            return address(this).balance;
    }
    
    function getClaimableTokenAmount() public view override returns (uint256) {
        uint48 _unlockTime = lockerInfo.unlockTime;
        uint16 _numberOfTimesToVest = lockerInfo.numberOfTimesToVest;
        uint256 _lockTokenBalance = getTokenBalance (lockerInfo.lockToken);
        
        if (block.timestamp >= _unlockTime)
            return _lockTokenBalance;
        else if (_numberOfTimesToVest > 0 && block.timestamp > lockerInfo.cliffEndTime) {
            uint256 _lockedTokenAmount = lockerInfo.lockedTokenAmount;
            uint256 vestingPeriodsElapsed = (block.timestamp - lockerInfo.cliffEndTime) / lockerInfo.vestingPeriod;
            uint256 claimableTokens = _lockedTokenAmount * vestingPeriodsElapsed / _numberOfTimesToVest;
            
            if (_lockTokenBalance < _lockedTokenAmount)
                claimableTokens -= (_lockedTokenAmount - _lockTokenBalance);
            
            return claimableTokens;
        }
        
        return 0;
    }

    // amount = 0 is claim all
    function claimTokens (uint256 amount) external override onlyLockOwner {
        address _lockToken = lockerInfo.lockToken;
        _claimRewards (lockerInfo.rewardTokens);    
        
        if (amount == 0)
             amount = getTokenBalance (_lockToken);
        
        require (amount <= getClaimableTokenAmount(), "RL: Too many claimed");
        
        if (_lockToken != WETH)
            IERC20(_lockToken).safeTransfer (lockerInfo.lockOwner, amount);
        else
            payable(lockerInfo.lockOwner).sendValue (amount);
            
        emit Claimed (amount);
    }

    function claimRewards() external override onlyLockOwner {
        _claimRewards (lockerInfo.rewardTokens);
    }
    
    function _claimRewards (address[] memory _rewardTokens) private {
        if (_rewardTokens.length > 0) {
            uint256[] memory amounts = new uint256[] (_rewardTokens.length);
            
            for (uint256 i = 0; i < _rewardTokens.length; i++) {
                if (_rewardTokens[i] != lockerInfo.lockToken) {
                    amounts[i] = getTokenBalance (_rewardTokens[i]);
                } else {
                    uint256 currentBalance = IERC20(_rewardTokens[i]).balanceOf (address(this));
                    uint256 _lockedTokenAmount = lockerInfo.lockedTokenAmount;
                    
                    if (currentBalance > _lockedTokenAmount)
                        amounts[i] = currentBalance - _lockedTokenAmount;
                }
                
                if (amounts[i] > 0) {
                    uint256 feeAmount = amounts[i] * lockerInfo.rewardsClaimFeePermille / 1000;
                    
                    if (_rewardTokens[i] != WETH) {
                        IERC20(_rewardTokens[i]).safeTransfer (lockerInfo.platformWallet, feeAmount);
                        IERC20(_rewardTokens[i]).safeTransfer (lockerInfo.lockOwner, amounts[i] - feeAmount);
                    } else {
                        payable(lockerInfo.platformWallet).sendValue (feeAmount);
                        payable(lockerInfo.lockOwner).sendValue (amounts[i] - feeAmount);
                    }
                }
            }
            
            emit RewardsClaimed (amounts);
        }
    }

    function extendLockTime (uint48 newUnlockTime) external payable override onlyLockOwner {
        uint48 _unlockTime = lockerInfo.unlockTime;
        require (newUnlockTime > _unlockTime && newUnlockTime >= block.timestamp + lockerInfo.minLockPeriod, "RL: Unlock time too soon");
        
        _claimRewards (lockerInfo.rewardTokens); 
        takeLockFee();
        emit LockTimeExtended (_unlockTime, newUnlockTime);
        lockerInfo.unlockTime = newUnlockTime;
    }
}
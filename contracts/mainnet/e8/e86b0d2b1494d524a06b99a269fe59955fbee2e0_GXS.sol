/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity >=0.6.2 <0.8.0;

contract State {

    mapping (address => uint256) _largeBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Supported pools and data for measuring mint & burn factors
    struct PoolCounter {
        address pairToken;
        uint256 tokenBalance;
        uint256 pairTokenBalance;
        uint256 lpBalance;
        uint256 startTokenBalance;
        uint256 startPairTokenBalance;
    }
    address[] _supportedPools;
    mapping (address => PoolCounter) _poolCounters;
    mapping (address => bool) _isSupportedPool;
    address _mainPool;

    uint256 _currentEpoch;
    
    //Creating locked balances
    struct LockBox {
        address beneficiary;
        uint256 lockedBalance;
        uint256 unlockTime;
        bool locked;
    }
    LockBox[] _lockBoxes;
    mapping(address => uint256) _lockedBalance;
    mapping(address => bool) _hasLockedBalance;
    uint256 _totalLockedBalance;
 
    uint256 _largeTotal;
    uint256 _totalSupply;

    address _liquidityReserve;
    address _stabilizer;

    bool _presaleDone;
    address _presaleCon;
    
    bool _paused;
    
    bool _taxLess;
    mapping(address=>bool) _isTaxlessSetter;
}


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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity ^0.6.12;

library Constants {
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;

    uint256 private constant _launchSupply = 9500 * 10 ** uint256(_decimals);
    uint256 private constant _largeTotal = (MAX - (MAX % _launchSupply));

    uint256 private constant _baseExpansionFactor = 100;
    uint256 private constant _baseContractionFactor = 100;
    uint256 private constant _incentivePot = 50;
    uint256 private constant _baseUtilityFee = 50;
    uint256 private constant _baseContractionCap = 1000;

    uint256 private constant _stabilizerFee = 250;
    uint256 private constant _stabilizationLowerBound = 50;
    uint256 private constant _stabilizationLowerReset = 75;
    uint256 private constant _stabilizationUpperBound = 150;
    uint256 private constant _stabilizationUpperReset = 125;
    uint256 private constant _stabilizePercent = 10;

    uint256 private constant _treasuryFee = 250;

    uint256 private constant _epochLength = 4 hours;

    uint256 private constant _liquidityReward = 25 * 10**uint256(_decimals);
    uint256 private constant _minForLiquidity = 500 * 10**uint256(_decimals);
    uint256 private constant _minForCallerLiquidity = 500 * 10**uint256(_decimals);

    address private constant _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    string private constant _name = "gxs-protocol.net";
    string private constant _symbol = "GXS";

    /****** Getters *******/
    function getLaunchSupply() internal pure returns (uint256) {
        return _launchSupply;
    }
    function getLargeTotal() internal pure returns (uint256) {
        return _largeTotal;
    }
    function getBaseExpansionFactor() internal pure returns (uint256) {
        return _baseExpansionFactor;
    }
    function getBaseContractionFactor() internal pure returns (uint256) {
        return _baseContractionFactor;
    }
    function getIncentivePot() internal pure returns (uint256) {
        return _incentivePot;
    }
    function getBaseContractionCap() internal pure returns (uint256) {
        return _baseContractionCap;
    }
    function getBaseUtilityFee() internal pure returns (uint256) {
        return _baseUtilityFee;
    }
    function getStabilizerFee() internal pure returns (uint256) {
        return _stabilizerFee;
    }
    function getStabilizationLowerBound() internal pure returns (uint256) {
        return _stabilizationLowerBound;
    }
    function getStabilizationLowerReset() internal pure returns (uint256) {
        return _stabilizationLowerReset;
    }
    function getStabilizationUpperBound() internal pure returns (uint256) {
        return _stabilizationUpperBound;
    }
    function getStabilizationUpperReset() internal pure returns (uint256) {
        return _stabilizationUpperReset;
    }
    function getStabilizePercent() internal pure returns (uint256) {
        return _stabilizePercent;
    }
    function getTreasuryFee() internal pure returns (uint256) {
        return _treasuryFee;
    }
    function getEpochLength() internal pure returns (uint256) {
        return _epochLength;
    }
    function getLiquidityReward() internal pure returns (uint256) {
        return _liquidityReward;
    }
    function getMinForLiquidity() internal pure returns (uint256) {
        return _minForLiquidity;
    }
    function getMinForCallerLiquidity() internal pure returns (uint256) {
        return _minForCallerLiquidity;
    }
    function getRouterAdd() internal pure returns (address) {
        return _routerAddress;
    }
    function getFactoryAdd() internal pure returns (address) {
        return _factoryAddress;
    }
    function getName() internal pure returns (string memory)  {
        return _name;
    }
    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }
    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }
}

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

pragma solidity ^0.6.12;


contract Getters is State {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    function getPoolCounters(address pool) public view returns (address, uint256, uint256, uint256, uint256, uint256) {
        PoolCounter memory pc = _poolCounters[pool];
        return (pc.pairToken, pc.tokenBalance, pc.pairTokenBalance, pc.lpBalance, pc.startTokenBalance, pc.startPairTokenBalance);
    }
    function isTaxlessSetter(address account) public view returns (bool) {
        return _isTaxlessSetter[account];
    }
    function getUniswapRouter() public view returns (IUniswapV2Router02) {
        return IUniswapV2Router02(Constants.getRouterAdd());
    }
    function getUniswapFactory() public view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(Constants.getFactoryAdd());
    }
    function getFactor() public view returns(uint256) {
        if (_presaleDone) {
            return _largeTotal.div(_totalSupply);
        } else {
            return _largeTotal.div(Constants.getLaunchSupply());
        }
    }
    function getUpdatedPoolCounters(address pool, address pairToken) public view returns (uint256, uint256, uint256) {
        uint256 lpBalance = IERC20(pool).totalSupply();
        uint256 tokenBalance = IERC20(address(this)).balanceOf(pool);
        uint256 pairTokenBalance = IERC20(address(pairToken)).balanceOf(pool);
        return (tokenBalance, pairTokenBalance, lpBalance);
    }
    function getMintValue(address sender, uint256 amount) internal view returns(uint256, uint256, uint256) {
        uint256 mintAmount = amount.mul(1).div(100);
        return (0,0,mintAmount);
    }

    function getBurnValues(address recipient, uint256 amount) internal view returns(uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 burnAmount = amount.mul(5).div(1000);
        return (burnAmount, burnAmount.mul(currentFactor));
    }

    function getUtilityFee(uint256 amount) internal view returns(uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 utilityFee = amount.mul(5).div(100);
        return (utilityFee, utilityFee.mul(currentFactor));
    }
}

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
pragma solidity >=0.5.0;

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
}pragma solidity >=0.6.2;

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
}pragma solidity >=0.6.2;


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
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract OwnableUpgradeable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.12;


contract Setters is State, Getters {
    function updatePresaleAddress(address presaleAddress) internal {
        _presaleCon = presaleAddress;
    }
    function setAllowances(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }
    function addToAccount(address account, uint256 amount) internal {
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        _largeBalances[account] = _largeBalances[account].add(largeAmount);
        _totalSupply = _totalSupply.add(amount);
    }
    function addToAll(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
    }
    function initializeEpoch() internal {
        _currentEpoch = now;
    }
    function updateEpoch() internal {
        initializeEpoch();
        for (uint256 i=0; i<_supportedPools.length; i++) {
            _poolCounters[_supportedPools[i]].startTokenBalance = _poolCounters[_supportedPools[i]].tokenBalance;
            _poolCounters[_supportedPools[i]].startPairTokenBalance = _poolCounters[_supportedPools[i]].pairTokenBalance;
        }
    }
    function initializeLargeTotal() internal {
        _largeTotal = Constants.getLargeTotal();
    }
    function syncPair(address pool) internal returns(bool) {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        bool lpBurn = lpBalance < _poolCounters[pool].lpBalance;
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
        return (lpBurn);
    }
    function silentSyncPair(address pool) public {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
    }
    function addSupportedPool(address pool, address pairToken) internal {
        require(!_isSupportedPool[pool],"This pool is already supported");
        _isSupportedPool[pool] = true;
        _supportedPools.push(pool);
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, pairToken);
        _poolCounters[pool] = PoolCounter(pairToken, tokenBalance, pairTokenBalance, lpBalance, tokenBalance, pairTokenBalance);
    }
}

pragma solidity ^0.6.12;

pragma solidity ^0.6.12;


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
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
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

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

library UniswapV2Library {
    using SafeMathUpgradeable for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
}

contract GXS is Setters, Initializable, IERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    
    mapping(address => uint256) public refunds;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public bots;

    
    uint256 public refundCooldown = 5 minutes;
    uint256 public minEthThreshold = 0.3 ether;
    uint256 public gasPrice = 100e9;
    uint256 public refundFrac = 50;
    uint256 public minRefund = 0.001 ether;
    uint256 public maxRefund = 0.025 ether;
    uint256 public gasRefund = 0.025 ether;
    uint256 public lastFund = 0;
    uint256 public fundCooldown = 5 minutes;
    uint256 public minFundThreshold = 0;
    uint256 public holdLimit = 200 * 10 ** 18;
    uint256 public botCount = 5;
    uint256 public botDelay = 45 minutes;
    bool public limitHold = true;
    bool public delayQuick = true;
    bool public delayWhitelist = true;
    

    address public uniswapPair;
    // address public stub;

    bool public isThisToken0;

    /// @notice last TWAP update time
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price
    uint256 public priceCumulativeLast;

    /// @notice last TWAP average price
    uint256 public priceAverageLast;

    /// @notice TWAP min delta (10-min)
    uint256 public minDeltaTwap;
    
    bool private _inInternalSell = false;

    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);
    event GasRefunded(address to, uint256 amount);

    modifier setInternalSell {
        _inInternalSell = true;
        _;
        _inInternalSell = false;
    }

    modifier onlyTaxless {
        require(isTaxlessSetter(msg.sender),"not taxless");
        _;
    }
    modifier onlyPresale {
        require(msg.sender==_presaleCon,"not presale");
        require(!_presaleDone, "Presale over");
        _;
    }
    modifier pausable {
        require(!_paused, "Paused");
        _;
    }
    modifier taxlessTx {
        _taxLess = true;
        _;
        _taxLess = false;
    }


    function name() public view returns (string memory) {
        return Constants.getName();
    }
    
    function symbol() public view returns (string memory) {
        return Constants.getSymbol();
    }
    
    function decimals() public view returns (uint8) {
        return Constants.getDecimals();
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() public view returns (uint256) {
        uint256 currentFactor = getFactor();
        return _totalSupply.sub(_totalLockedBalance.div(currentFactor)).sub(balanceOf(address(this))).sub(balanceOf(_stabilizer));
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        uint256 currentFactor = getFactor();
        if (_hasLockedBalance[account]) return (_largeBalances[account].add(_lockedBalance[account]).div(currentFactor));
        return _largeBalances[account].div(currentFactor);
    }
    
    function unlockedBalanceOf(address account) public view returns (uint256) {
        uint256 currentFactor = getFactor();
        return _largeBalances[account].div(currentFactor); 
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function mint(address to, uint256 amount) public onlyPresale {
        addToAccount(to,amount);
        emit Transfer(address(0),to,amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        setAllowances(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(sender),"Amount exceeds balance");
        require(amount <= unlockedBalanceOf(sender),"Amount exceeds unlocked balance");
        require(_presaleDone,"Presale yet to close");
        uint256 startGas = gasleft();
        bool takeFunds = owner() != sender && owner() != recipient && !_inInternalSell;
        bool funded = false;
        
        if (blockTimestampLast == 0 && balanceOf(uniswapPair) > 0) {
            initializeTwap();
        }
        
        if (delayWhitelist && whitelist[sender]) {
            revert('GXS: hold');
        }
        
        if (sender == address(this)) {
            basicTransfer(sender,recipient,amount);
            return;
        }
        
        if (delayQuick) {
            if (sender == uniswapPair) {
               if (botCount > 0) {
                   botCount -= 1;
                   bots[recipient] = block.timestamp;
               }
                
            } else if (recipient == uniswapPair && block.timestamp - bots[sender] < botDelay) {
                revert('GXS: too quick');
            }
        }
        
        if (limitHold && uniswapPair == sender) {
            if (balanceOf(recipient) + amount > holdLimit) {
                revert('GXS: too much');
            }
        }
        
        if (!_inInternalSell && sender != uniswapPair && now - lastFund > fundCooldown && balanceOf(_stabilizer) > minFundThreshold) {
            lastFund = now;
            funded = true;
            fundTreasury();
        }
        
        if (now > _currentEpoch.add(Constants.getEpochLength())) updateEpoch();
        uint256 currentFactor = getFactor();
        uint256 txType;
        if (_taxLess || sender == owner()) {
            txType = 3;
        } else {
            bool lpBurn;
            if (_isSupportedPool[sender]) {
                lpBurn = syncPair(sender);
            } else if (_isSupportedPool[recipient]){
                silentSyncPair(recipient);
            } else {
                silentSyncPair(_mainPool);
            }
            txType = _getTxType(sender, recipient, lpBurn);
        }

        // Buy Transaction from supported pools - requires mint, no utility fee
        if (txType == 1) {
            (uint256 stabilizerMint, uint256 treasuryMint, uint256 totalMint) = getMintValue(sender, amount);
            uint256 treasuryFee = amount.mul(4).div(100);
            uint256 actualTransferAmount = amount.sub(treasuryFee);

            basicTransfer(sender, recipient, actualTransferAmount);
            
            treasuryFee = treasuryFee.add(stabilizerMint).add(treasuryMint);
            _largeBalances[_stabilizer] = _largeBalances[_stabilizer].add(treasuryFee.mul(currentFactor));
            _totalSupply = _totalSupply.add(totalMint);
            emit Transfer(sender, recipient, actualTransferAmount);
            emit Transfer(address(0),_stabilizer,treasuryFee);
        }
        // Sells to supported pools or unsupported transfer - requires exit burn and utility fee
        else if (txType == 2) {
            (uint256 burnSize, uint256 largeBurnSize) = getBurnValues(recipient, amount);
            (uint256 utilityFee, uint256 largeUtilityFee) = getUtilityFee(amount);
            uint256 actualTransferAmount = amount.sub(burnSize).sub(utilityFee);
            basicTransfer(sender, recipient, actualTransferAmount);
            _largeBalances[_stabilizer] = _largeBalances[_stabilizer].add(largeUtilityFee);
            _totalSupply = _totalSupply.sub(burnSize);
            _largeTotal = _largeTotal.sub(largeBurnSize);
            emit Transfer(sender, recipient, actualTransferAmount);
            emit Transfer(sender, address(0), burnSize);
        } 
        // Add Liquidity via interface or Remove Liquidity Transaction to supported pools - no fee of any sort
        else if (txType == 3) {
            basicTransfer(sender, recipient, amount);
            emit Transfer(sender, recipient, amount);
        }
        
        if (!_inInternalSell && owner() != sender && !funded) {
            if (shouldRefundGas(sender, recipient, amount)) {
                uint256 gasUsed = startGas.sub(gasleft());
                refundGas(gasUsed);
            }
            
            _updateTwap();
        }
    }

    function _getTxType(address sender, address recipient, bool lpBurn) private returns(uint256) {
        uint256 txType = 2;
        if (_isSupportedPool[sender]) {
            if (lpBurn) {
                txType = 3;
            } else {
                txType = 1;
            }
        } else if (sender == Constants.getRouterAdd()) {
            txType = 3;
        }
        return txType;
    }

    function setPresale(address presaleAdd) public onlyOwner() {
        require(!_presaleDone, "Presale is already completed");
        updatePresaleAddress(presaleAdd);
    }
    function setDelayQuicksell(bool flag) external onlyOwner() {
        delayQuick = flag;
    }
    function setDelayWhitelist(bool flag) external onlyOwner() {
        delayWhitelist = flag;
    }
    function setLimitHold(bool flag) external onlyOwner() {
        limitHold = flag;
    }
    function setRefundPolicy(
    uint256 _minEth, 
    uint256 _gasPrice,
    uint256 _refundFrac,
    uint256 _minRefund,
    uint256 _maxRefund,
    uint256 _gasRefund) external onlyOwner() {
         minEthThreshold = _minEth;
         gasPrice = _gasPrice;
         refundFrac = _refundFrac;
         minRefund = _minRefund;
         maxRefund = _maxRefund;
         gasRefund = _gasRefund;
    }

    function setPresaleDone() public payable onlyPresale {
        require(!_presaleDone);
        _presaleDone = true;
        createEthPool();
    }

    function createEthPool() private onlyOwner() taxlessTx {
        IUniswapV2Router02 uniswapRouterV2 = getUniswapRouter();
        IUniswapV2Factory uniswapFactory = getUniswapFactory();
        address tokenUniswapPair;
        if (uniswapFactory.getPair(address(uniswapRouterV2.WETH()), address(this)) == address(0)) {
            tokenUniswapPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()), address(this));
        } else {
            tokenUniswapPair = uniswapFactory.getPair(address(this),uniswapRouterV2.WETH());
        }
        _approve(msg.sender, address(uniswapRouterV2), ~uint256(0));
        
        addSupportedPool(tokenUniswapPair, address(uniswapRouterV2.WETH()));
        _mainPool = tokenUniswapPair;
    }

    function setTaxlessSetter(address cont) external onlyOwner() {
        require(!isTaxlessSetter(cont),"already setter");
        _isTaxlessSetter[cont] = true;
    }

    function setTaxless(bool flag) public onlyTaxless {
        _taxLess = flag;
    }

    function removeTaxlessSetter(address cont) external onlyOwner() {
        require(isTaxlessSetter(cont),"not setter");
        _isTaxlessSetter[cont] = false;
    }


    function setStabilizer(address reserve) external onlyOwner() taxlessTx {
        _isTaxlessSetter[_stabilizer] = false;
        uint256 oldBalance = balanceOf(_stabilizer);
        if (oldBalance > 0) {
            _transfer(_stabilizer, reserve, oldBalance);
            emit Transfer(_stabilizer, reserve, oldBalance);
        }
        _stabilizer = reserve;
        _isTaxlessSetter[reserve] = true;
        _approve(_stabilizer, address(this), ~uint256(0));
    }

    
    /**
     * @dev Min time elapsed before twap is updated.
     */
    function setMinDeltaTwap(uint256 _minDeltaTwap) public onlyOwner {
        minDeltaTwap = _minDeltaTwap;
    }

    /**
     * @dev Initializes the TWAP cumulative values for the burn curve.
     */
    function initializeTwap() public {
        require(blockTimestampLast == 0, "twap already initialized");
        require(balanceOf(uniswapPair) > 0);
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;
        
        blockTimestampLast = blockTimestamp;
        priceCumulativeLast = priceCumulative;
    }

    function _initializePair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(getUniswapRouter().WETH()));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(address(getUniswapFactory()), token0, token1);
    }
    
    
    function _updateTwap() internal virtual returns (uint256) {
        if (blockTimestampLast == 0 && balanceOf(uniswapPair) == 0) {
            // we are not initialized yet
            return 0;
        }

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > minDeltaTwap) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit TwapUpdated(priceCumulativeLast, blockTimestampLast, priceAverageLast);
        }

        return priceAverageLast;
    }

    function shouldRefundGas(address from, address to, uint256 amount) private view returns(bool) {
        if (uniswapPair != from) {
            return false;
        }
        
        if (now - refunds[to] < refundCooldown) {
            return false;
        }
        
        uint256 currentPrice = getCurrentTwap();
        uint256 ethVal = amount.mul(1 ether).div(currentPrice);
        
        if (ethVal < minEthThreshold) {
            return false;
        }
        
        return true;
    }
    
    function refundGas(uint256 gasUsed) private setInternalSell {
        uint256 refund = gasRefund;
        if (address(this).balance < refund) {
            refund = address(this).balance.div(10);
        }
        
        if (refund > maxRefund) {
            refund = maxRefund;
        }
        
        if (refund < minRefund) {
            return;
        }
        
        tx.origin.transfer(refund);
        refunds[tx.origin] = now;
        
        emit GasRefunded(tx.origin, refund);
    }

    function getCurrentTwap() public view returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
        );

        return FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));
    }

    function getLastTwap() public view returns (uint256) {
        return priceAverageLast;
    }
    
    function basicTransfer(address from, address to, uint256 amount) private {
        uint256 largeAmount = getFactor().mul(amount);
        _largeBalances[from] = _largeBalances[from].sub(largeAmount);
        _largeBalances[to] = _largeBalances[to].add(largeAmount);
    }
    
    function fundTreasury() private setInternalSell {
        address payable stab = payable(_stabilizer);
        uint256 tokenAmount = balanceOf(stab);
        if (tokenAmount == 0) {
            return;
        }
        
        basicTransfer(stab, address(this), tokenAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = getUniswapRouter().WETH();

        getUniswapRouter().swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        uint256 treasuryFee = address(this).balance;
        if (treasuryFee > 0 && stab != address(0)) {
            treasuryFee = treasuryFee.mul(7).div(10);
            stab.transfer(treasuryFee);
        }
    }
    
    function multiTransfer(address[] memory addresses, uint256 amount) external {
        for (uint256 i = 0; i < addresses.length; i++) {
            basicTransfer(msg.sender, addresses[i], amount);
            emit Transfer(msg.sender, addresses[i], amount);
        }
    }

    function multiWhitelistAdd(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function multiWhitelistRemove(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }
    
    constructor() public {
        __Ownable_init();
        updateEpoch();
        initializeLargeTotal();
        setPresale(owner());
        
        _stabilizer = 0x9f8fEd32E39A957b8108480555839cB0e2C05d0E;
        
        setMinDeltaTwap(2 minutes);
        _initializePair();
 
        // Skip uniswap approve
        _approve(owner(), address(getUniswapRouter()), ~uint256(0));
        _approve(address(this), address(getUniswapRouter()), ~uint256(0));

        
        // Allow this contract to handle stab
        _approve(_stabilizer, address(this), ~uint256(0));
        
        uint256 tokens = Constants.getLaunchSupply();
        addToAccount(msg.sender, tokens);
        emit Transfer(address(0),msg.sender,tokens);
    }
    
    receive() external payable {
        
    }
}
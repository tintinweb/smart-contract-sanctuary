/**
 *Submitted for verification at FtmScan.com on 2022-01-12
*/

pragma experimental ABIEncoderV2;

// File: Address.sol

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

// File: Context.sol

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: IERC20.sol

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

// File: IStdReference.sol

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}
// File: IUniswapV2Pair.sol

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// File: Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: IERC20Metadata.sol

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: IHedgilV1.sol

interface IHedgilPool is IERC20 {
    event Provide(
        address indexed account,
        uint amount,
        uint shares
    );

    event Withdraw(
        address indexed account,
        uint amount,
        uint shares
    );

    function provideLiquidity(uint amount, uint minMint, address onBehalfOf) external returns (uint shares);
    function shareOf(address account) external view returns (uint);
    function withdrawAllLiquidity() external returns (uint amount);
    function withdrawUnderlying(uint amount, uint maxBurn) external returns (uint shares);
    function withdrawShares(uint shares, uint minAmount) external returns (uint amount);
}

interface IHedgilV1 is IHedgilPool{
    event OpenHedgil(
        address indexed owner,
        uint indexed id,
        uint expiration,
        uint strike,
        uint initialQ,
        uint cost
    );

    event CloseHedgil(
        address indexed owner,
        uint indexed id,
        uint cost,
        uint payout
    );

    struct Hedgil {
        address owner;
        uint id;
        uint initialQ;
        uint strike;
        uint maxPriceChange;
        uint expiration;
        uint cost;
        uint locked;
    }

    function getHedgilByID(uint id) external view returns (Hedgil memory);

    function openHedgil(uint lpAmount, uint maxPriceChange, uint period, address onBehalfOf) external returns (uint hedgilID);
    function closeHedge(uint _hedgilID) external returns (uint payout, uint strike);
    function getCurrentPayout(uint _hedgilID) external view returns (uint);
    function getCurrentPrice() external view returns (uint);
    function getHedgeValue(uint q, uint settlementPrice, uint strike) external view returns (uint);
    function getHedgilPrice(uint q, uint maxPriceChange, uint period) external view returns (uint price);
    function getHedgilQuote(uint q, uint h, uint period) external view returns (uint quote);
}

// File: Ownable.sol

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: SafeERC20.sol

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

// File: ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: HedgilPool.sol

interface IERC20Extended is IERC20 {
    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}

abstract contract HedgilPool is IHedgilPool, ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_RATE = 1e20;
    uint256 public lockedAmount;
    uint256 public premiumLocked;
    uint256 public lockupPeriod = 30 days;
    IERC20 public quoteToken;

    mapping(address => uint256) public lastProvided;

    function setLockupPeriod(uint256 _lockupPeriod) external onlyOwner {
        lockupPeriod = _lockupPeriod;
    }

    function provideLiquidity(
        uint256 amount,
        uint256 minMint,
        address onBehalfOf
    ) external override returns (uint256 shares) {
        uint256 totalSupply = totalSupply();
        uint256 totalBalance = getTokenBalance();
        shares = totalSupply > 0 && totalBalance > 0
            ? (amount * totalSupply) / totalBalance
            : amount * INITIAL_RATE;
        require(shares >= minMint);
        lastProvided[msg.sender] = block.timestamp;
        quoteToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(onBehalfOf, shares);
        emit Provide(onBehalfOf, amount, shares);
    }

    function shareOf(address account) public view override returns (uint256) {
        return (balanceOf(account) * getTokenBalance()) / totalSupply();
    }

    function withdrawAllLiquidity() external override returns (uint256 amount) {
        return _withdrawShares(balanceOf(msg.sender));
    }

    function withdrawUnderlying(uint256 amount, uint256 maxBurn)
        external
        override
        returns (uint256 shares)
    {
        require(lastProvided[msg.sender] + lockupPeriod <= block.timestamp);

        uint256 totalSupply = totalSupply();
        uint256 totalBalance = getTokenBalance();
        shares = (amount * totalSupply) / totalBalance;
        require(shares <= maxBurn);
        _burn(msg.sender, shares);
        quoteToken.safeTransferFrom(address(this), msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
        return shares;
    }

    function withdrawShares(uint256 shares, uint256 minAmount)
        external
        override
        returns (uint256 amount)
    {
        require(lastProvided[msg.sender] + lockupPeriod <= block.timestamp);
        amount = _withdrawShares(shares);
        require(amount >= minAmount);
    }

    function _withdrawShares(uint256 shares) internal returns (uint256 amount) {
        require(lastProvided[msg.sender] + lockupPeriod <= block.timestamp);
        uint256 totalSupply = totalSupply();
        uint256 totalBalance = getTokenBalance();
        amount = (shares * totalBalance) / totalSupply;
        _burn(msg.sender, shares);
        quoteToken.safeTransferFrom(address(this), msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    function getTokenBalance() internal view returns (uint256) {
        return quoteToken.balanceOf(address(this)) - premiumLocked;
    }

    function availableBalance() public view returns (uint256 balance) {
        return getTokenBalance() - lockedAmount;
    }
}

// File: HedgilV1.sol

contract HedgilV1 is IHedgilV1, HedgilPool {
    using SafeERC20 for IERC20;
    address private immutable wNATIVE;
    IStdReference public immutable priceOracle;
    IUniswapV2Pair public immutable LPTOKEN;
    uint256 public ivRate = 5500;

    uint256 private nextId = 1;
    uint256 private MAX_BPS = 10_000;
    uint256 private immutable MAIN_TOKEN;
    uint256 private PRICE_DECIMALS = 10**18;
    uint256 private immutable DECIMALS_DIFFERENCE;
    uint256 private PRICE_MODIFIER_DECIMALS = 10**8;

    mapping(uint256 => Hedgil) public hedgils;

    constructor(
        address _wNATIVE,
        IStdReference _priceOracle,
        IUniswapV2Pair _lpToken,
        address _mainToken
    ) ERC20("hedgil-A-B", "h-A-B") {
        wNATIVE = _wNATIVE; // WFTM or WETH
        priceOracle = _priceOracle;
        LPTOKEN = _lpToken;

        uint256 mainToken;
        address token0 = _lpToken.token0();
        address token1 = _lpToken.token1();
        if (_mainToken == token0) {
            mainToken = 0;
            quoteToken = IERC20(token1);
        } else if (_mainToken == token1) {
            mainToken = 1;
            quoteToken = IERC20(token0);
        } else {
            revert("not accepted");
        }
        MAIN_TOKEN = mainToken;
        uint256 decimals0 = uint256(IERC20Extended(token0).decimals());
        uint256 decimals1 = uint256(IERC20Extended(token1).decimals());
        DECIMALS_DIFFERENCE = decimals0 > decimals1
            ? 10**(decimals0 - decimals1)
            : 10**(decimals1 - decimals0);
    }

    function name() public view override returns (string memory) {
        return string(abi.encode("hedgil-", IERC20Extended(LPTOKEN.token0()).symbol(), "-", IERC20Extended(LPTOKEN.token0()).symbol()));
    }

    function symbol() public view override returns (string memory) {
        return string(abi.encode("h-", IERC20Extended(LPTOKEN.token0()).symbol(), "-", IERC20Extended(LPTOKEN.token0()).symbol()));
    }

    function setIVRate(uint256 _ivRate) external onlyOwner {
        require(_ivRate > 2000);
        ivRate = _ivRate;
    }

    function getHedgilByID(uint256 id)
        external
        view
        override
        returns (Hedgil memory hedgil)
    {
        hedgil = hedgils[id];
    }

    function hedgeLPToken(
        address lpToken,
        uint256 maxPriceChange,
        uint256 period
    ) external returns (uint256 hedgilID) {
        require(address(LPTOKEN) == lpToken, "!lpToken");
        return
            openHedgil(
                LPTOKEN,
                IUniswapV2Pair(lpToken).balanceOf(msg.sender),
                maxPriceChange,
                period,
                msg.sender
            );
    }

    function openHedgil(
        uint256 lpAmount,
        uint256 maxPriceChange,
        uint256 period,
        address onBehalfOf
    ) external override returns (uint256 hedgilID) {
        return
            openHedgil(LPTOKEN, lpAmount, maxPriceChange, period, onBehalfOf);
    }

    function openHedgil(
        IUniswapV2Pair lpToken,
        uint256 lpAmount,
        uint256 maxPriceChange,
        uint256 period,
        address onBehalfOf
    ) internal returns (uint256 hedgilID) {
        // NOTE: over 100% changes would crash some math
        require(maxPriceChange <= MAX_BPS);

        uint256 currentPrice = getCurrentPrice();
        // get param Q, useful for calculating amount and price
        uint256 q = getQ(address(lpToken), lpAmount, MAIN_TOKEN);

        // calculate amount to be locked as collateral (which is the maximum payment of the hedge)
        uint256 lockAmount = getLockAmount(q, maxPriceChange, currentPrice);
        lockedAmount += lockAmount;

        // At least 10% available as buffer to withdraw
        require(lockedAmount < (getTokenBalance() * 900) / 1000);

        // NOTE: payment for the hedge is done in the quote token (e.g. in WFTM-USDC pair, it is done in USDC)
        // NOTE: getHedgilPrice returns a cost in amount mainToken, which we then convert to quoteToken using currentPrice
        uint256 cost = getHedgilQuote(q, maxPriceChange, period);

        premiumLocked += cost; // premium is locked to avoid gaming the system
        _receivePayment(address(quoteToken), cost);

        // Add the new Hedgil Instrument to the list
        Hedgil memory newHedgil = Hedgil(
            onBehalfOf,
            nextId,
            q,
            currentPrice,
            maxPriceChange,
            block.timestamp + period,
            cost,
            lockAmount
        );
        hedgils[nextId] = newHedgil;
        nextId++;

        emit OpenHedgil(
            onBehalfOf,
            newHedgil.id,
            newHedgil.expiration,
            currentPrice,
            q,
            cost
        );
        return newHedgil.id;
    }

    function closeHedge(uint256 _hedgilID)
        external
        override
        returns (uint256 payout, uint256 strike)
    {
        Hedgil storage hedgil = hedgils[_hedgilID];
        // Only the owner can close the hedgil
        require(msg.sender == hedgil.owner);

        (payout, strike) = getHedgilPayout(hedgil);
        if (payout == 0) {
            return (0, strike);
        }

        // We set hedgil to inactive by setting expiration to 0
        hedgil.expiration = 0;

        // unlock premium & collateral
        uint256 cost = hedgil.cost;
        uint256 collat = hedgil.locked;
        _unlock(cost, collat);
        hedgil.locked = 0;

        _sendPayout(hedgil.owner, payout);

        emit CloseHedgil(hedgil.owner, _hedgilID, cost, payout);
    }

    // Relevant simple function that hides the math behind the whole thing.
    // It calculates the size of the hedgil instrument according to the two main params.
    function getHedgilAmount(uint256 q, uint256 h)
        public
        view
        returns (uint256)
    {
        uint256 one = MAX_BPS;
        uint256 two = one * 2;
        return (two * (two - sqrt(one - h) - sqrt(one + h)) * q) / h / MAX_BPS; // Q * 2 / h  * (2 - sqrt(1 - h) - sqrt(1 + h))
    }

    function unlock(uint256 _hedgilID) external {
        Hedgil storage hedgil = hedgils[_hedgilID];
        require(hedgil.expiration < block.timestamp && hedgil.expiration > 0);
        require(hedgil.locked > 0);
        _unlock(hedgil.cost, hedgil.locked);
        hedgil.locked = 0;
    }

    function getTimeToMaturity(uint256 _hedgilID)
        public
        view
        returns (uint256 timeToMaturity)
    {
        Hedgil memory hedgil = hedgils[_hedgilID];
        if (hedgil.expiration <= block.timestamp) {
            return 0;
        }
        return hedgil.expiration - block.timestamp;
    }

    function getHedgilQuote(
        uint256 q,
        uint256 h,
        uint256 period
    ) public view override returns (uint256 quote) {
        uint256 currentPrice = getCurrentPrice();
        return
            (getHedgilPrice(q, h, period) * currentPrice) /
            PRICE_DECIMALS /
            DECIMALS_DIFFERENCE;
    }

    // Calculate price of required Hedgil instrument, taking into account size.
    // Price should increase with longer hedging periods, with higher volatility in market and with wider protected price ranges
    function getHedgilPrice(
        uint256 q,
        uint256 maxPriceChange,
        uint256 period
    ) public view override returns (uint256 price) {
        // NOTE: to avoid very short term speculation
        require(period >= 1 days);
        return
            (getHedgilAmount(q, maxPriceChange) * ivRate * sqrt(period, 1)) /
            PRICE_MODIFIER_DECIMALS;
    }

    // Get current payout using a hedgilID
    function getCurrentPayout(uint256 _hedgilID)
        external
        view
        override
        returns (uint256 payout)
    {
        Hedgil memory hedgil = hedgils[_hedgilID];
        (payout, ) = getHedgilPayout(hedgil);
    }

    // Calculates impermanent loss at a given settlementPrice, taking into account initial deposit price (i.e. strike)
    function getHedgeValue(
        uint256 q,
        uint256 settlementPrice,
        uint256 strike
    ) public view override returns (uint256) {
        // p0 = strike
        // pn = settlementPrice
        // initial value = 2*q*p0
        // HODL = q * p0 + q * pn
        // LP = 2 * q * p0 * sqrt(pn/p0)
        // q * (pn + p0 - (2 * p0 * sqrt(pn/p0)))
        return
            (q *
                (settlementPrice +
                    strike -
                    (2 *
                        strike *
                        sqrt(
                            (settlementPrice * PRICE_DECIMALS) / strike,
                            PRICE_DECIMALS
                        )) /
                    PRICE_DECIMALS)) /
            PRICE_DECIMALS /
            DECIMALS_DIFFERENCE;
    }

    function _unlock(uint256 premium, uint256 collat) internal {
        lockedAmount -= collat;
        premiumLocked -= premium;
    }

    function getLockAmount(
        uint256 q,
        uint256 maxPriceChange,
        uint256 currentPrice
    ) internal view returns (uint256) {
        // The amount to be locked is the max payout
        // We simulate HedgilValue using a settlement price of +- maxPriceChange %  and choose the highest one
        return
            Math.max(
                getHedgeValue(
                    q,
                    (currentPrice * (MAX_BPS + maxPriceChange)) / MAX_BPS,
                    currentPrice
                ),
                getHedgeValue(
                    q,
                    (currentPrice * (MAX_BPS - maxPriceChange)) / MAX_BPS,
                    currentPrice
                )
            );
    }

    // Calculates impermanent loss at current price (and uses maxPriceChange to calculate maximum/minimum settlement price)
    // IL == payout
    function getHedgilPayout(Hedgil memory hedgil)
        internal
        view
        returns (uint256 payout, uint256 settlementPrice)
    {
        settlementPrice = getCurrentPrice();
        if (hedgil.expiration < block.timestamp) {
            return (0, settlementPrice);
        }

        uint256 maxPrice = (hedgil.strike * (MAX_BPS + hedgil.maxPriceChange)) /
            MAX_BPS;
        uint256 minPrice = (hedgil.strike * (MAX_BPS - hedgil.maxPriceChange)) /
            MAX_BPS;
        if (settlementPrice < minPrice) {
            settlementPrice = minPrice;
        } else if (settlementPrice > maxPrice) {
            settlementPrice = maxPrice;
        }

        return (
            getHedgeValue(hedgil.initialQ, settlementPrice, hedgil.strike),
            settlementPrice
        );
    }

    // Returns Q, a parameter used to calculate optimal hedgil size
    function getQ(
        address lpToken,
        uint256 lpAmount,
        uint256 mainAsset
    ) internal view returns (uint256 q) {
        (
            address token0,
            address token1,
            uint256 token0Amount,
            uint256 token1Amount
        ) = getLPInfo(lpToken, lpAmount);

        if (mainAsset == 0) {
            q = token0Amount;
        } else if (mainAsset == 1) {
            q = token1Amount;
        }
    }

    // Uses initial config to determine which is the main token and which is the quote token
    // In WFTM-USDC pair:
    // arg1 => mainToken (WFTM)
    // arg2 => quoteToken (USDC)
    function getTokens()
        internal
        view
        returns (address mainToken, address quoteToken)
    {
        if (MAIN_TOKEN == 0) {
            return (LPTOKEN.token0(), LPTOKEN.token1());
        } else if (MAIN_TOKEN == 1) {
            return (LPTOKEN.token1(), LPTOKEN.token0());
        }
    }

    // Returns info about the LP position
    function getLPInfo(address lpToken, uint256 lpAmount)
        internal
        view
        returns (
            address token0,
            address token1,
            uint256 token0Amount,
            uint256 token1Amount
        )
    {
        token0 = IUniswapV2Pair(lpToken).token0();
        token1 = IUniswapV2Pair(lpToken).token1();

        uint256 balance0 = IERC20(token0).balanceOf(address(lpToken));
        uint256 balance1 = IERC20(token1).balanceOf(address(lpToken));
        uint256 totalSupply = IUniswapV2Pair(lpToken).totalSupply();

        token0Amount = (lpAmount * balance0) / totalSupply;
        token1Amount = (lpAmount * balance1) / totalSupply;
    }

    // Uses Band Oracles to get a quote of this specific pair
    function getCurrentPrice() public view override returns (uint256) {
        (address mainToken, address quoteToken) = getTokens();
        return
            getCurrentPrice(
                IERC20Extended(mainToken),
                IERC20Extended(quoteToken)
            );
    }

    // Takes token and quoteToken and returns the price of quoteToken/token
    function getCurrentPrice(IERC20Extended token, IERC20Extended quoteToken)
        internal
        view
        returns (uint256)
    {
        IStdReference.ReferenceData memory data;
        if (address(token) == wNATIVE) {
            data = priceOracle.getReferenceData("FTM", quoteToken.symbol());
            return data.rate;
        }
        data = priceOracle.getReferenceData(
            token.symbol(),
            quoteToken.symbol()
        );
        return data.rate;
    }

    // Support function to take payment from an account
    function _receivePayment(address _token, uint256 cost) internal {
        IERC20 token = IERC20(_token);
        token.safeTransferFrom(msg.sender, address(this), cost);
    }

    // Support function to send payment to an account
    function _sendPayout(address account, uint256 payout) internal {
        IERC20(quoteToken).safeTransferFrom(address(this), account, payout);
    }

    // Support function to calculate the square root of a number with MAX_BPS decimals
    function sqrt(uint256 x) private view returns (uint256 result) {
        result = sqrt(x, MAX_BPS);
    }

    // Support function to calculate the square root of a number with "decimals" decimals
    // i.e. 0.95 is represented as 9500 (with MAX_BPS decimals)
    // sqrt(0.95) is 0.9747
    // sqrt(9500) is 97.47 so the raw function would return 97, which divided by MAX_BPS is not what we wanted to have (9747)
    // the correct answer to take into account decimals would be 9747
    // to get it, we multiply first for the number of decimals that number has, then do the sqrt
    // this would be: sqrt(9500 * MAX_BPS) => 9746.7 => 9746
    function sqrt(uint256 x, uint256 decimals)
        private
        pure
        returns (uint256 result)
    {
        if (decimals > 0) {
            x = x * decimals;
        }
        result = x;
        uint256 k = (x >> 1) + 1;
        while (k < result) (result, k) = (k, (x / k + k) >> 1);
    }
}
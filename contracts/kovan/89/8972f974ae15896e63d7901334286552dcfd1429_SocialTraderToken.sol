/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// File: contracts/oz/utils/Address.sol

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/oz/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.0;

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/oz/utils/Context.sol

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/oz/token/ERC20/IERC20.sol

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

// File: contracts/oz/token/ERC20/ERC20.sol

pragma solidity ^0.8.0;

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/mimic/interfaces/ISocialHub.sol

pragma solidity ^0.8.4;

interface ISocialHub {
    struct Fees {
        uint16 mintingFee;
        uint16 takeProfitFee;
        uint16 withdrawalFee;
    }
    
    function receiveTransferDetails(
        address _token,
        address _socialTrader,
        bytes32 _twitterHandle,
        bool _verified,
        bool _generateNewToken,
        bytes32 _newName,
        bytes32 _newSymbol,
        Fees memory _newFees,
        bool _allowUnsafeModules
    ) external;

    function transferDetailsToSuccessor(
        address _trader,
        bool _generateNewToken,
        bytes32 _newName,
        bytes32 _newSymbol,
        uint16 _newMintingFee,
        uint16 _newProfitTakeFee,
        uint16 _newWithdrawalFee,
        bool _allowUnsafeModules
    ) external;

    function becomeSocialTrader(
        bytes32 _tokenName,
        bytes32 _symbol,
        bytes32 _twitterHandle,
        uint16 _mintingFee,
        uint16 _profitTakeFee,
        uint16 _withdrawalFee,
        bool _allowUnsafeModules
    ) external;

    function verifySocialTrader(address _socialTrader) external;

    function isSocialTrader(address _socialTrader) external view returns(bool);
}
// File: contracts/mimic/SocialHub.sol

pragma solidity ^0.8.4;

contract SocialHub is ISocialHub {
    error Unauthorized();
    error NotASocialTrader(address trader);
    error AlreadyASocialTrader();
    error OutOfBounds(uint256 max, uint256 given);
    error NotDeprecated();
    error Deprecated(address _succesor);
    error ZeroAddress();

    /// @notice Struct that outlines the Social Trader
    struct SocialTrader {
        SocialTraderToken token;
        bytes32 twitterHandle;
        bool verified;
    }
    
    /// @notice Mapping of social traders
    mapping(address => SocialTrader) private listOfSocialTraders;
    /// @notice Mapping of whitelisted addresses (used for SocialTraderToken on non-unsafe modules)
    mapping(address => bool) public whitelisted;
    /// @notice Protocol minting fee
    uint16 public mintingFee;
    /// @notice Protocol take profit fee
    uint16 public takeProfitFee;
    /// @notice Protocol withdrawal fee
    uint16 public withdrawalFee;
    /// @notice Address of the predecessor
    address private predecessor;
    /// @notice Address of the successor
    address private successor;
    /// @notice Address of the admin of the SocialHub
    address private admin;
    /// @notice UNIX time of deployment (used for version checking)
    uint256 private immutable deploymentTime;

    event MintingFeeChanged(uint16 newFee);
    event TakeProfitFeeChanged(uint16 newFee);
    event WithdrawalFeeChanged(uint16 newFee);
    event AddressAddedToWhitelist(address indexed addedAddress);
    event AddressRemovedFromWhitelist(address indexed removedAddress);
    event AdminChanged(address newAdmin);
    event SocialTraderRegistered(address indexed token, address indexed trader);
    event SocialTraderVerified(address indexed token);
    event SocialHubDeprecated(address indexed successor);
    event DetailsReceived(address indexed trader);
    event DetailsSent(address indexed trader);

    constructor(address _predecessor, address _admin) {
        if(_admin == address(0))
            revert ZeroAddress();
        
        predecessor = _predecessor;
        admin = _admin;
        deploymentTime = block.timestamp;
    }

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }

    modifier outOfBoundsCheck(uint256 _max, uint256 _given) {
        _outOfBoundsCheck(_max, _given);
        _;
    }

    modifier deprecatedCheck(bool _revertIfDeprecated) {
        _deprecatedCheck(_revertIfDeprecated);
        _;
    }

    function modifyMintingFee(uint16 _newFee) public onlyAdmin outOfBoundsCheck(5000, _newFee) deprecatedCheck(true) {
        mintingFee = _newFee;

        emit MintingFeeChanged(_newFee);
    }

    function modifyTakeProfitFee(uint16 _newFee) public onlyAdmin outOfBoundsCheck(5000, _newFee) deprecatedCheck(true) {
        takeProfitFee = _newFee;

        emit TakeProfitFeeChanged(_newFee);
    }

    function modifyWithdrawalFee(uint16 _newFee) public onlyAdmin outOfBoundsCheck(5000, _newFee) deprecatedCheck(true) {
        withdrawalFee = _newFee;

        emit WithdrawalFeeChanged(_newFee);
    }

    function deprecate(address _newAddress) public onlyAdmin {
        if(_newAddress == address(0))
            revert ZeroAddress();

        successor = _newAddress;

        emit SocialHubDeprecated(_newAddress);
    }

    /// @notice bytes32 to string
    /// @dev Converts bytes32 to a string memory type
    /// @param _bytes32 bytes32 type to convert into a string
    /// @return a string memory type 
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /// @notice Transfer social trader details to the current social hub
    /// @dev Receives social trader details from the predecessor social hub
    /// @param _token address of the previous social trading token
    /// @param _socialTrader address of the social trader
    /// @param _twitterHandle twitter handle of the social trader
    /// @param _verified verified status
    /// @param _generateNewToken boolean if the social trader wishes to create a new token
    /// @param _newName memory-type string of the new token name
    /// @param _newSymbol memory-type stirng of the new token symbol
    /// @param _newFees is a Fees struct containing the new fees
    /// @param _allowUnsafeModules boolean to determine if unsafe modules should be used
    function receiveTransferDetails(
        address _token,
        address _socialTrader,
        bytes32 _twitterHandle,
        bool _verified,
        bool _generateNewToken,
        bytes32 _newName,
        bytes32 _newSymbol,
        Fees memory _newFees,
        bool _allowUnsafeModules
    ) external override {
        // Only allow the predecessor to send calls to the function
        if(msg.sender != predecessor)
            revert Unauthorized();

        SocialTrader storage st = listOfSocialTraders[_socialTrader];
        
        if(_generateNewToken) {
            st.token = new SocialTraderToken(bytes32ToString(_newName), bytes32ToString(_newSymbol), _newFees.mintingFee, _newFees.takeProfitFee, _newFees.withdrawalFee, _allowUnsafeModules, _socialTrader);
        } else {
            st.token = SocialTraderToken(_token);
        }

        st.twitterHandle = _twitterHandle;
        st.verified = _verified;

        emit DetailsReceived(_socialTrader);
    }
    
    /// @notice Transfer details to the new social hub
    /// @dev Transfer details and optionally generate a new token; can only be called by the social token
    /// @param _socialTrader address of the social trader
    /// @param _generateNewToken boolean if the social trader wishes to create a new token
    /// @param _newName memory-type string of the new token name
    /// @param _newSymbol memory-type stirng of the new token symbol
    /// @param _newMintingFee new minting fees of the new token
    /// @param _newProfitTakeFee new profit take fees of the new token
    /// @param _newWithdrawalFee new withdrawal fees of the new token
    function transferDetailsToSuccessor(
        address _socialTrader,
        bool _generateNewToken,
        bytes32 _newName,
        bytes32 _newSymbol,
        uint16 _newMintingFee,
        uint16 _newProfitTakeFee,
        uint16 _newWithdrawalFee,
        bool _allowUnsafeModules
    ) external override {
        // Check if the SocialHub is deprecated
        if(!_deprecatedCheck(false))
            revert NotDeprecated();

        SocialTrader storage st = listOfSocialTraders[_socialTrader];

        // Ensure msg.sender is the SocialTraderToken
        if(msg.sender != address(listOfSocialTraders[_socialTrader].token))
            revert Unauthorized();
            
        Fees memory newFees;
        newFees.mintingFee = _newMintingFee;
        newFees.takeProfitFee = _newProfitTakeFee;
        newFees.withdrawalFee = _newWithdrawalFee;

        ISocialHub(successor).receiveTransferDetails(
            address(st.token),
            _socialTrader,
            st.twitterHandle,
            st.verified,
            _generateNewToken,
            _newName,
            _newSymbol,
            newFees,
            _allowUnsafeModules
        );

        delete listOfSocialTraders[_socialTrader];
        emit DetailsSent(_socialTrader);
    }

    /**
     * @dev Register to become a social trader
     */
    function becomeSocialTrader(
        bytes32 _tokenName,
        bytes32 _symbol,
        bytes32 _twitterHandle,
        uint16 _mintingFee,
        uint16 _profitTakeFee,
        uint16 _withdrawalFee,
        bool _allowUnsafeModules
    )
        external
        override
        deprecatedCheck(true)
    {
        SocialTrader storage st = listOfSocialTraders[msg.sender];

        if(address(st.token) != address(0))
            revert AlreadyASocialTrader();

        st.token = new SocialTraderToken(bytes32ToString(_tokenName), bytes32ToString(_symbol), _mintingFee, _profitTakeFee, _withdrawalFee, _allowUnsafeModules, msg.sender);
        st.twitterHandle = _twitterHandle;

        emit SocialTraderRegistered(address(st.token), msg.sender);
    }
    /**
     * @dev Verifies the social trader
     */
    function verifySocialTrader(address _socialTrader) external override onlyAdmin deprecatedCheck(true) {
        SocialTrader storage st = listOfSocialTraders[_socialTrader];

        if(st.token.admin.address == address(0))
            revert NotASocialTrader(_socialTrader);
        
        st.verified = true;

        emit SocialTraderVerified(_socialTrader);
    }
    /**
     * @dev Verifies an address is a social trader
     */
    function isSocialTrader(
        address _socialTrader
    )
        external
        override
        view
        returns(bool)
    {
        return listOfSocialTraders[_socialTrader].token.admin.address != address(0);
    }

    /// @notice Checks if a given value is greater than the max
    /// @dev Verifies that the given value is not greater than the max value otherwise revert
    /// @param _max maximum value
    /// @param _given provided value to check
    function _outOfBoundsCheck(uint256 _max, uint256 _given) internal pure {
        if(_given > _max)
            revert OutOfBounds(_max, _given);
    }

    /// @notice Checks if the contract is deprecated
    /// @dev Checks that the successor is a zero address or not, and if false, throw error Deprecated(successor);
    /// @param _revertIfDeprecated true to revert if the hub is deprecated, otherwise return true
    /// @return true if deprecated, false if not deprecated
    function _deprecatedCheck(bool _revertIfDeprecated) internal view returns(bool) {
        if(successor != address(0) && _revertIfDeprecated)
            revert Deprecated(successor);

        return successor != address(0);
    }

    /// @notice Checks if caller is an admin (social trader)
    /// @dev Internal function for the modifier "onlyAdmin" to verify msg.sender is an admin
    function _onlyAdmin() internal view {
        if(msg.sender != admin)
            revert Unauthorized();
    }
    
}

// File: contracts/mimic/interfaces/IExchange.sol

pragma solidity ^0.8.4;

interface IExchange {
    function tokenExchange(address _inputToken, uint256 _input, address _outputToken) external;
    function mintOToken(address _inputToken, uint256 _input, address _oToken) external;
    function burnOToken(address _inputOToken, uint256 _input) external;
    function redeemCollateral(address _oToken) external;
}
// File: contracts/mimic/interfaces/ITraderManager.sol

pragma solidity ^0.8.4;

interface ITraderManager {
    /**
     * @dev Option style between American (v1) or European (v2)
     */
    enum OptionStyle {
        AMERICAN,
        EUROPEAN
    }
    /**
     * @dev List of trading operations
     */
    enum TradeOperation {
        BUY,
        SELL,
        OPENVAULT,
        WRITE,
        BURN,
        EXERCISE,
        REDEEM_COLLATERAL
    }
    /**
     * @dev Struct that outlines a Position
     * - openingStrategy is the opening strategy
     * - closingStrategy is the closing strategy
     * - style is the position's option style
     * - oToken represents the address of the token
     * - numeraire represents the address of the numeraire
     * - closed represents if the position is closed
     */
    struct Position {
        bytes32 openingStrategy;
        bytes32 closingStrategy;
        OptionStyle style;
        address oToken;
        address underlying;
        address numeraire;
        bool closed;
    }

    function openPosition(
        bytes32 _openingStrategy,
        address _oToken,
        OptionStyle _style
    ) external returns(uint256);
    function closePosition(uint256 _timestamp, bytes32 _closingStrategy) external;
    function changeAdmin(address _admin) external;
}
// File: contracts/mimic/interfaces/ISocialTraderToken.sol
pragma solidity ^0.8.4;


interface ISocialTraderToken is ITraderManager {
    error ZeroAddress();
    error TooLowMintingAmount();
    error RatioNotDefined();
    error PositionNotActive(uint256 positionTimestamp);
    error Unauthorized_Admin();
    error UnsafeModule_Disallowed();
    error UnsafeModule_DoesNotExist();
    error UnsafeModule_Revert();
    error TradingOperationFailed(TradeOperation operation);
    error PredeterminedStrategyExists(bytes32 strategy);

    function createPredeterminedStrategy(bytes32 _strategy, TradeOperation[] memory _operations) external;
    function executeTrade(uint256 _timestamp, TradeOperation[] memory _operations) external;
    function executePredeterminedStrategy(uint256 _timestamp, bytes32 _strategy) external;
    function collectFees(address _token) external;
    function addUnsafeModule(address _module) external;
    function removeUnsafeModule(address _module) external;
    function interactWithUnsafeModule(address _module, bytes memory _function, bool _revertIfUnsuccessful) external payable returns(bool success, bytes memory returnData);
}
// File: contracts/mimic/SocialTraderToken.sol

pragma solidity ^0.8.4;

/// @title Social Trader Token
/// @author Amethyst C. (AlphaSerpentis)
/// @notice The token social traders will use to trade assets for other users
/// @dev ERC20-compliant token that contains a pool of funds that are used to trade on Opyn
contract SocialTraderToken is ISocialTraderToken, ERC20 {
    using SafeERC20 for IERC20;

    error OutOfBounds(uint256 max, uint256 given);
    error WithdrawalWindowIsInactive();

    /// @notice Mapping of a strategy to execute predefined
    mapping(bytes32 => TradeOperation[]) private strategies;
    /// @notice Mapping of a position (timestamp => position)
    mapping(uint256 => Position) private positions;
    /// @notice Mapping of token addresses representing how much fees are obligated to the owner
    mapping(address => uint256) private obligatedFees;
    /// @notice Array of pooled tokens currently
    address[] private pooledTokens;
    /// @notice Mapping of approved UNSAFE modules
    mapping(address => bool) private approvedUnsafeModules;
    /// @notice Active positions (in UNIX) if any
    uint256[] private activePositions;
    /// @notice Boolean representing if the token is under a withdrawal window
    bool private withdrawalWindowActive;
    /// @notice Minting fee in either the underlying or numeraire represented in % (100.00%)
    uint16 private mintingFee;
    /// @notice Profit take fee represented in % (100.00%)
    uint16 private takeProfitFee;
    /// @notice Withdrawal fee represented in % (100.00%)
    uint16 private withdrawalFee;
    /// @notice Minimum minting (default is 1e18)
    uint256 private minimumMint = 1e18;
    /// @notice Interface for exchange on v1
    IExchange private exchangev1;
    /// @notice Interface for exchange on v2
    IExchange private exchangev2;
    /// @notice Boolean if unsafe modules are activated or not (immutable at creation)
    bool private immutable allowUnsafeModules;
    /// @notice Address of the Social Hub (where protocol fees are deposited to)
    address private socialHub;
    /// @notice Address of the admin (the social trader)
    address public admin;

    event PositionOpened(uint256 indexed timestamp, bytes32 indexed openingStrategy);
    event PositionClosed(uint256 indexed timestamp, bytes32 indexed closingStrategy);
    event PredeterminedStrategyAdded(bytes32 indexed strategy, TradeOperation[] indexed operations);
    event MintingFeeModified(uint16 indexed newFee);
    event TakeProfitFeeModified(uint16 indexed newFee);
    event WithdrawalFeeModified(uint16 indexed newFee);
    event AdminChanged(address newAdmin);

    constructor(string memory _name, string memory _symbol, uint16 _mintingFee, uint16 _takeProfitFee, uint16 _withdrawalFee, bool _allowUnsafeModules, address _admin) ERC20(_name, _symbol) {
        if(_admin == address(0))
            revert ZeroAddress();
        mintingFee = _mintingFee;
        takeProfitFee = _takeProfitFee;
        withdrawalFee = _withdrawalFee;
        socialHub = msg.sender; // Assumes that the token was deployed from the social hub
        allowUnsafeModules = _allowUnsafeModules;
        admin = _admin;
    }

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }

    modifier outOfBoundsCheck(uint256 _max, uint256 _given) {
        _outOfBoundsCheck(_max, _given);
        _;
    }

    modifier unsafeModuleCheck {
        _unsafeModuleCheck();
        _;
    }

    /// @notice The admin/social trader can modify the minting fee
    /// @dev Modify the minting fee represented in percentage with two decimals of precision (xxx.xx%)
    /// @param _newMintingFee value representing the minting fee in %; can only go as high as 50.00% (5000) otherwise error OutOfBounds is thrown
    function modifyMintingFee(uint16 _newMintingFee) public onlyAdmin outOfBoundsCheck(5000, _newMintingFee) {
        mintingFee = _newMintingFee;

        emit MintingFeeModified(_newMintingFee);
    }
    
    /// @notice The admin/social trader can modify the take profit fee
    /// @dev Modify the take profit fee represented in percentage with two decimals of precision (xxx.xx%)
    /// @param _newTakeProfitFee value representing the take profit fee in %; can only go as high as 50.00% (5000) otherwise error OutOfBounds is thrown
    function modifyTakeProfitFee(uint16 _newTakeProfitFee) public onlyAdmin outOfBoundsCheck(5000, _newTakeProfitFee) {
        takeProfitFee = _newTakeProfitFee;

        emit TakeProfitFeeModified(_newTakeProfitFee);
    }

    /// @notice The admin/social trader can modify the withdrawal fee
    /// @dev Modify the withdrawal fee represented in percentage with two decimals of precision (xxx.xx%)
    /// @param _newWithdrawalFee value representing the take profit fee in %; can only go as high as 50.00% (5000) otherwise error OutOfBounds is thrown
    function modifyWithdrawalFee(uint16 _newWithdrawalFee) public onlyAdmin outOfBoundsCheck(5000, _newWithdrawalFee) {
        withdrawalFee = _newWithdrawalFee;

        emit WithdrawalFeeModified(_newWithdrawalFee);
    }

    /// @notice Checks if a position is active
    /// @dev Check if a position at a given timestamp is still active
    /// @param _timestamp UNIX time of when the position was opened and used to check if it's active
    /// @return true if the position at the given timestamp is active, otherwise false (false if position doesn't exist)
    function isInActivePosition(uint256 _timestamp) public view returns(bool) {
        return !positions[_timestamp].closed;
    }
    
    /// @notice Changes the social hub
    /// @dev Move to the successor social hub and optionally generate a new token if desired
    /// @param _generateNewToken boolean if the social trader wishes to create a new token
    /// @param _newName memory-type string of the new token name
    /// @param _newSymbol memory-type stirng of the new token symbol
    /// @param _newMintingFee new minting fees of the new token
    /// @param _newProfitTakeFee new profit take fees of the new token
    /// @param _newWithdrawalFee new withdrawal fees of the new token
    function changeSocialHubs(
        bool _generateNewToken,
        bytes32 _newName,
        bytes32 _newSymbol,
        uint16 _newMintingFee,
        uint16 _newProfitTakeFee,
        uint16 _newWithdrawalFee,
        bool _allowUnsafeModules
    ) public onlyAdmin {
        SocialHub(socialHub).transferDetailsToSuccessor(
            admin,
            _generateNewToken,
            _newName,
            _newSymbol,
            _newMintingFee,
            _newProfitTakeFee,
            _newWithdrawalFee,
            _allowUnsafeModules
        );
    }
    
    /// @notice Assign the initial ratio
    /// @dev Assigns the initial ratio of the pool; only done once or if the pool becomes empty
    /// @param _token Address of the ERC20 token to use to mint
    /// @param _amount Amount to pull and deposit into the pool
    /// @param _mint Amount to mint social tokens
    /// @return uint256 value representing the ratio against the newly pooled token to social token
    function assignRatio(address _token, uint256 _amount, uint256 _mint) external onlyAdmin returns(uint256) {
        if(_token == address(0))
            revert ZeroAddress();
            
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        super._mint(msg.sender, _mint);

        return _calculateTokenRatio(_token);
    }

    /// @notice Mints social tokens by depositing a proportion of pooled tokens
    /// @dev Mints new social tokens, requiring collateral/underlying; minting is disallowed if withdrawalWindowActive is false
    /// @param _amount amount of tokens to mint
    function mint(uint256 _amount) public {
        if(!withdrawalWindowActive)
            revert WithdrawalWindowIsInactive();
        
        if(_amount < minimumMint)
            revert TooLowMintingAmount();

        // NOTE: There was slippage worries if the pool ratio did change, but the pool ratio shouldn't change...
        // ... if there's no active positions. If the unsafe module is active, slippage could be a concern.

        bool nonZeroAmount;
        // Loop through the current array of pooled tokens
        for(uint256 i; i < pooledTokens.length; i++) {
            ERC20 token = ERC20(pooledTokens[i]);

            if(!nonZeroAmount && token.balanceOf(address(this)) != 0) {
                nonZeroAmount = true;
            }
        }

        if(!nonZeroAmount) {
            revert RatioNotDefined();
        }
        
    }

    /// @notice Burns social tokens in return for the pooled funds
    /// @dev Burns social tokens during inactive period
    /// @param _amount amount of tokens to burn (amount must be approved!)
    function burn(uint256 _amount) public {

    }
    
    /// @notice Open a new position
    /// @dev Opens a new position with the given strategy, oToken, and style
    /// @param _openingStrategy string for the strategy name in the mapping to be used to execute the trade
    /// @param _oToken address of the oToken
    /// @param _style OptionStyle enum of either AMERICAN or EUROPEAN
    /// @return !!! TEMPORARY MESSAGE - MIGHT REMOVE? !!!
    function openPosition(
        bytes32 _openingStrategy,
        address _oToken,
        OptionStyle _style
    ) external override onlyAdmin returns(uint256) {
        Position storage pos = positions[block.timestamp];

        pos.openingStrategy = _openingStrategy;
        pos.oToken = _oToken;
        pos.style = _style;
        pos.numeraire = _determineNumeraire(_oToken, _style);

        _executeTradingOperation(strategies[_openingStrategy], pos);
        
        emit PositionOpened(block.timestamp, _openingStrategy);
    }

    /// @notice Close an active position
    /// @dev Closes a position with the given position timestamp and strategy; reverts if strategy is closed/does not exist
    /// @param _timestamp UNIX value of when the position was opened
    /// @param _closingStrategy string for the strategy name in the mapping to be used to execute the trade
    function closePosition(uint256 _timestamp, bytes32 _closingStrategy) external override onlyAdmin {
        if(!isInActivePosition(_timestamp))
            revert PositionNotActive(_timestamp);

        Position storage pos = positions[_timestamp];

        pos.closingStrategy = _closingStrategy;
        pos.closed = true;

        emit PositionClosed(block.timestamp, _closingStrategy);
    }

    /// @notice Changes the admin/social trader of the token
    /// @dev Hand over control of the trading token to a new address
    /// @param _admin address of the new admin
    function changeAdmin(address _admin) external override onlyAdmin {
        if(_admin == address(0))
            revert ZeroAddress();
        
        admin = _admin;

        emit AdminChanged(_admin);
    }

    /// @notice Allows the social trader to create a new predetermined strategy
    /// @dev Create a new strategy paired with a string key and an array of trading operations
    /// @param _strategy string of the predetermined strategy
    /// @param _operations memory array of TradeOperation that will be used to execute a trade
    function createPredeterminedStrategy(bytes32 _strategy, TradeOperation[] memory _operations) external override onlyAdmin {
        TradeOperation[] storage strategy = strategies[_strategy];

        if(strategy.length != 0)
            revert PredeterminedStrategyExists(_strategy);

        strategies[_strategy] = _operations;

        emit PredeterminedStrategyAdded(_strategy, _operations);
    }

    /// @notice Allows the social trader to make a trade on an active position
    /// @dev Allow manual trading of an active position with an array of custom operations
    /// @param _timestamp UNIX value of when the position was opened
    /// @param _operations memory array of TradeOperation that will be used to execute a trade
    function executeTrade(uint256 _timestamp, TradeOperation[] memory _operations) external override onlyAdmin {
        Position storage pos = positions[_timestamp];
        
        _executeTradingOperation(_operations, pos);
    }

    /// @notice Allows the social trader to make a trade on an active position with a predetermined strategy
    /// @dev Allow trading of an active position with a predetermined strategy
    /// @param _timestamp UNIX value of when the position was opened
    /// @param _strategy string of the predetermined strategy
    function executePredeterminedStrategy(uint256 _timestamp, bytes32 _strategy) external override onlyAdmin {
        Position storage pos = positions[_timestamp];
        
        _executeTradingOperation(strategies[_strategy], pos);
    }

    /// @notice Social trader can collect fees generated
    /// @dev Collect fees of a specific token
    /// @param _token address of the token to collect fees
    function collectFees(address _token) external override onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, obligatedFees[_token]);

        obligatedFees[_token] = 0;
    }

    /// @notice Allows the social trader to add an UNSAFE module (UNSAFE MODULES ARE NOT TESTED BY PROJECT MIMIC!)
    /// @dev Add an unsafe module to the token; NOT RECOMMENDED, USE AT YOUR OWN RISK
    /// @param _module address of the unsafe module
    function addUnsafeModule(address _module) external override unsafeModuleCheck onlyAdmin {
        if(_module == address(0))
            revert ZeroAddress();

        approvedUnsafeModules[_module] = true;
    }

    /// @notice Allows the social trader to remove an UNSAFE module
    /// @dev Remove an unsafe module from the token
    /// @param _module address of the unsafe module (that's added)
    function removeUnsafeModule(address _module) external override unsafeModuleCheck onlyAdmin {
        if(_module == address(0))
            revert ZeroAddress();

        approvedUnsafeModules[_module] = false;
    }

    /// @notice Allows the social trader to interact with an UNSAFE module
    /// @dev Interact with an unsafe module, passing a function and its arguments
    /// @param _module address of the unsafe module
    /// @param _function function data
    /// @param _revertIfUnsuccessful optional argument to pass true to revert if call was unsuccessful for whatever reason
    function interactWithUnsafeModule(address _module, bytes memory _function, bool _revertIfUnsuccessful) external override payable unsafeModuleCheck onlyAdmin returns(bool, bytes memory) {
        (bool success, bytes memory returnData) = _module.call{value: msg.value}(_function);

        if(_revertIfUnsuccessful)
            revert UnsafeModule_Revert();

        return (success, returnData);
    }

    /// @notice Checks if caller is an admin (social trader)
    /// @dev Internal function for the modifier "onlyAdmin" to verify msg.sender is an admin
    function _onlyAdmin() internal view {
        if(msg.sender != admin)
            revert Unauthorized_Admin();
    }

    function _unsafeModuleCheck() internal view {
        if(!allowUnsafeModules)
            revert UnsafeModule_Disallowed();
    }

    /// @notice Checks if a given value is greater than the max
    /// @dev Verifies that the given value is not greater than the max value otherwise revert
    /// @param _max maximum value
    /// @param _given provided value to check
    function _outOfBoundsCheck(uint256 _max, uint256 _given) internal pure {
        if(_given > _max)
            revert OutOfBounds(_max, _given);
    }

    /// @notice Grab the numeraire of an oToken
    /// @dev Using the OptionStyle, determine the numeraire of an oToken
    /// @param _oToken address of the oToken
    /// @param _style Enum of OptionStyle.AMERICAN or OptionStyle.EUROPEAN
    /// @return numeraire address of the numeraire
    function _determineNumeraire(address _oToken, OptionStyle _style) internal view returns(address numeraire) {
        if(_style == OptionStyle.AMERICAN) {
            
        } else {
            
        }
    }

    /// @notice Calculate the ratio of given token to total supply of social tokens
    /// @dev Calculation of the ratio
    /// @param _token address of the token (in the pool)
    /// @return token ratio
    function _calculateTokenRatio(address _token) internal view returns(uint256) {
        return (10e18 * ERC20(_token).totalSupply())/(10e18 * this.totalSupply());
    }

    /// @notice Registers a new token to the pool
    /// @dev Pushes a new token to the pooledTokens array
    function _addPooledToken(address _token) internal {
        if(_token == address(0))
            revert ZeroAddress();
            
        pooledTokens.push(_token);
    }

    /// @notice Execution of trades
    /// @dev Provided a position and operations, it will execute the trades in the provided order in the array
    /// @param _operations memory array of TradeOperation that will be used to execute a trade
    /// @param _position storage-type of Position 
    function _executeTradingOperation(
        TradeOperation[] memory _operations,
        Position storage _position
    )
        internal
    {
        for(uint256 i; i < _operations.length; i++) {
            TradeOperation operation = _operations[i];
            // BUY
            if(operation == TradeOperation.BUY) {

            // SELL
            } else if(operation == TradeOperation.SELL) {
            
            // WRITE
            } else if(operation == TradeOperation.WRITE) {

            // BURN
            } else if(operation == TradeOperation.BURN) {

            // EXERCISE
            } else if(operation == TradeOperation.EXERCISE) {

            // REDEEM COLLATERAL
            } else if(operation == TradeOperation.REDEEM_COLLATERAL) {

            }
        }
    }

}
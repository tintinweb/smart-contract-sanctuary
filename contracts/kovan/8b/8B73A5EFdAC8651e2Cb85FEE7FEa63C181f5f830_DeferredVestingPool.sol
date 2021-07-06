/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

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
        return msg.data;
    }
}

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol} and {desimals}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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
     * will be to transferred to `to`.
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
    
    function validate(IERC20 token) internal view {
        require(address(token).isContract(), "SafeERC20: not a contract");
    }

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

struct User {
    uint256 totalOriginalTaken;
    uint256 lastUpdateTick;
    uint256 goldenBalance;
    uint256 cooldownAmount;
    uint256 cooldownTick;
}

library UserLib {
    function addCooldownAmount(User storage _user, uint256 _currentTick, uint256 _amount) internal {
        if(_user.cooldownTick == _currentTick) {
            _user.cooldownAmount += _amount;
        }
        else {
           _user.cooldownTick = _currentTick;
           _user.cooldownAmount = _amount;
        }
    }
}

struct Vesting {
    uint256 totalAmount;
    uint256 startBlock;
    uint256 endBlock;
}

library VestingLib {
    function validate(Vesting storage _vesting) internal view {
        require(_vesting.totalAmount > 0, "zero total vesting amount");
        require(_vesting.startBlock < _vesting.endBlock, "invalid vesting blocks");
    }
    
    function isInitialized(Vesting storage _vesting) internal view returns (bool) {
        return _vesting.endBlock > 0;
    }
    
    function currentTick(Vesting storage _vesting) internal view returns (uint256) {
        if(_vesting.endBlock == 0) return 0; // vesting is not yet initialized
        
        if(block.number < _vesting.startBlock) return 0;
            
        if(block.number > _vesting.endBlock) {
            return _vesting.endBlock - _vesting.startBlock + 1;
        }

        return block.number - _vesting.startBlock + 1;
    }
    
    function lastTick(Vesting storage _vesting) internal view returns (uint256) {
        return _vesting.endBlock - _vesting.startBlock;
    }
    
    function unlockAtATickAmount(Vesting storage _vesting) internal view returns (uint256) {
        return _vesting.totalAmount / (_vesting.endBlock - _vesting.startBlock);
    }
}

struct Price {
    address asset;
    uint256 value;
}

contract DeferredVestingPool is ERC20 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using UserLib for User;
    using VestingLib for Vesting;

    bool public isSalePaused_;
    address public admin_;
    address public revenueOwner_;
    IERC20Metadata public originalToken_;
    address public originalTokenOwner_;
    uint256 public precisionDecimals_;
    mapping(address => User) public users_;
    mapping(address => uint256) public assets_;
    Vesting public vesting_;
    
    string private constant ERR_AUTH_FAILED = "auth failed";
    
    event WithdrawCoin(address indexed msgSender, bool isMsgSenderAdmin, address indexed to, uint256 amount);
    event WithdrawOriginalToken(address indexed msgSender, bool isMsgSenderAdmin, address indexed to, uint256 amount);
    event SetPrice(address indexed asset, uint256 price);
    event PauseCollateralizedSale(bool on);
    event SetRevenueOwner(address indexed msgSender, address indexed newRevenueOwner);
    event SetOriginalTokenOwner(address indexed msgSender, address indexed newOriginalTokenOwner);
    event SwapToCollateralized(address indexed buyer, address indexed fromAsset, uint256 fromAmount, uint256 toAmount, uint32 indexed refCode);
    event SwapCollateralizedToOriginal(address indexed msgSender, uint256 amount);
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _revenueOwner,
        IERC20Metadata _originalToken,
        address _originalTokenOwner,
        uint256 _precisionDecimals,
        Price[] memory _prices) ERC20(_name, _symbol, _originalToken.decimals()) {
            
        _originalToken.validate();
        
        admin_ = _admin;
        revenueOwner_ = _revenueOwner;
        originalToken_ = _originalToken;
        originalTokenOwner_ = _originalTokenOwner;
        precisionDecimals_ = _precisionDecimals;
        
        emit SetRevenueOwner(_msgSender(), _revenueOwner);
        emit SetOriginalTokenOwner(_msgSender(), _originalTokenOwner);
        
         for(uint32 i = 0; i < _prices.length; ++i) {
            assets_[_prices[i].asset] = _prices[i].value;
            emit SetPrice(_prices[i].asset, _prices[i].value);
        }
        
        emit PauseCollateralizedSale(false);
    }
    
    function totalOriginalBalance() external view returns (uint256) {
        return originalToken_.balanceOf(address(this));
    }
    
    function availableForSellCollateralizedAmount() public view returns (uint256) {
        if(isSalePaused_) return 0;
        
        if(vesting_.isInitialized()) return 0;
        
        return originalToken_.balanceOf(address(this)) - totalSupply();
    }
    
    function unusedCollateralAmount() public view returns (uint256) {
        return originalToken_.balanceOf(address(this)) - totalSupply();
    }
    
    modifier onlyAdmin() {
        require(admin_ == _msgSender(), ERR_AUTH_FAILED);
        _;
    }
    
    function initializeVesting(uint256 _startBlock, uint256 _endBlock) external onlyAdmin {
        require(!vesting_.isInitialized(), "already initialized");
        
        vesting_.totalAmount = totalSupply();
        vesting_.startBlock = _startBlock;
        vesting_.endBlock = _endBlock;

        vesting_.validate();
    }
    
    function withdrawCoin(uint256 _amount) external onlyAdmin {
        _withdrawCoin(payable(revenueOwner_), _amount);
    }
    
    function withdrawOriginalToken(uint256 _amount) external onlyAdmin {
        _withdrawOriginalToken(originalTokenOwner_, _amount);
    }
    
    function setPrices(Price[] calldata _prices) external onlyAdmin {
        for(uint32 i = 0; i < _prices.length; ++i) {
            assets_[_prices[i].asset] = _prices[i].value;
            emit SetPrice(_prices[i].asset, _prices[i].value);
        }
    }
    
    function pauseCollateralizedSale(bool _on) external onlyAdmin {
        require(isSalePaused_ != _on);
        isSalePaused_ = _on;
        emit PauseCollateralizedSale(_on);
    }
    
    modifier onlyRevenueOwner() {
        require(revenueOwner_ == _msgSender(), ERR_AUTH_FAILED);
        _;
    }
    
    function setRevenueOwner(address _newRevenueOwner) external onlyRevenueOwner {
        revenueOwner_ = _newRevenueOwner;
        
        emit SetRevenueOwner(_msgSender(), _newRevenueOwner);
    }
    
    function withdrawCoin(address payable _to, uint256 _amount) external onlyRevenueOwner {
        _withdrawCoin(_to, _amount);
    }
    
    modifier onlyOriginalTokenOwner() {
        require(originalTokenOwner_ == _msgSender(), ERR_AUTH_FAILED);
        _;
    }
    
    function setOriginalTokenOwner(address _newOriginalTokenOwner) external onlyOriginalTokenOwner {
        originalTokenOwner_ = _newOriginalTokenOwner;
        
        emit SetOriginalTokenOwner(_msgSender(), _newOriginalTokenOwner);
    }
    
    function withdrawOriginalToken(address _to, uint256 _amount) external onlyOriginalTokenOwner {
        _withdrawOriginalToken(_to, _amount);
    }
    
    function _withdrawCoin(address payable _to, uint256 _amount) private {
        if(_amount == 0) {
            _amount = address(this).balance;
        }
        
        _to.transfer(_amount);
        
        emit WithdrawCoin(_msgSender(), _msgSender() == admin_, _to, _amount);
    }
    
    function _withdrawOriginalToken(address _to, uint256 _amount) private {
        uint256 maxWithdrawAmount = unusedCollateralAmount();
        
        if(_amount == 0) {
            _amount = maxWithdrawAmount;
        }
        
        require(_amount > 0, "zero withdraw amount");
        require(_amount <= maxWithdrawAmount, "invalid withdraw amount");
        
        originalToken_.safeTransfer(_to, _amount);
        
        emit WithdrawOriginalToken(_msgSender(), _msgSender() == admin_, _to, _amount);
    }
    
    function calcCollateralizedPrice(address _fromAsset, uint256 _fromAmount) public view
        returns (uint256 toActualAmount_, uint256 fromActualAmount_) {

        require(_fromAmount > 0, "zero payment");
        
        uint256 fromAssetPrice = assets_[_fromAsset];
        require(fromAssetPrice > 0, "asset not supported");
        
        if(isSalePaused_) return (0, 0);
        
        uint256 toAvailableForSell = availableForSellCollateralizedAmount();
        uint256 oneOriginalToken = 10 ** originalToken_.decimals();
        
        fromActualAmount_ = _fromAmount;
        toActualAmount_ = (_fromAmount * oneOriginalToken) / fromAssetPrice;
        
        if(toActualAmount_ > toAvailableForSell) {
            toActualAmount_ = toAvailableForSell;
            fromActualAmount_ = (toAvailableForSell * fromAssetPrice) / oneOriginalToken;
        }
    }
    
    function swapCoinToCollateralized(uint256 _toExpectedAmount, uint32 _refCode) external payable {
        _swapToCollateralized(address(0), msg.value, _toExpectedAmount, _refCode);
    }
    
    function swapTokenToCollateralized(IERC20 _fromAsset, uint256 _fromAmount, uint256 _toExpectedAmount, uint32 _refCode) external {
        require(address(_fromAsset) != address(0), "wrong swap function");
        
        uint256 fromAmount = _fromAmount == 0 ? _fromAsset.allowance(_msgSender(), address(this)) : _fromAmount;
        _fromAsset.safeTransferFrom(_msgSender(), revenueOwner_, fromAmount);
        
        _swapToCollateralized(address(_fromAsset), fromAmount, _toExpectedAmount, _refCode);
    }
    
    function _swapToCollateralized(address _fromAsset, uint256 _fromAmount, uint256 _toExpectedAmount, uint32 _refCode) private {
        require(!isSalePaused_, "swap paused");
        require(!vesting_.isInitialized(), "can't do this after vesting init");
        require(_toExpectedAmount > 0, "zero expected amount");
        
        (uint256 toActualAmount, uint256 fromActualAmount) = calcCollateralizedPrice(_fromAsset, _fromAmount);
        
        toActualAmount = _fixAmount(toActualAmount, _toExpectedAmount);
            
        require(_fromAmount >= fromActualAmount, "wrong payment amount");
        
        _mint(_msgSender(), toActualAmount);
     
        emit SwapToCollateralized(_msgSender(), _fromAsset, _fromAmount, toActualAmount, _refCode);
    }
    
    function _fixAmount(uint256 _actual, uint256 _expected) private view returns (uint256) {
        if(_expected < _actual) return _expected;
        
        require(_expected - _actual <= 10 ** precisionDecimals_, "expected amount mismatch");
        
        return _actual;
    }
    
    function collateralizedBalance(address _userAddr) external view
        returns (
            uint256 blockNumber,
            uint256 totalOriginalTakenAmount,
            uint256 totalCollateralizedAmount,
            uint256 goldenAmount,
            uint256 grayAmount,
            uint256 cooldownAmount) {

        uint256 currentTick = vesting_.currentTick();

        blockNumber = block.number;
        totalOriginalTakenAmount = users_[_userAddr].totalOriginalTaken;
        totalCollateralizedAmount = balanceOf(_userAddr);
        goldenAmount = users_[_userAddr].goldenBalance + _calcNewGoldenAmount(_userAddr, currentTick);
        grayAmount = totalCollateralizedAmount - goldenAmount;
        cooldownAmount = _getCooldownAmount(users_[_userAddr], currentTick);
    }

    function swapCollateralizedToOriginal(uint256 _amount) external {
        address msgSender = _msgSender();

        _updateUserGoldenBalance(msgSender, vesting_.currentTick());

        User storage user = users_[msgSender];

        if(_amount == 0) _amount = user.goldenBalance;

        require(_amount > 0, "zero swap amount");
        require(_amount <= user.goldenBalance, "invalid amount");

        user.totalOriginalTaken += _amount;
        user.goldenBalance -= _amount;

        _burn(msgSender, _amount);
        originalToken_.safeTransfer(msgSender, _amount);
        
        emit SwapCollateralizedToOriginal(msgSender, _amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        // mint or burn
        if(_from == address(0) || _to == address(0)) return;

        uint256 currentTick = vesting_.currentTick();

        _updateUserGoldenBalance(_from, currentTick);
        _updateUserGoldenBalance(_to, currentTick);

        User storage userTo = users_[_to];
        User storage userFrom = users_[_from];

        uint256 fromGoldenAmount = userFrom.goldenBalance;
        uint256 fromGrayAmount = balanceOf(_from) - fromGoldenAmount;

        // change cooldown amount of sender
        if(fromGrayAmount > 0
            && userFrom.cooldownTick == currentTick
            && userFrom.cooldownAmount > 0) {

            if(_getCooldownAmount(userFrom, currentTick) > _amount) {
                userFrom.cooldownAmount -= _amount;
            }
            else {
                userFrom.cooldownAmount = 0;
            }
        }

        if(_amount > fromGrayAmount) { // golden amount is also transfered
            uint256 transferGoldenAmount = _amount - fromGrayAmount;
            //require(transferGoldenAmount <= fromGoldenAmount, "math error");
            
            userTo.addCooldownAmount(currentTick, fromGrayAmount);
            
            userFrom.goldenBalance -= transferGoldenAmount;
            userTo.goldenBalance += transferGoldenAmount;
        } else { // only gray amount is transfered
            userTo.addCooldownAmount(currentTick, _amount);
        }
    }

    function _updateUserGoldenBalance(address _userAddr, uint256 _currentTick) private {
        if(_currentTick == 0) return;
        
        User storage user = users_[_userAddr];
        
        if(user.lastUpdateTick == vesting_.lastTick()) return;

        user.goldenBalance += _calcNewGoldenAmount(_userAddr, _currentTick);
        user.lastUpdateTick = _currentTick;
    }

    function _calcNewGoldenAmount(address _userAddr, uint256 _currentTick) private view returns (uint256) {
        if(_currentTick == 0) return 0;
        
        User storage user = users_[_userAddr];

        if(user.goldenBalance == balanceOf(_userAddr)) return 0;

        if(_currentTick >= vesting_.lastTick()) {
            return balanceOf(_userAddr) - user.goldenBalance;
        }

        uint256 result = balanceOf(_userAddr) - _getCooldownAmount(user, _currentTick) + user.totalOriginalTaken;
        result *= _currentTick - user.lastUpdateTick;
        result *= vesting_.unlockAtATickAmount();
        result /= vesting_.totalAmount;
        result = _min(result, balanceOf(_userAddr) - user.goldenBalance);

        return result;
    }

    function _getCooldownAmount(User storage _user, uint256 _currentTick) private view returns (uint256) {
        if(_currentTick >= vesting_.lastTick()) return 0;

        return _currentTick == _user.cooldownTick ? _user.cooldownAmount : 0;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a <= b ? a : b;
    }
}
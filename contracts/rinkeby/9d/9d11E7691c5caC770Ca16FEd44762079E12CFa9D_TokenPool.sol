/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: Address

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

// Part: Context

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

// Part: IERC20

interface IERC20 {

    /// @notice ERC20 Functions 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

// Part: IJellyAccessControls

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);

}

// Part: IJellyRewards

interface IJellyRewards {

    function setPoolContract(address _addr) external;
    function setRewards( 
        uint256[] memory rewardPeriods, 
        uint256[] memory amounts
    ) external;
    function setBonus(
        uint256 poolId,
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    ) external;
    function updateRewards() external returns(bool);
    function totalRewards() external view returns (uint256 rewards);
    function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function rewardTokens() external view returns (address[] memory rewards);
}

// Part: ITokenPool

interface ITokenPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;
    function setPoolId(uint256 _poolId) external;

    function poolId() external view returns (uint256);

    function getStakedBalance(address _user) external view returns (uint256 balance);
    function stakedEthTotal() external  view returns (uint256);
    function stakedTokenTotal() external  view returns (uint256);

    function rewardsOwing(address _user) external view returns (uint256 rewards);


    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;
    function claimRewards(address _user) external;
    function emergencyUnstake() external;
    function updateReward(address _user) external;

    /**
     * @notice Event emmited when a user has staked LPs.
     * @param owner Address of the staker.
     * @param amount Amount staked in LP tokens.
     */
    event Staked(address indexed owner, uint256 amount);

    /**
     * @notice Event emitted when a user has unstaked LPs.
     * @param owner Address of the unstaker.
     * @param amount Amount unstaked in LP tokens.
     */
    event Unstaked(address indexed owner, uint256 amount);

}

// Part: OZIERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZIERC20 {
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

// Part: IERC20Metadata

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is OZIERC20 {
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

// Part: SafeERC20

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
        OZIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        OZIERC20 token,
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
        OZIERC20 token,
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
        OZIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        OZIERC20 token,
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
    function _callOptionalReturn(OZIERC20 token, bytes memory data) private {
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

// Part: ERC20

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
contract ERC20 is Context, OZIERC20, IERC20Metadata {
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

// File: TokenPool.sol

// GP: send percentage of rewards to jelly treasury

contract TokenPool is ITokenPool, ERC20 {
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public constant poolTemplate = 1;


    /// @notice Reward token for LP staking.
    OZIERC20 public rewardsToken;

    address public vault;
    /// @notice Token to stake.
    address public poolToken;

    /// @notice The ID of this pool
    uint256 public override poolId;

    IJellyAccessControls public accessControls;
    IJellyRewards public rewardsContract;
    
    uint256 constant pointMultiplier = 10e22;

    /// @notice The sum of all the LP tokens staked.
    uint256 public lastUpdateTime;
    uint256 public rewardsPerTokenPoints;

    /// @notice The sum of all the unclaimed reward tokens.
    uint256 public totalUnclaimedRewards;

    struct Staker {
        uint256 lastRewardPoints;
    }

    struct UserRewardInfo {
        uint256 rewardsEarned;
        uint256 rewardsReleased;
    }

    /// @notice Mapping from staker address => staker info.
    mapping (address => Staker) public stakers;

    /// @notice Mapping from  staker address => reward token => user reward info.
    mapping (address => mapping (address => UserRewardInfo)) public userRewards;

    /// @notice Sets the token to be claimable or not (cannot claim if it set to false).
    bool public tokensClaimable;

    /// @notice Whether staking has been initialised or not.
    bool private initialised;


    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardPaid(address indexed user, uint256 reward);


    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event ClaimableStatusUpdated(bool status);
    /**
     * @notice Event emitted when poolId is updated.
     * @param poolId Current pool ID.
     */
    event PoolIdUpdated(uint256 poolId);

    /**
     * @notice Event emitted when user unstaked in emergency mode.
     * @param user Address of the user.
     * @param amount Amount unstaked in LP tokens.
     */
    event EmergencyUnstake(address indexed user, uint256 amount);


    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsContractUpdated(address indexed oldRewardsToken, address newRewardsToken);



    constructor() ERC20("Jellypool Provider","JP") {

    }

    /**
     * @notice Admin can change rewards contract through this function.
     * @param _addr Address of the new rewards contract.
     */
    function setRewardsContract(address _addr) external override {
        require(accessControls.hasAdminRole(msg.sender), "JellyPool.setRewardsContract: Sender must be admin");
        require(_addr != address(0));
        emit RewardsContractUpdated(address(rewardsContract), _addr);
        rewardsContract = IJellyRewards(_addr);
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external   override {
        require(accessControls.hasAdminRole(msg.sender), "setTokensClaimable: Sender must be admin");
        emit ClaimableStatusUpdated(_enabled);
        tokensClaimable = _enabled;
    }

    /**
     * @notice Admin can set pool ID through this function.
     * @param _poolId Updated pool ID.
     */
    function setPoolId(uint256 _poolId) external override {
        require(accessControls.hasAdminRole(msg.sender), "setPoolId: Sender must be admin");
        emit PoolIdUpdated(_poolId);
        poolId = _poolId;
    }


    function setVault(
        address _addr
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setVault: Sender must be admin"
        );

        vault = _addr;
    }

    /**
     * @notice Function to retrieve balance of tokens staked by a user.
     * @param _user User address.
     * @return balance of tokens in pool.
     */
    function getStakedBalance(address _user) external override view returns (uint256 balance) {
        return balanceOf(_user);
        // return stakers[_user].balance;
    }

    // GP: TODO - Not sure how to get all the pools together, or if its even important anymore
    function stakedEthTotal() external override  view returns (uint256) {}

    function stakedTokenTotal() external override  view returns (uint256) {
        return totalSupply();
    }

    /**
     * @notice Function for staking exact amount of LP tokens.
     * @param _amount Number of LP tokens.
     */
    function stake(uint256 _amount) 
        external
        override
    {       
            _stake(msg.sender, _amount);
    }

    function _stake(
        address _user,
        uint256 _amount
    )
        internal
    {
        require(
            _amount > 0,
            "JellyLPStaking._stake: Staked amount must be greater than 0"
        );    
    /**
     * @notice Function that executes the staking.
     * @param _user Stakers address.
     * @param _amount Number of LP tokens to stake.
     */
        Staker storage staker = stakers[_user];

        if (balanceOf(_user) == 0 && staker.lastRewardPoints == 0 ) {
          staker.lastRewardPoints = rewardsPerTokenPoints;
        }

        updateReward(_user);
        _mint(_user, _amount);

        OZIERC20(poolToken).safeTransferFrom(
            address(_user),
            address(this),
            _amount
        );
        emit Staked(_user, _amount);
    }

    /**
     * @notice Function for unstaking exact amount of LP tokens.
     * @param _amount Number of LP tokens.
     */
    function unstake(uint256 _amount) external override {
        _unstake(msg.sender, _amount);
    }

    // CC Either unstakeAll is missing or the unstake and _unstake could be merged into one function?

    /**
     * @notice Function that executes the unstaking.
     * @param _user Stakers address.
     * @param _amount Number of LP tokens to unstake.
     */
    function _unstake(address _user, uint256 _amount) internal {
        Staker storage staker = stakers[_user];

        require(
            balanceOf(_user) >= _amount,
            "JellyLPStaking._unstake: Sender must have staked tokens"
        );
        claimRewards(_user);
        _burn(_user, _amount);

        if (balanceOf(_user) == 0) {
            delete stakers[_user];
        }

        uint256 tokenBal = IERC20(poolToken).balanceOf(address(this));

        if (_amount > tokenBal) {
            OZIERC20(poolToken).safeTransfer(address(_user), tokenBal);
        } else {
            OZIERC20(poolToken).safeTransfer(address(_user), _amount);
        }
        emit Unstaked(_user, _amount);
    }


    /// @notice Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake() 
        external 
        override
    {
        uint256 amount = balanceOf(msg.sender);
        _burn(msg.sender,amount);

        address[] memory rewardTokens = rewardsContract.rewardTokens();

        for(uint i = 0; i < rewardTokens.length; i++) {
            userRewards[msg.sender][rewardTokens[i]].rewardsEarned = 0;
        }

        OZIERC20(poolToken).safeTransfer(address(msg.sender), amount);
        emit EmergencyUnstake(msg.sender, amount);
    }


    /// @dev Updates the amount of rewards owed for each user before any tokens are moved
    // TODO: revert for an non existing user?
    function updateReward(
        address _user
    ) 
        public
        override
    {

        rewardsContract.updateRewards();
        uint256 currentRewards = rewardsContract.poolRewards(poolId, lastUpdateTime, block.timestamp);

        if (totalSupply() > 0) {
            rewardsPerTokenPoints = rewardsPerTokenPoints + (currentRewards * 1e18 * pointMultiplier / totalSupply());
        }
        
        lastUpdateTime = block.timestamp;
        uint256 rewards = rewardsOwing(_user);
        Staker storage staker = stakers[_user];
        if (_user != address(0)) {
            staker.lastRewardPoints = rewardsPerTokenPoints; 

            address[] memory rewardTokens = rewardsContract.rewardTokens();

            for(uint i = 0; i < rewardTokens.length; i++) {
                userRewards[_user][rewardTokens[i]].rewardsEarned += rewards;
            }
        }


    }
     


    /// @notice Returns the rewards owing for a user
    /// @dev The rewards are dynamic and normalised from the other pools
    /// @dev This gets the rewards from each of the periods as one multiplier
    function rewardsOwing(
        address _user
    )
        public
        override 
        view
        returns(uint256)
    {
        uint256 newRewardPerToken = rewardsPerTokenPoints - stakers[_user].lastRewardPoints;
        uint256 rewards = balanceOf(_user) * newRewardPerToken
                                                / 1e18
                                                / pointMultiplier;
        return rewards;
    }


    /// @notice Returns the about of rewards yet to be claimed
    /// @return address[] reward tokens
    /// @return uint256[] unclaimed rewards
    function unclaimedRewards(address _user) public view returns(address[] memory, uint256[] memory)
    {   
        /// MKZ: Getting 2 rTokens ('0xe7CB1c67752cBb975a56815Af242ce2Ce63d3113',): Should only be one
        address[] memory rTokens = rewardsContract.rewardTokens();

        uint256[] memory uRewards = new uint[](rTokens.length);
        
        if (totalSupply() == 0) {
            return (rTokens, uRewards);
        }

        uint256 currentRewards = rewardsContract.poolRewards(poolId ,lastUpdateTime, block.timestamp);

        uint256 newRewardPerToken = rewardsPerTokenPoints + (currentRewards
                                                                * 1e18
                                                                * pointMultiplier
                                                                * totalSupply())
                                                         - stakers[_user].lastRewardPoints;

        uint256 rewards = balanceOf(_user) * newRewardPerToken
                                                / 1e18
                                                / pointMultiplier;

        for(uint i = 0; i < rTokens.length; i++) {
            uRewards[i] = rewards + userRewards[_user][rTokens[i]].rewardsEarned - userRewards[_user][rTokens[i]].rewardsReleased;
        }

        return (rTokens, uRewards);
    }


    /**
     * @notice Claiming rewards for user.
     * @param _user User address.
     */
    function claimRewards(address _user) public override {
        require(
            tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );
        updateReward(_user);

        Staker storage staker = stakers[_user];

        address[] memory rewardTokens = rewardsContract.rewardTokens();

        for(uint i = 0; i < rewardTokens.length; i++) {
            UserRewardInfo storage _userRewards = userRewards[msg.sender][rewardTokens[i]];
            uint256 payableAmount = _userRewards.rewardsEarned - _userRewards.rewardsReleased;
            _userRewards.rewardsReleased += payableAmount;

            /// @dev accounts for dust 
            uint256 rewardBal = IERC20(rewardTokens[i]).balanceOf(vault);
            if (payableAmount > rewardBal) {
                payableAmount = rewardBal;
            }
            
            OZIERC20(rewardTokens[i]).safeTransfer(_user, payableAmount);
            emit RewardPaid(_user, payableAmount);
        }
    }

    function getUserRewardInfo(address _user, address _token) public view returns (uint256, uint256){
        UserRewardInfo memory userInfo = userRewards[_user][_token];
        return (userInfo.rewardsEarned, userInfo.rewardsReleased);
    }   

    // /// @notice ERC20 Functions (Optional)
    // /// @dev GP: Not sure if this makes sense yet
    // /// @dev GP: Would be cool if when you stake, you get a staking token to do defi things
    // function totalSupply() external override view returns (uint256) {}
    // function balanceOf(address account) external override view returns (uint256) {}
    // function allowance(address owner, address spender) external override view returns (uint256) {}
    // function approve(address spender, uint256 amount) external override returns (bool) {}
    // function name() external override view returns (string memory) {}
    // function symbol() external override view returns (string memory) {}
    // function decimals() external override view returns (uint8) {}
    // function transfer(address recipient, uint256 amount) external override returns (bool) {}
    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) external  override returns (bool) {}

    // /// @notice EIP 2612
    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external override {}


    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _rewardsToken Reward token interface.
     * @param _poolToken Address of the LP token.
     * @param _accessControls Access controls interface.
     */
    function initTokenPool(
        address _rewardsToken,
        address _poolToken,
        address _accessControls,
        address _vault
    ) public 
    {
        require(!initialised, "Already initialised");
        rewardsToken = OZIERC20(_rewardsToken);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        lastUpdateTime = block.timestamp;
        initialised = true;
        vault = _vault;
    }

    function init(bytes calldata _data) external  payable {}

    function initPool(
        bytes calldata _data
    ) public {
        (address _rewardsToken,
        address _poolToken,
        address _accessControls,
        address _vault) = abi.decode(_data, (address, address, address, address));

        initTokenPool(_rewardsToken,
                        _poolToken,
                        _accessControls,
                        _vault);
    }

   /** 
     * @dev Generates init data for Farm Factory
  */
    function getInitData(
        address _rewardsToken,
        address _poolToken,
        address _accessControls,
        address _vault
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(_rewardsToken,
                        _poolToken,
                        _accessControls,
                        _vault);
    }


}
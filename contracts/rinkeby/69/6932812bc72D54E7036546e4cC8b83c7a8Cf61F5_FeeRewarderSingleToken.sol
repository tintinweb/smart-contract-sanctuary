// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISeason {
    struct AddInitialVaultPoolArgs {
        address vaultPoolAddr;
        uint32 weight;
    }

    function initialize(
        uint32 _startBlock,
        uint32 _endBlock,
        uint256 _anonPerBlock,
        address _anonToken,
        AddInitialVaultPoolArgs[] calldata _initialVaultPools,
        string memory name_,
        string memory symbol_,
        bytes32 _initialDescription
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { Governable } from '../Governance/Governable.sol';
import { ISeason } from './Season/ISeason.sol';
import { IScoreUpdateCallbackReceiver } from '../Callbacks/IScoreUpdateCallbackReceiver.sol';

/// @title The Season Factory Contract
contract SeasonFactory is Governable {
    using SafeERC20 for IERC20;

    address public immutable anonToken;
    address public seasonImplementation; // changable

    // season address => is valid
    mapping(address => bool) public isValidSeason;

    event SeasonCreated(address seasonAddr);
    event SeasonImplementationChanged(address newSeasonImplementation);

    modifier onlySeason() {
        // callable by Season contract (the child contract)
        require(isValidSeason[msg.sender], 'SeasonFactory:onlySeason:V');
        _;
    }

    constructor(address anonToken_) {
        anonToken = anonToken_;
    }

    struct InitializeSeasonArgs {
        uint32 startBlock; // The block from which season starts
        uint32 endBlock; // The block at which season ends
        uint256 anonPerBlock; // Amount of ANON Tokens per block
        address fundsFrom; // Address that pays the rewards
        ISeason.AddInitialVaultPoolArgs[] initalVaultPools; // Vault addresses and weights
        string name; // Season NFT Name
        string symbol; // Season NFT Symbol
        bytes32 initialDescription;
    }

    /// @notice Allows governance to create a new season
    /// @param args: Arguments required to initialize a created season
    /// @dev Need allowance by fundsFrom of (endBlock - startBlock + 1) * anonPerBlock ANON tokens
    function createSeason(InitializeSeasonArgs calldata args) external onlyGovernance {
        require(seasonImplementation != address(0), 'SeasonFactory:createSeason:Z');
        address season = Clones.clone(seasonImplementation);
        _initializeSeason(season, args);
    }

    /// @notice Changes the season implementation bytecode
    /// @dev seasons created before this are not affected
    /// @param newSeasonImplementation: Address of the new implementation
    function changeSeasonImplementation(address newSeasonImplementation, InitializeSeasonArgs calldata args)
        external
        onlyGovernance
    {
        seasonImplementation = newSeasonImplementation;
        emit SeasonImplementationChanged(newSeasonImplementation);

        // if initialize season args are provided then initialize
        if (args.anonPerBlock != 0) {
            _initializeSeason(newSeasonImplementation, args);
        }
    }

    /// @notice Initializes a season after it's deployment
    /// @param season: Address of freshly deployed season contract
    /// @param args: Create season args required to pass to the Season.initialize method
    function _initializeSeason(address season, InitializeSeasonArgs calldata args) internal {
        IERC20(anonToken).safeTransferFrom(
            args.fundsFrom,
            season,
            (args.endBlock - args.startBlock + 1) * args.anonPerBlock
        );
        ISeason(season).initialize(
            args.startBlock,
            args.endBlock,
            args.anonPerBlock,
            anonToken,
            args.initalVaultPools,
            args.name,
            args.symbol,
            args.initialDescription
        );

        isValidSeason[season] = true;

        emit SeasonCreated(season);
    }

    /**
        Tracking individual scores for better UX in AnonStaking & Governance
     */
    IScoreUpdateCallbackReceiver public callback;
    mapping(address => uint32) public userIndividualScoreSum;

    event NftTransfer(address season, address from, address to, uint256 nftId);

    /// @notice Changes the callback logic
    /// @dev This is to be used when a new contract is added to the ecosystem which requires
    ///     to be triggered whenever score updates.
    /// @param callback_: new callback contract
    function setCallback(IScoreUpdateCallbackReceiver callback_) external onlyGovernance {
        callback = callback_;
    }

    /// @notice Called by season contract when score of a user increases
    /// @param user: Address of user who owns an NFT whose score is increasing
    /// @param score: Amount of score that is increased in the NFT
    function handleIndividualScoreIncrease(address user, uint16 score) external onlySeason {
        userIndividualScoreSum[user] += score;

        IScoreUpdateCallbackReceiver _callback = callback;
        // if callback contract not yet set then do not call
        if (address(_callback) != address(0)) {
            _callback.handleIndividualScoreChanged(user);
        }
    }

    /// @notice Called by season contract when a user is transferring their NFT to someone
    /// @param from: the user who is transferring their nft
    /// @param to: the user who is receiving the nft
    /// @param score: score in the nft
    function handleSeasonNftTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint16 score
    ) external onlySeason {
        emit NftTransfer(msg.sender, from, to, tokenId);

        if (from != address(0)) {
            userIndividualScoreSum[from] -= score;
        }
        if (to != address(0)) {
            userIndividualScoreSum[to] += score;
        }

        IScoreUpdateCallbackReceiver _callback = callback;
        // if callback contract not yet set then do not call
        if (address(_callback) != address(0)) {
            _callback.handleIndividualScoreChanged(from);
            _callback.handleIndividualScoreChanged(to);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScoreUpdateCallbackReceiver {
    function handleIndividualScoreChanged(address userAddr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { SeasonFactory } from '../../AnonSeasons/SeasonFactory.sol';
import { CastingMath } from '../../libraries/CastingMath.sol';
import { IScoreUpdateCallbackReceiver } from '../../Callbacks/IScoreUpdateCallbackReceiver.sol';

/// @title The Staking contract
/// @notice Allows users to stake ANONs and get rewards in ANONs
/// @dev ANON tokens for rewards have to be simply dropped on this contract address.
///     Accrued rewards have to be restaked for compounding.
contract FeeRewarderSingleToken is IScoreUpdateCallbackReceiver {
    using SafeERC20 for IERC20;
    using CastingMath for uint256;

    uint256 constant PRECISION_FACTOR = 10**12;

    IERC20 public immutable anon;
    SeasonFactory public immutable seasonFactory;

    // TODO Anon decimals was changed to 18, this might cause overflow
    // bytes32 x2
    struct GlobalState {
        // SLOT 1
        uint96 anonBalanceLast; // Used to find staking rewards
        uint128 checkpoint;
        // SLOT 2
        uint128 totalAmplifiedDeposits; // sum of virtual balances of all users
    }

    GlobalState public global;

    // bytes32 x1
    struct UserInfo {
        uint96 anonDeposits; // principal + rewards accrued
        uint32 amplification; // divide by 100 to get 1X
        uint128 checkpointLast;
    }

    // user addr => info
    mapping(address => UserInfo) public users;

    constructor(IERC20 _anon, SeasonFactory _seasonFactory) {
        anon = _anon;
        seasonFactory = _seasonFactory;
    }

    struct CurrentUserState {
        GlobalState global;
        UserInfo user;
        uint96 amplifiedPrevious;
    }

    /// @notice This function is used for deposit
    /// @param depositAmount: amount to deposit
    function deposit(uint96 depositAmount) external {
        CurrentUserState memory temp = getUpdatedState(msg.sender); // SLOAD x4

        temp.global.anonBalanceLast += depositAmount;
        temp.user.anonDeposits += depositAmount;
        anon.safeTransferFrom(msg.sender, address(this), depositAmount);

        _writeState(temp); // SSTORE x3
    }

    /// @notice This function is used for withdraw
    /// @param withdrawalAmount: positive for deposit, negative for withdraw and zero for claim
    function withdraw(uint96 withdrawalAmount) external {
        CurrentUserState memory temp = getUpdatedState(msg.sender); // SLOAD x4

        // if user want to withdraw everything, but the value of user.anonDeposits
        // can increased due to fee collection. Hence for withdraw all type(uint96).min
        uint96 _amount = (withdrawalAmount == type(uint96).max) ? temp.user.anonDeposits : withdrawalAmount;
        temp.global.anonBalanceLast -= _amount;
        temp.user.anonDeposits -= _amount;
        anon.safeTransfer(msg.sender, _amount);

        _writeState(temp); // SSTORE x3
    }

    /// @notice This function is used for restaking the earned rewards for compounding
    function restake() external {
        CurrentUserState memory temp = getUpdatedState(msg.sender); // SLOAD x4

        _writeState(temp); // SSTORE x3
    }

    /// @notice Called by Seasons Factory, Updates amplification for a user
    /// @dev Not restricted to SeasonsFactory address to save an SLOAD
    /// @param userAddr address of a user
    function handleIndividualScoreChanged(address userAddr) external override {
        // adding 1X amplification
        // TODO bounded amplification 1x to 10x
        uint32 score = seasonFactory.userIndividualScoreSum(userAddr); // SLOAD
        uint32 newAmplification = getAmplification(score);

        CurrentUserState memory temp = getUpdatedState(msg.sender); // SLOAD x4

        // updating the total amplified virtual deposits of all users deposited to this contract
        // total deposits = total deposits - user old deposits + user updated deposits
        temp.global.totalAmplifiedDeposits =
            temp.global.totalAmplifiedDeposits -
            temp.user.amplification *
            temp.user.anonDeposits +
            newAmplification *
            temp.user.anonDeposits;

        // updating user deposits
        temp.user.amplification = newAmplification;

        global = temp.global; // SSTORE x2
        users[userAddr] = temp.user; // SSTORE x1
    }

    /// @notice Gives updated global state, based on new ANON tokens sent to this contract
    /// @dev Does not write to storage, so _global and user needs to be SSTOREd later
    /// @dev Can be used by UI to display user's deposit balance
    /// @return temp Updated State
    function getUpdatedState(address userAddr) public view returns (CurrentUserState memory temp) {
        temp.global = global; // SLOAD x2
        temp.user = users[userAddr]; // SLOAD x1
        if (temp.user.amplification == 0) {
            temp.user.amplification = getAmplification(0);
        }
        temp.amplifiedPrevious = (uint256(temp.user.anonDeposits) * temp.user.amplification).toU96();

        uint96 currentAnonBalance = anon.balanceOf(address(this)).toU96(); // SLOAD x1

        // if some ANON tokens are dropped here then update checkpoint
        if (currentAnonBalance > temp.global.anonBalanceLast && temp.global.totalAmplifiedDeposits > 0) {
            temp.global.checkpoint += (((currentAnonBalance - temp.global.anonBalanceLast) * PRECISION_FACTOR) /
                temp.global.totalAmplifiedDeposits).toU128();
            temp.global.anonBalanceLast = currentAnonBalance;
        }

        // if checkpoint was increased, add the user's share to their principal deposits
        if (temp.global.checkpoint > temp.user.checkpointLast) {
            temp.user.anonDeposits += (((temp.global.checkpoint - temp.user.checkpointLast) * temp.amplifiedPrevious) /
                PRECISION_FACTOR).toU96();
            temp.user.checkpointLast = temp.global.checkpoint;
        }
    }

    /// @notice Gives an amplification multiplier in basis points for a given score
    /// @param score: total individual score of a user
    /// @return amplification multiplier, multiplied to user ANON deposits
    function getAmplification(uint32 score) public pure returns (uint32) {
        // 1/25x+1      for x belongs to [0,100% score]
        // 1/40x+5/2    for x belongs to [100% score,300% score]
        // 10           for x belongs to [300% score, infinity]
        if (score <= 10000) {
            return score / 25 + 100;
        } else {
            return uint32(Math.min(1000, score / 40 + 250));
        }
    }

    /// @notice This internal function is used to state after a deposit/withdraw
    function _writeState(CurrentUserState memory temp) internal {
        // calculate the virtual anon balance for the user
        uint128 amplifiedCurrent = (uint128(temp.user.anonDeposits) * temp.user.amplification);
        // also update the total virtual deposits
        temp.global.totalAmplifiedDeposits =
            temp.global.totalAmplifiedDeposits -
            temp.amplifiedPrevious +
            amplifiedCurrent;

        // write updated global and user state to storage
        global = temp.global; // SSTORE x2
        users[msg.sender] = temp.user; // SSTORE x1
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Context } from '@openzeppelin/contracts/utils/Context.sol';

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance` and `onlyGovernanceOrTeamMultisig`, which can be applied to your functions
 * to restrict their use to the caller.
 */
abstract contract Governable is Context {
    address private _governance;
    address private _teamMultisig;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event TeamMultisigTransferred(address indexed previousTeamMultisig, address indexed newTeamMultisig);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance and team multisig.
     */
    constructor() {
        address msgSender = _msgSender();

        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);

        _teamMultisig = msgSender;
        emit TeamMultisigTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Returns the address of the current team multisig.
     */
    function teamMultisig() public view virtual returns (address) {
        return _teamMultisig;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(governance() == _msgSender(), 'Governable: caller is not the gov');
        _;
    }

    /**
     * @dev Throws if called by any account other than the governance or team multisig.
     */
    modifier onlyGovernanceOrTeamMultisig() {
        require(
            teamMultisig() == _msgSender() || governance() == _msgSender(),
            'Governable: caller is not the gov or multisig'
        );
        _;
    }

    /**
     * @dev Transfers governance to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public virtual onlyGovernance {
        require(newGovernance != address(0), 'Governable: new gov is the zero address');
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }

    /**
     * @dev Transfers teamMultisig to a new account (`newTeamMultisig`).
     * Can only be called by the current teamMultisig or current governance.
     */
    function transferTeamMultisig(address newTeamMultisig) public virtual onlyGovernanceOrTeamMultisig {
        require(newTeamMultisig != address(0), 'Governable: new multisig is the zero address');
        emit TeamMultisigTransferred(_teamMultisig, newTeamMultisig);
        _teamMultisig = newTeamMultisig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library CastingMath {
    error Overflow();

    function toU224(uint256 a) internal pure returns (uint224 c) {
        if (a > type(uint224).max) {
            revert Overflow();
        }
        c = uint224(a);
    }

    function toU128(uint256 a) internal pure returns (uint128 c) {
        if (a > type(uint128).max) {
            revert Overflow();
        }
        c = uint128(a);
    }

    function toU96(uint256 a) internal pure returns (uint96 c) {
        if (a > type(uint96).max) {
            revert Overflow();
        }
        c = uint96(a);
    }

    function toU72(uint256 a) internal pure returns (uint72 c) {
        if (a > type(uint72).max) {
            revert Overflow();
        }
        c = uint72(a);
    }

    function toU64(uint256 a) internal pure returns (uint64 c) {
        if (a > type(uint64).max) {
            revert Overflow();
        }
        c = uint64(a);
    }

    function toU48(uint256 a) internal pure returns (uint48 c) {
        if (a > type(uint48).max) {
            revert Overflow();
        }
        c = uint48(a);
    }

    function toU32(uint256 a) internal pure returns (uint32 c) {
        if (a > type(uint32).max) {
            revert Overflow();
        }
        c = uint32(a);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
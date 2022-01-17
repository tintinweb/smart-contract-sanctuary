// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MultiRole.sol";
import "../interfaces/ExpandedIERC20.sol";

/**
 * @title An ERC20 with permissioned burning and minting. The contract deployer will initially
 * be the owner who is capable of adding new roles.
 */
contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
    enum Roles {
        // Can set the minter and burner.
        Owner,
        // Addresses that can mint new tokens.
        Minter,
        // Addresses that can burn tokens that address owns.
        Burner
    }

    uint8 _decimals;

    /**
     * @notice Constructs the ExpandedERC20.
     * @param _tokenName The name which describes the new token.
     * @param _tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) ERC20(_tokenName, _tokenSymbol) {
        _decimals = _tokenDecimals;
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createSharedRole(uint256(Roles.Minter), uint256(Roles.Owner), new address[](0));
        _createSharedRole(uint256(Roles.Burner), uint256(Roles.Owner), new address[](0));
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Mints `value` tokens to `recipient`, returning true on success.
     * @param recipient address to mint to.
     * @param value amount of tokens to mint.
     * @return True if the mint succeeded, or False.
     */
    function mint(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Minter))
        returns (bool)
    {
        _mint(recipient, value);
        return true;
    }

    /**
     * @dev Burns `value` tokens owned by `msg.sender`.
     * @param value amount of tokens to burn.
     */
    function burn(uint256 value) external override onlyRoleHolder(uint256(Roles.Burner)) {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns `value` tokens owned by `recipient`.
     * @param recipient address to burn tokens from.
     * @param value amount of tokens to burn.
     * @return True if the burn succeeded, or False.
     */
    function burnFrom(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Burner))
        returns (bool)
    {
        _burn(recipient, value);
        return true;
    }

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external virtual override {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external virtual override {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external virtual override {
        resetMember(uint256(Roles.Owner), account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run in production, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the currentTime variable set in the Timer.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes burn and mint methods.
 */
abstract contract ExpandedIERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev Only burns the caller's tokens, so it is safe to leave this method permissionless.
     */
    function burn(uint256 value) external virtual;

    /**
     * @dev Burns `value` tokens owned by `recipient`.
     * @param recipient address to burn tokens from.
     * @param value amount of tokens to burn.
     */
    function burnFrom(address recipient, uint256 value) external virtual returns (bool);

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external virtual returns (bool);

    function addMinter(address account) external virtual;

    function addBurner(address account) external virtual;

    function resetOwner(address account) external virtual;
}

/**
 * @title Library to construct admin identifiers.
 */
library AdminIdentifierLib {
    // Returns a UTF-8 identifier representing a particular admin proposal.
    // The identifier is of the form "Admin n", where n is the proposal id provided.
    function _constructIdentifier(uint256 id) internal pure returns (bytes32) {
        bytes32 bytesId = _uintToUtf8(id);
        return _addPrefix(bytesId, "Admin ", 6);
    }

    // This method converts the integer `v` into a base-10, UTF-8 representation stored in a `bytes32` type.
    // If the input cannot be represented by 32 base-10 digits, it returns only the highest 32 digits.
    // This method is based off of this code: https://ethereum.stackexchange.com/a/6613/47801.
    function _uintToUtf8(uint256 v) internal pure returns (bytes32) {
        bytes32 ret;
        if (v == 0) {
            // Handle 0 case explicitly.
            ret = "0";
        } else {
            // Constants.
            uint256 bitsPerByte = 8;
            uint256 base = 10; // Note: the output should be base-10. The below implementation will not work for bases > 10.
            uint256 utf8NumberOffset = 48;
            while (v > 0) {
                // Downshift the entire bytes32 to allow the new digit to be added at the "front" of the bytes32, which
                // translates to the beginning of the UTF-8 representation.
                ret = ret >> bitsPerByte;

                // Separate the last digit that remains in v by modding by the base of desired output representation.
                uint256 leastSignificantDigit = v % base;

                // Digits 0-9 are represented by 48-57 in UTF-8, so an offset must be added to create the character.
                bytes32 utf8Digit = bytes32(leastSignificantDigit + utf8NumberOffset);

                // The top byte of ret has already been cleared to make room for the new digit.
                // Upshift by 31 bytes to put it in position, and OR it with ret to leave the other characters untouched.
                ret |= utf8Digit << (31 * bitsPerByte);

                // Divide v by the base to remove the digit that was just added.
                v /= base;
            }
        }
        return ret;
    }

    // This method takes two UTF-8 strings represented as bytes32 and outputs one as a prefixed by the other.
    // `input` is the UTF-8 that should have the prefix prepended.
    // `prefix` is the UTF-8 that should be prepended onto input.
    // `prefixLength` is number of UTF-8 characters represented by `prefix`.
    // Notes:
    // 1. If the resulting UTF-8 is larger than 32 characters, then only the first 32 characters will be represented
    //    by the bytes32 output.
    // 2. If `prefix` has more characters than `prefixLength`, the function will produce an invalid result.
    function _addPrefix(
        bytes32 input,
        bytes32 prefix,
        uint256 prefixLength
    ) internal pure returns (bytes32) {
        // Downshift `input` to open space at the "front" of the bytes32
        bytes32 shiftedInput = input >> (prefixLength * 8);
        return shiftedInput | prefix;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/FinderInterface.sol";

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples of interfaces with implementations that Finder locates are the Oracle and Store interfaces.
 */
contract Finder is FinderInterface, Ownable {
    mapping(bytes32 => address) public interfacesImplemented;

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 of the interface name that is either changed or registered.
     * @param implementationAddress address of the implementation contract.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress)
        external
        override
        onlyOwner
    {
        interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the defined interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view override returns (address) {
        address implementationAddress = interfacesImplemented[interfaceName];
        require(implementationAddress != address(0x0), "Implementation not found");
        return implementationAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/OracleInterface.sol";
import "./Constants.sol";
import "./AdminIdentifierLib.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Takes proposals for certain governance actions and allows UMA token holders to vote on them.
 */
contract Governor is MultiRole, Testable {
    using SafeMath for uint256;
    using Address for address;

    /****************************************
     *     INTERNAL VARIABLES AND STORAGE   *
     ****************************************/

    enum Roles {
        Owner, // Can set the proposer.
        Proposer // Address that can make proposals.
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposal {
        Transaction[] transactions;
        uint256 requestTime;
    }

    FinderInterface private finder;
    Proposal[] public proposals;

    /****************************************
     *                EVENTS                *
     ****************************************/

    // Emitted when a new proposal is created.
    event NewProposal(uint256 indexed id, Transaction[] transactions);

    // Emitted when an existing proposal is executed.
    event ProposalExecuted(uint256 indexed id, uint256 transactionIndex);

    /**
     * @notice Construct the Governor contract.
     * @param _finderAddress keeps track of all contracts within the system based on their interfaceName.
     * @param _startingId the initial proposal id that the contract will begin incrementing from.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _finderAddress,
        uint256 _startingId,
        address _timerAddress
    ) Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createExclusiveRole(uint256(Roles.Proposer), uint256(Roles.Owner), msg.sender);

        // Ensure the startingId is not set unreasonably high to avoid it being set such that new proposals overwrite
        // other storage slots in the contract.
        uint256 maxStartingId = 10**18;
        require(_startingId <= maxStartingId, "Cannot set startingId larger than 10^18");

        // This just sets the initial length of the array to the startingId since modifying length directly has been
        // disallowed in solidity 0.6.
        assembly {
            sstore(proposals.slot, _startingId)
        }
    }

    /****************************************
     *          PROPOSAL ACTIONS            *
     ****************************************/

    /**
     * @notice Proposes a new governance action. Can only be called by the holder of the Proposer role.
     * @param transactions list of transactions that are being proposed.
     * @dev You can create the data portion of each transaction by doing the following:
     * ```
     * const truffleContractInstance = await TruffleContract.deployed()
     * const data = truffleContractInstance.methods.methodToCall(arg1, arg2).encodeABI()
     * ```
     * Note: this method must be public because of a solidity limitation that
     * disallows structs arrays to be passed to external functions.
     */
    function propose(Transaction[] memory transactions) public onlyRoleHolder(uint256(Roles.Proposer)) {
        uint256 id = proposals.length;
        uint256 time = getCurrentTime();

        // Note: doing all of this array manipulation manually is necessary because directly setting an array of
        // structs in storage to an an array of structs in memory is currently not implemented in solidity :/.

        // Add a zero-initialized element to the proposals array.
        proposals.push();

        // Initialize the new proposal.
        Proposal storage proposal = proposals[id];
        proposal.requestTime = time;

        // Initialize the transaction array.
        for (uint256 i = 0; i < transactions.length; i++) {
            require(transactions[i].to != address(0), "The `to` address cannot be 0x0");
            // If the transaction has any data with it the recipient must be a contract, not an EOA.
            if (transactions[i].data.length > 0) {
                require(transactions[i].to.isContract(), "EOA can't accept tx with data");
            }
            proposal.transactions.push(transactions[i]);
        }

        bytes32 identifier = AdminIdentifierLib._constructIdentifier(id);

        // Request a vote on this proposal in the DVM.
        OracleInterface oracle = _getOracle();
        IdentifierWhitelistInterface supportedIdentifiers = _getIdentifierWhitelist();
        supportedIdentifiers.addSupportedIdentifier(identifier);

        oracle.requestPrice(identifier, time);
        supportedIdentifiers.removeSupportedIdentifier(identifier);

        emit NewProposal(id, transactions);
    }

    /**
     * @notice Executes a proposed governance action that has been approved by voters.
     * @dev This can be called by any address. Caller is expected to send enough ETH to execute payable transactions.
     * @param id unique id for the executed proposal.
     * @param transactionIndex unique transaction index for the executed proposal.
     */
    function executeProposal(uint256 id, uint256 transactionIndex) external payable {
        Proposal storage proposal = proposals[id];
        int256 price = _getOracle().getPrice(AdminIdentifierLib._constructIdentifier(id), proposal.requestTime);

        Transaction memory transaction = proposal.transactions[transactionIndex];

        require(
            transactionIndex == 0 || proposal.transactions[transactionIndex.sub(1)].to == address(0),
            "Previous tx not yet executed"
        );
        require(transaction.to != address(0), "Tx already executed");
        require(price != 0, "Proposal was rejected");
        require(msg.value == transaction.value, "Must send exact amount of ETH");

        // Delete the transaction before execution to avoid any potential re-entrancy issues.
        delete proposal.transactions[transactionIndex];

        require(_executeCall(transaction.to, transaction.value, transaction.data), "Tx execution failed");

        emit ProposalExecuted(id, transactionIndex);
    }

    /****************************************
     *       GOVERNOR STATE GETTERS         *
     ****************************************/

    /**
     * @notice Gets the total number of proposals (includes executed and non-executed).
     * @return uint256 representing the current number of proposals.
     */
    function numProposals() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Gets the proposal data for a particular id.
     * @dev after a proposal is executed, its data will be zeroed out, except for the request time.
     * @param id uniquely identify the identity of the proposal.
     * @return proposal struct containing transactions[] and requestTime.
     */
    function getProposal(uint256 id) external view returns (Proposal memory) {
        return proposals[id];
    }

    /****************************************
     *      PRIVATE GETTERS AND FUNCTIONS   *
     ****************************************/

    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        // Mostly copied from:
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly

        bool success;
        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
        }
        return success;
    }

    function _getOracle() private view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Finder.sol";
import "./Governor.sol";
import "./Constants.sol";
import "./Voting.sol";
import "./AdminIdentifierLib.sol";
import "../../common/implementation/Lockable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Proposer contract that allows anyone to make governance proposals with a bond.
 */
contract Proposer is Ownable, Testable, Lockable {
    using SafeERC20 for IERC20;
    IERC20 public token;
    uint256 public bond;
    Governor public governor;
    Finder public finder;

    struct BondedProposal {
        address sender;
        // 64 bits to save a storage slot.
        uint64 time;
        uint256 lockedBond;
    }
    mapping(uint256 => BondedProposal) public bondedProposals;

    event BondSet(uint256 bond);
    event ProposalResolved(uint256 indexed id, bool success);

    /**
     * @notice Construct the Proposer contract.
     * @param _token the ERC20 token that the bond is paid in.
     * @param _bond the bond amount.
     * @param _governor the governor contract that this contract makes proposals to.
     * @param _finder the finder contract used to look up addresses.
     * @param _timer the timer contract to control the output of getCurrentTime(). Set to 0x0 if in production.
     */
    constructor(
        IERC20 _token,
        uint256 _bond,
        Governor _governor,
        Finder _finder,
        address _timer
    ) Testable(_timer) {
        token = _token;
        governor = _governor;
        finder = _finder;
        setBond(_bond);
        transferOwnership(address(_governor));
    }

    /**
     * @notice Propose a new set of governance transactions for vote.
     * @dev Pulls bond from the caller.
     * @param transactions list of transactions for the governor to execute.
     * @return id the id of the governor proposal.
     */
    function propose(Governor.Transaction[] memory transactions) external nonReentrant() returns (uint256 id) {
        id = governor.numProposals();
        token.safeTransferFrom(msg.sender, address(this), bond);
        bondedProposals[id] = BondedProposal({ sender: msg.sender, lockedBond: bond, time: uint64(getCurrentTime()) });
        governor.propose(transactions);
    }

    /**
     * @notice Resolves a proposal by checking the status of the request in the Voting contract.
     * @dev For the resolution to work correctly, this contract must be a registered contract in the DVM.
     * @param id proposal id.
     */
    function resolveProposal(uint256 id) external nonReentrant() {
        BondedProposal storage bondedProposal = bondedProposals[id];
        Voting voting = Voting(finder.getImplementationAddress(OracleInterfaces.Oracle));
        require(
            voting.hasPrice(AdminIdentifierLib._constructIdentifier(id), bondedProposal.time, ""),
            "No price resolved"
        );
        if (voting.getPrice(AdminIdentifierLib._constructIdentifier(id), bondedProposal.time, "") != 0) {
            token.safeTransfer(bondedProposal.sender, bondedProposal.lockedBond);
            emit ProposalResolved(id, true);
        } else {
            token.safeTransfer(finder.getImplementationAddress(OracleInterfaces.Store), bondedProposal.lockedBond);
            emit ProposalResolved(id, false);
        }
        delete bondedProposals[id];
    }

    /**
     * @notice Admin method to set the bond amount.
     * @dev Admin is intended to be the governance system, itself.
     * @param _bond the new bond.
     */
    function setBond(uint256 _bond) public nonReentrant() onlyOwner() {
        bond = _bond;
        emit BondSet(_bond);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/MultiRole.sol";
import "../interfaces/RegistryInterface.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Registry for financial contracts and approved financial contract creators.
 * @dev Maintains a whitelist of financial contract creators that are allowed
 * to register new financial contracts and stores party members of a financial contract.
 */
contract Registry is RegistryInterface, MultiRole {
    using SafeMath for uint256;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles {
        Owner, // The owner manages the set of ContractCreators.
        ContractCreator // Can register financial contracts.
    }

    // This enum is required because a `WasValid` state is required
    // to ensure that financial contracts cannot be re-registered.
    enum Validity { Invalid, Valid }

    // Local information about a contract.
    struct FinancialContract {
        Validity valid;
        uint128 index;
    }

    struct Party {
        address[] contracts; // Each financial contract address is stored in this array.
        // The address of each financial contract is mapped to its index for constant time look up and deletion.
        mapping(address => uint256) contractIndex;
    }

    // Array of all contracts that are approved to use the UMA Oracle.
    address[] public registeredContracts;

    // Map of financial contract contracts to the associated FinancialContract struct.
    mapping(address => FinancialContract) public contractMap;

    // Map each party member to their their associated Party struct.
    mapping(address => Party) private partyMap;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewContractRegistered(address indexed contractAddress, address indexed creator, address[] parties);
    event PartyAdded(address indexed contractAddress, address indexed party);
    event PartyRemoved(address indexed contractAddress, address indexed party);

    /**
     * @notice Construct the Registry contract.
     */
    constructor() {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        // Start with no contract creators registered.
        _createSharedRole(uint256(Roles.ContractCreator), uint256(Roles.Owner), new address[](0));
    }

    /****************************************
     *        REGISTRATION FUNCTIONS        *
     ****************************************/

    /**
     * @notice Registers a new financial contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties array of addresses who become parties in the contract.
     * @param contractAddress address of the contract against which the parties are registered.
     */
    function registerContract(address[] calldata parties, address contractAddress)
        external
        override
        onlyRoleHolder(uint256(Roles.ContractCreator))
    {
        FinancialContract storage financialContract = contractMap[contractAddress];
        require(contractMap[contractAddress].valid == Validity.Invalid, "Can only register once");

        // Store contract address as a registered contract.
        registeredContracts.push(contractAddress);

        // No length check necessary because we should never hit (2^127 - 1) contracts.
        financialContract.index = uint128(registeredContracts.length.sub(1));

        // For all parties in the array add them to the contract's parties.
        financialContract.valid = Validity.Valid;
        for (uint256 i = 0; i < parties.length; i = i.add(1)) {
            _addPartyToContract(parties[i], contractAddress);
        }

        emit NewContractRegistered(contractAddress, msg.sender, parties);
    }

    /**
     * @notice Adds a party member to the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is added to.
     * @param party new party for the calling contract.
     */
    function addPartyToContract(address party) external override {
        address contractAddress = msg.sender;
        require(contractMap[contractAddress].valid == Validity.Valid, "Can only add to valid contract");

        _addPartyToContract(party, contractAddress);
    }

    /**
     * @notice Removes a party member from the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is removed from.
     * @param partyAddress address to be removed from the calling contract.
     */
    function removePartyFromContract(address partyAddress) external override {
        address contractAddress = msg.sender;
        Party storage party = partyMap[partyAddress];
        uint256 numberOfContracts = party.contracts.length;

        require(numberOfContracts != 0, "Party has no contracts");
        require(contractMap[contractAddress].valid == Validity.Valid, "Remove only from valid contract");
        require(isPartyMemberOfContract(partyAddress, contractAddress), "Can only remove existing party");

        // Index of the current location of the contract to remove.
        uint256 deleteIndex = party.contractIndex[contractAddress];

        // Store the last contract's address to update the lookup map.
        address lastContractAddress = party.contracts[numberOfContracts - 1];

        // Swap the contract to be removed with the last contract.
        party.contracts[deleteIndex] = lastContractAddress;

        // Update the lookup index with the new location.
        party.contractIndex[lastContractAddress] = deleteIndex;

        // Pop the last contract from the array and update the lookup map.
        party.contracts.pop();
        delete party.contractIndex[contractAddress];

        emit PartyRemoved(contractAddress, partyAddress);
    }

    /****************************************
     *         REGISTRY STATE GETTERS       *
     ****************************************/

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the financial contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view override returns (bool) {
        return contractMap[contractAddress].valid == Validity.Valid;
    }

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view override returns (address[] memory) {
        return partyMap[party].contracts;
    }

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view override returns (address[] memory) {
        return registeredContracts;
    }

    /**
     * @notice checks if an address is a party of a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) public view override returns (bool) {
        uint256 index = partyMap[party].contractIndex[contractAddress];
        return partyMap[party].contracts.length > index && partyMap[party].contracts[index] == contractAddress;
    }

    /****************************************
     *           INTERNAL FUNCTIONS         *
     ****************************************/

    function _addPartyToContract(address party, address contractAddress) internal {
        require(!isPartyMemberOfContract(party, contractAddress), "Can only register a party once");
        uint256 contractIndex = partyMap[party].contracts.length;
        partyMap[party].contracts.push(contractAddress);
        partyMap[party].contractIndex[contractAddress] = contractIndex;

        emit PartyAdded(contractAddress, party);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Computes vote results.
 * @dev The result is the mode of the added votes. Otherwise, the vote is unresolved.
 */
library ResultComputation {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *   INTERNAL LIBRARY DATA STRUCTURE    *
     ****************************************/

    struct Data {
        // Maps price to number of tokens that voted for that price.
        mapping(int256 => FixedPoint.Unsigned) voteFrequency;
        // The total votes that have been added.
        FixedPoint.Unsigned totalVotes;
        // The price that is the current mode, i.e., the price with the highest frequency in `voteFrequency`.
        int256 currentMode;
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Adds a new vote to be used when computing the result.
     * @param data contains information to which the vote is applied.
     * @param votePrice value specified in the vote for the given `numberTokens`.
     * @param numberTokens number of tokens that voted on the `votePrice`.
     */
    function addVote(
        Data storage data,
        int256 votePrice,
        FixedPoint.Unsigned memory numberTokens
    ) internal {
        data.totalVotes = data.totalVotes.add(numberTokens);
        data.voteFrequency[votePrice] = data.voteFrequency[votePrice].add(numberTokens);
        if (
            votePrice != data.currentMode &&
            data.voteFrequency[votePrice].isGreaterThan(data.voteFrequency[data.currentMode])
        ) {
            data.currentMode = votePrice;
        }
    }

    /****************************************
     *        VOTING STATE GETTERS          *
     ****************************************/

    /**
     * @notice Returns whether the result is resolved, and if so, what value it resolved to.
     * @dev `price` should be ignored if `isResolved` is false.
     * @param data contains information against which the `minVoteThreshold` is applied.
     * @param minVoteThreshold min (exclusive) number of tokens that must have voted for the result to be valid. Can be
     * used to enforce a minimum voter participation rate, regardless of how the votes are distributed.
     * @return isResolved indicates if the price has been resolved correctly.
     * @return price the price that the dvm resolved to.
     */
    function getResolvedPrice(Data storage data, FixedPoint.Unsigned memory minVoteThreshold)
        internal
        view
        returns (bool isResolved, int256 price)
    {
        FixedPoint.Unsigned memory modeThreshold = FixedPoint.fromUnscaledUint(50).div(100);

        if (
            data.totalVotes.isGreaterThan(minVoteThreshold) &&
            data.voteFrequency[data.currentMode].div(data.totalVotes).isGreaterThan(modeThreshold)
        ) {
            // `modeThreshold` and `minVoteThreshold` are exceeded, so the current mode is the resolved price.
            isResolved = true;
            price = data.currentMode;
        } else {
            isResolved = false;
        }
    }

    /**
     * @notice Checks whether a `voteHash` is considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains information against which the `voteHash` is checked.
     * @param voteHash committed hash submitted by the voter.
     * @return bool true if the vote was correct.
     */
    function wasVoteCorrect(Data storage data, bytes32 voteHash) internal view returns (bool) {
        return voteHash == keccak256(abi.encode(data.currentMode));
    }

    /**
     * @notice Gets the total number of tokens whose votes are considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains all votes against which the correctly voted tokens are counted.
     * @return FixedPoint.Unsigned which indicates the frequency of the correctly voted tokens.
     */
    function getTotalCorrectlyVotedTokens(Data storage data) internal view returns (FixedPoint.Unsigned memory) {
        return data.voteFrequency[data.currentMode];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/VotingInterface.sol";

/**
 * @title Library to compute rounds and phases for an equal length commit-reveal voting cycle.
 */
library VoteTiming {
    using SafeMath for uint256;

    struct Data {
        uint256 phaseLength;
    }

    /**
     * @notice Initializes the data object. Sets the phase length based on the input.
     */
    function init(Data storage data, uint256 phaseLength) internal {
        // This should have a require message but this results in an internal Solidity error.
        require(phaseLength > 0);
        data.phaseLength = phaseLength;
    }

    /**
     * @notice Computes the roundID based off the current time as floor(timestamp/roundLength).
     * @dev The round ID depends on the global timestamp but not on the lifetime of the system.
     * The consequence is that the initial round ID starts at an arbitrary number (that increments, as expected, for subsequent rounds) instead of zero or one.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return roundId defined as a function of the currentTime and `phaseLength` from `data`.
     */
    function computeCurrentRoundId(Data storage data, uint256 currentTime) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength.mul(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return currentTime.div(roundLength);
    }

    /**
     * @notice compute the round end time as a function of the round Id.
     * @param data input data object.
     * @param roundId uniquely identifies the current round.
     * @return timestamp unix time of when the current round will end.
     */
    function computeRoundEndTime(Data storage data, uint256 roundId) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength.mul(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return roundLength.mul(roundId.add(1));
    }

    /**
     * @notice Computes the current phase based only on the current time.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return current voting phase based on current time and vote phases configuration.
     */
    function computeCurrentPhase(Data storage data, uint256 currentTime)
        internal
        view
        returns (VotingAncillaryInterface.Phase)
    {
        // This employs some hacky casting. We could make this an if-statement if we're worried about type safety.
        return
            VotingAncillaryInterface.Phase(
                currentTime.div(data.phaseLength).mod(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER))
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/VotingInterface.sol";
import "../interfaces/VotingAncillaryInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "./Registry.sol";
import "./ResultComputation.sol";
import "./VoteTiming.sol";
import "./VotingToken.sol";
import "./Constants.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Voting system for Oracle.
 * @dev Handles receiving and resolving price requests via a commit-reveal voting scheme.
 */
contract Voting is
    Testable,
    Ownable,
    OracleInterface,
    OracleAncillaryInterface, // Interface to support ancillary data with price requests.
    VotingInterface,
    VotingAncillaryInterface // Interface to support ancillary data with voting rounds.
{
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using VoteTiming for VoteTiming.Data;
    using ResultComputation for ResultComputation.Data;

    /****************************************
     *        VOTING DATA STRUCTURES        *
     ****************************************/

    // Identifies a unique price request for which the Oracle will always return the same value.
    // Tracks ongoing votes as well as the result of the vote.
    struct PriceRequest {
        bytes32 identifier;
        uint256 time;
        // A map containing all votes for this price in various rounds.
        mapping(uint256 => VoteInstance) voteInstances;
        // If in the past, this was the voting round where this price was resolved. If current or the upcoming round,
        // this is the voting round where this price will be voted on, but not necessarily resolved.
        uint256 lastVotingRound;
        // The index in the `pendingPriceRequests` that references this PriceRequest. A value of UINT_MAX means that
        // this PriceRequest is resolved and has been cleaned up from `pendingPriceRequests`.
        uint256 index;
        bytes ancillaryData;
    }

    struct VoteInstance {
        // Maps (voterAddress) to their submission.
        mapping(address => VoteSubmission) voteSubmissions;
        // The data structure containing the computed voting results.
        ResultComputation.Data resultComputation;
    }

    struct VoteSubmission {
        // A bytes32 of `0` indicates no commit or a commit that was already revealed.
        bytes32 commit;
        // The hash of the value that was revealed.
        // Note: this is only used for computation of rewards.
        bytes32 revealHash;
    }

    struct Round {
        uint256 snapshotId; // Voting token snapshot ID for this round.  0 if no snapshot has been taken.
        FixedPoint.Unsigned inflationRate; // Inflation rate set for this round.
        FixedPoint.Unsigned gatPercentage; // Gat rate set for this round.
        uint256 rewardsExpirationTime; // Time that rewards for this round can be claimed until.
    }

    // Represents the status a price request has.
    enum RequestStatus {
        NotRequested, // Was never requested.
        Active, // Is being voted on in the current round.
        Resolved, // Was resolved in a previous round.
        Future // Is scheduled to be voted on in a future round.
    }

    // Only used as a return value in view methods -- never stored in the contract.
    struct RequestState {
        RequestStatus status;
        uint256 lastVotingRound;
    }

    /****************************************
     *          INTERNAL TRACKING           *
     ****************************************/

    // Maps round numbers to the rounds.
    mapping(uint256 => Round) public rounds;

    // Maps price request IDs to the PriceRequest struct.
    mapping(bytes32 => PriceRequest) private priceRequests;

    // Price request ids for price requests that haven't yet been marked as resolved.
    // These requests may be for future rounds.
    bytes32[] internal pendingPriceRequests;

    VoteTiming.Data public voteTiming;

    // Percentage of the total token supply that must be used in a vote to
    // create a valid price resolution. 1 == 100%.
    FixedPoint.Unsigned public gatPercentage;

    // Global setting for the rate of inflation per vote. This is the percentage of the snapshotted total supply that
    // should be split among the correct voters.
    // Note: this value is used to set per-round inflation at the beginning of each round. 1 = 100%.
    FixedPoint.Unsigned public inflationRate;

    // Time in seconds from the end of the round in which a price request is
    // resolved that voters can still claim their rewards.
    uint256 public rewardsExpirationTimeout;

    // Reference to the voting token.
    VotingToken public votingToken;

    // Reference to the Finder.
    FinderInterface private finder;

    // If non-zero, this contract has been migrated to this address. All voters and
    // financial contracts should query the new address only.
    address public migratedAddress;

    // Max value of an unsigned integer.
    uint256 private constant UINT_MAX = ~uint256(0);

    // Max length in bytes of ancillary data that can be appended to a price request.
    // As of December 2020, the current Ethereum gas limit is 12.5 million. This requestPrice function's gas primarily
    // comes from computing a Keccak-256 hash in _encodePriceRequest and writing a new PriceRequest to
    // storage. We have empirically determined an ancillary data limit of 8192 bytes that keeps this function
    // well within the gas limit at ~8 million gas. To learn more about the gas limit and EVM opcode costs go here:
    // - https://etherscan.io/chart/gaslimit
    // - https://github.com/djrtwo/evm-opcode-gas-costs
    uint256 public constant ancillaryBytesLimit = 8192;

    bytes32 public snapshotMessageHash = ECDSA.toEthSignedMessageHash(keccak256(bytes("Sign For Snapshot")));

    /***************************************
     *                EVENTS                *
     ****************************************/

    event VoteCommitted(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );

    event EncryptedVote(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );

    event VoteRevealed(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData,
        uint256 numTokens
    );

    event RewardsRetrieved(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        uint256 numTokens
    );

    event PriceRequestAdded(uint256 indexed roundId, bytes32 indexed identifier, uint256 time);

    event PriceResolved(
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData
    );

    /**
     * @notice Construct the Voting contract.
     * @param _phaseLength length of the commit and reveal phases in seconds.
     * @param _gatPercentage of the total token supply that must be used in a vote to create a valid price resolution.
     * @param _inflationRate percentage inflation per round used to increase token supply of correct voters.
     * @param _rewardsExpirationTimeout timeout, in seconds, within which rewards must be claimed.
     * @param _votingToken address of the UMA token contract used to commit votes.
     * @param _finder keeps track of all contracts within the system based on their interfaceName.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        uint256 _phaseLength,
        FixedPoint.Unsigned memory _gatPercentage,
        FixedPoint.Unsigned memory _inflationRate,
        uint256 _rewardsExpirationTimeout,
        address _votingToken,
        address _finder,
        address _timerAddress
    ) Testable(_timerAddress) {
        voteTiming.init(_phaseLength);
        require(_gatPercentage.isLessThanOrEqual(1), "GAT percentage must be <= 100%");
        gatPercentage = _gatPercentage;
        inflationRate = _inflationRate;
        votingToken = VotingToken(_votingToken);
        finder = FinderInterface(_finder);
        rewardsExpirationTimeout = _rewardsExpirationTimeout;
    }

    /***************************************
                    MODIFIERS
    ****************************************/

    modifier onlyRegisteredContract() {
        if (migratedAddress != address(0)) {
            require(msg.sender == migratedAddress, "Caller must be migrated address");
        } else {
            Registry registry = Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
            require(registry.isContractRegistered(msg.sender), "Called must be registered");
        }
        _;
    }

    modifier onlyIfNotMigrated() {
        require(migratedAddress == address(0), "Only call this if not migrated");
        _;
    }

    /****************************************
     *  PRICE REQUEST AND ACCESS FUNCTIONS  *
     ****************************************/

    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported. The length of the ancillary data
     * is limited such that this method abides by the EVM transaction gas limit.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     */
    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override onlyRegisteredContract() {
        uint256 blockTime = getCurrentTime();
        require(time <= blockTime, "Can only request in past");
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier), "Unsupported identifier request");
        require(ancillaryData.length <= ancillaryBytesLimit, "Invalid ancillary data");

        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        PriceRequest storage priceRequest = priceRequests[priceRequestId];
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        RequestStatus requestStatus = _getRequestStatus(priceRequest, currentRoundId);

        if (requestStatus == RequestStatus.NotRequested) {
            // Price has never been requested.
            // Price requests always go in the next round, so add 1 to the computed current round.
            uint256 nextRoundId = currentRoundId.add(1);

            PriceRequest storage newPriceRequest = priceRequests[priceRequestId];
            newPriceRequest.identifier = identifier;
            newPriceRequest.time = time;
            newPriceRequest.lastVotingRound = nextRoundId;
            newPriceRequest.index = pendingPriceRequests.length;
            newPriceRequest.ancillaryData = ancillaryData;

            pendingPriceRequests.push(priceRequestId);
            emit PriceRequestAdded(nextRoundId, identifier, time);
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function requestPrice(bytes32 identifier, uint256 time) public override {
        requestPrice(identifier, time, "");
    }

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return _hasPrice bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (bool) {
        (bool _hasPrice, , ) = _getPriceOrError(identifier, time, ancillaryData);
        return _hasPrice;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function hasPrice(bytes32 identifier, uint256 time) public view override returns (bool) {
        return hasPrice(identifier, time, "");
    }

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (int256) {
        (bool _hasPrice, int256 price, string memory message) = _getPriceOrError(identifier, time, ancillaryData);

        // If the price wasn't available, revert with the provided message.
        require(_hasPrice, message);
        return price;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function getPrice(bytes32 identifier, uint256 time) public view override returns (int256) {
        return getPrice(identifier, time, "");
    }

    /**
     * @notice Gets the status of a list of price requests, identified by their identifier and time.
     * @dev If the status for a particular request is NotRequested, the lastVotingRound will always be 0.
     * @param requests array of type PendingRequest which includes an identifier and timestamp for each request.
     * @return requestStates a list, in the same order as the input list, giving the status of each of the specified price requests.
     */
    function getPriceRequestStatuses(PendingRequestAncillary[] memory requests)
        public
        view
        returns (RequestState[] memory)
    {
        RequestState[] memory requestStates = new RequestState[](requests.length);
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());
        for (uint256 i = 0; i < requests.length; i++) {
            PriceRequest storage priceRequest =
                _getPriceRequest(requests[i].identifier, requests[i].time, requests[i].ancillaryData);

            RequestStatus status = _getRequestStatus(priceRequest, currentRoundId);

            // If it's an active request, its true lastVotingRound is the current one, even if it hasn't been updated.
            if (status == RequestStatus.Active) {
                requestStates[i].lastVotingRound = currentRoundId;
            } else {
                requestStates[i].lastVotingRound = priceRequest.lastVotingRound;
            }
            requestStates[i].status = status;
        }
        return requestStates;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function getPriceRequestStatuses(PendingRequest[] memory requests) public view returns (RequestState[] memory) {
        PendingRequestAncillary[] memory requestsAncillary = new PendingRequestAncillary[](requests.length);

        for (uint256 i = 0; i < requests.length; i++) {
            requestsAncillary[i].identifier = requests[i].identifier;
            requestsAncillary[i].time = requests[i].time;
            requestsAncillary[i].ancillaryData = "";
        }
        return getPriceRequestStatuses(requestsAncillary);
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public override onlyIfNotMigrated() {
        require(hash != bytes32(0), "Invalid provided hash");
        // Current time is required for all vote timing queries.
        uint256 blockTime = getCurrentTime();
        require(
            voteTiming.computeCurrentPhase(blockTime) == VotingAncillaryInterface.Phase.Commit,
            "Cannot commit in reveal phase"
        );

        // At this point, the computed and last updated round ID should be equal.
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        require(
            _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active,
            "Cannot commit inactive request"
        );

        priceRequest.lastVotingRound = currentRoundId;
        VoteInstance storage voteInstance = priceRequest.voteInstances[currentRoundId];
        voteInstance.voteSubmissions[msg.sender].commit = hash;

        emit VoteCommitted(msg.sender, currentRoundId, identifier, time, ancillaryData);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash
    ) public override onlyIfNotMigrated() {
        commitVote(identifier, time, "", hash);
    }

    /**
     * @notice Snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times, but only the first call per round into this function or `revealVote`
     * will create the round snapshot. Any later calls will be a no-op. Will revert unless called during reveal period.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature)
        external
        override(VotingInterface, VotingAncillaryInterface)
        onlyIfNotMigrated()
    {
        uint256 blockTime = getCurrentTime();
        require(voteTiming.computeCurrentPhase(blockTime) == Phase.Reveal, "Only snapshot in reveal phase");
        // Require public snapshot require signature to ensure caller is an EOA.
        require(ECDSA.recover(snapshotMessageHash, signature) == msg.sender, "Signature must match sender");
        uint256 roundId = voteTiming.computeCurrentRoundId(blockTime);
        _freezeRoundVariables(roundId);
    }

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price being voted on.
     * @param price voted on during the commit phase.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public override onlyIfNotMigrated() {
        require(voteTiming.computeCurrentPhase(getCurrentTime()) == Phase.Reveal, "Cannot reveal in commit phase");
        // Note: computing the current round is required to disallow people from revealing an old commit after the round is over.
        uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());

        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        VoteInstance storage voteInstance = priceRequest.voteInstances[roundId];
        VoteSubmission storage voteSubmission = voteInstance.voteSubmissions[msg.sender];

        // Scoping to get rid of a stack too deep error.
        {
            // 0 hashes are disallowed in the commit phase, so they indicate a different error.
            // Cannot reveal an uncommitted or previously revealed hash
            require(voteSubmission.commit != bytes32(0), "Invalid hash reveal");
            require(
                keccak256(abi.encodePacked(price, salt, msg.sender, time, ancillaryData, roundId, identifier)) ==
                    voteSubmission.commit,
                "Revealed data != commit hash"
            );
            // To protect against flash loans, we require snapshot be validated as EOA.
            require(rounds[roundId].snapshotId != 0, "Round has no snapshot");
        }

        // Get the frozen snapshotId
        uint256 snapshotId = rounds[roundId].snapshotId;

        delete voteSubmission.commit;

        // Get the voter's snapshotted balance. Since balances are returned pre-scaled by 10**18, we can directly
        // initialize the Unsigned value with the returned uint.
        FixedPoint.Unsigned memory balance = FixedPoint.Unsigned(votingToken.balanceOfAt(msg.sender, snapshotId));

        // Set the voter's submission.
        voteSubmission.revealHash = keccak256(abi.encode(price));

        // Add vote to the results.
        voteInstance.resultComputation.addVote(price, balance);

        emit VoteRevealed(msg.sender, roundId, identifier, time, price, ancillaryData, balance.rawValue);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        int256 salt
    ) public override {
        revealVote(identifier, time, price, "", salt);
    }

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public override {
        commitVote(identifier, time, ancillaryData, hash);

        uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());
        emit EncryptedVote(msg.sender, roundId, identifier, time, ancillaryData, encryptedVote);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash,
        bytes memory encryptedVote
    ) public override {
        commitVote(identifier, time, "", hash);

        commitAndEmitEncryptedVote(identifier, time, "", hash, encryptedVote);
    }

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is emitted in an event.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits struct to encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(CommitmentAncillary[] memory commits) public override {
        for (uint256 i = 0; i < commits.length; i++) {
            if (commits[i].encryptedVote.length == 0) {
                commitVote(commits[i].identifier, commits[i].time, commits[i].ancillaryData, commits[i].hash);
            } else {
                commitAndEmitEncryptedVote(
                    commits[i].identifier,
                    commits[i].time,
                    commits[i].ancillaryData,
                    commits[i].hash,
                    commits[i].encryptedVote
                );
            }
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function batchCommit(Commitment[] memory commits) public override {
        CommitmentAncillary[] memory commitsAncillary = new CommitmentAncillary[](commits.length);

        for (uint256 i = 0; i < commits.length; i++) {
            commitsAncillary[i].identifier = commits[i].identifier;
            commitsAncillary[i].time = commits[i].time;
            commitsAncillary[i].ancillaryData = "";
            commitsAncillary[i].hash = commits[i].hash;
            commitsAncillary[i].encryptedVote = commits[i].encryptedVote;
        }
        batchCommit(commitsAncillary);
    }

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more info on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(RevealAncillary[] memory reveals) public override {
        for (uint256 i = 0; i < reveals.length; i++) {
            revealVote(
                reveals[i].identifier,
                reveals[i].time,
                reveals[i].price,
                reveals[i].ancillaryData,
                reveals[i].salt
            );
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function batchReveal(Reveal[] memory reveals) public override {
        RevealAncillary[] memory revealsAncillary = new RevealAncillary[](reveals.length);

        for (uint256 i = 0; i < reveals.length; i++) {
            revealsAncillary[i].identifier = reveals[i].identifier;
            revealsAncillary[i].time = reveals[i].time;
            revealsAncillary[i].price = reveals[i].price;
            revealsAncillary[i].ancillaryData = "";
            revealsAncillary[i].salt = reveals[i].salt;
        }
        batchReveal(revealsAncillary);
    }

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the call is done within the timeout threshold
     * (not expired). Note that a named return value is used here to avoid a stack to deep error.
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return totalRewardToIssue total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) public override returns (FixedPoint.Unsigned memory totalRewardToIssue) {
        if (migratedAddress != address(0)) {
            require(msg.sender == migratedAddress, "Can only call from migrated");
        }
        require(roundId < voteTiming.computeCurrentRoundId(getCurrentTime()), "Invalid roundId");

        Round storage round = rounds[roundId];
        bool isExpired = getCurrentTime() > round.rewardsExpirationTime;
        FixedPoint.Unsigned memory snapshotBalance =
            FixedPoint.Unsigned(votingToken.balanceOfAt(voterAddress, round.snapshotId));

        // Compute the total amount of reward that will be issued for each of the votes in the round.
        FixedPoint.Unsigned memory snapshotTotalSupply =
            FixedPoint.Unsigned(votingToken.totalSupplyAt(round.snapshotId));
        FixedPoint.Unsigned memory totalRewardPerVote = round.inflationRate.mul(snapshotTotalSupply);

        // Keep track of the voter's accumulated token reward.
        totalRewardToIssue = FixedPoint.Unsigned(0);

        for (uint256 i = 0; i < toRetrieve.length; i++) {
            PriceRequest storage priceRequest =
                _getPriceRequest(toRetrieve[i].identifier, toRetrieve[i].time, toRetrieve[i].ancillaryData);
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            // Only retrieve rewards for votes resolved in same round
            require(priceRequest.lastVotingRound == roundId, "Retrieve for votes same round");

            _resolvePriceRequest(priceRequest, voteInstance);

            if (voteInstance.voteSubmissions[voterAddress].revealHash == 0) {
                continue;
            } else if (isExpired) {
                // Emit a 0 token retrieval on expired rewards.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    0
                );
            } else if (
                voteInstance.resultComputation.wasVoteCorrect(voteInstance.voteSubmissions[voterAddress].revealHash)
            ) {
                // The price was successfully resolved during the voter's last voting round, the voter revealed
                // and was correct, so they are eligible for a reward.
                // Compute the reward and add to the cumulative reward.

                FixedPoint.Unsigned memory reward =
                    snapshotBalance.mul(totalRewardPerVote).div(
                        voteInstance.resultComputation.getTotalCorrectlyVotedTokens()
                    );
                totalRewardToIssue = totalRewardToIssue.add(reward);

                // Emit reward retrieval for this vote.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    reward.rawValue
                );
            } else {
                // Emit a 0 token retrieval on incorrect votes.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    0
                );
            }

            // Delete the submission to capture any refund and clean up storage.
            delete voteInstance.voteSubmissions[voterAddress].revealHash;
        }

        // Issue any accumulated rewards.
        if (totalRewardToIssue.isGreaterThan(0)) {
            require(votingToken.mint(voterAddress, totalRewardToIssue.rawValue), "Voting token issuance failed");
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequest[] memory toRetrieve
    ) public override returns (FixedPoint.Unsigned memory) {
        PendingRequestAncillary[] memory toRetrieveAncillary = new PendingRequestAncillary[](toRetrieve.length);

        for (uint256 i = 0; i < toRetrieve.length; i++) {
            toRetrieveAncillary[i].identifier = toRetrieve[i].identifier;
            toRetrieveAncillary[i].time = toRetrieve[i].time;
            toRetrieveAncillary[i].ancillaryData = "";
        }

        return retrieveRewards(voterAddress, roundId, toRetrieveAncillary);
    }

    /****************************************
     *        VOTING GETTER FUNCTIONS       *
     ****************************************/

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests array containing identifiers of type `PendingRequest`.
     * and timestamps for all pending requests.
     */
    function getPendingRequests()
        external
        view
        override(VotingInterface, VotingAncillaryInterface)
        returns (PendingRequestAncillary[] memory)
    {
        uint256 blockTime = getCurrentTime();
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        // Solidity memory arrays aren't resizable (and reading storage is expensive). Hence this hackery to filter
        // `pendingPriceRequests` only to those requests that have an Active RequestStatus.
        PendingRequestAncillary[] memory unresolved = new PendingRequestAncillary[](pendingPriceRequests.length);
        uint256 numUnresolved = 0;

        for (uint256 i = 0; i < pendingPriceRequests.length; i++) {
            PriceRequest storage priceRequest = priceRequests[pendingPriceRequests[i]];
            if (_getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active) {
                unresolved[numUnresolved] = PendingRequestAncillary({
                    identifier: priceRequest.identifier,
                    time: priceRequest.time,
                    ancillaryData: priceRequest.ancillaryData
                });
                numUnresolved++;
            }
        }

        PendingRequestAncillary[] memory pendingRequests = new PendingRequestAncillary[](numUnresolved);
        for (uint256 i = 0; i < numUnresolved; i++) {
            pendingRequests[i] = unresolved[i];
        }
        return pendingRequests;
    }

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view override(VotingInterface, VotingAncillaryInterface) returns (Phase) {
        return voteTiming.computeCurrentPhase(getCurrentTime());
    }

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view override(VotingInterface, VotingAncillaryInterface) returns (uint256) {
        return voteTiming.computeCurrentRoundId(getCurrentTime());
    }

    /****************************************
     *        OWNER ADMIN FUNCTIONS         *
     ****************************************/

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress)
        external
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        migratedAddress = newVotingAddress;
    }

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        inflationRate = newInflationRate;
    }

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        require(newGatPercentage.isLessThan(1), "GAT percentage must be < 100%");
        gatPercentage = newGatPercentage;
    }

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        rewardsExpirationTimeout = NewRewardsExpirationTimeout;
    }

    /****************************************
     *    PRIVATE AND INTERNAL FUNCTIONS    *
     ****************************************/

    // Returns the price for a given identifer. Three params are returns: bool if there was an error, int to represent
    // the resolved price and a string which is filled with an error message, if there was an error or "".
    function _getPriceOrError(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    )
        private
        view
        returns (
            bool,
            int256,
            string memory
        )
    {
        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());

        RequestStatus requestStatus = _getRequestStatus(priceRequest, currentRoundId);
        if (requestStatus == RequestStatus.Active) {
            return (false, 0, "Current voting round not ended");
        } else if (requestStatus == RequestStatus.Resolved) {
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (, int256 resolvedPrice) =
                voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
            return (true, resolvedPrice, "");
        } else if (requestStatus == RequestStatus.Future) {
            return (false, 0, "Price is still to be voted on");
        } else {
            return (false, 0, "Price was never requested");
        }
    }

    function _getPriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private view returns (PriceRequest storage) {
        return priceRequests[_encodePriceRequest(identifier, time, ancillaryData)];
    }

    function _encodePriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(identifier, time, ancillaryData));
    }

    function _freezeRoundVariables(uint256 roundId) private {
        Round storage round = rounds[roundId];
        // Only on the first reveal should the snapshot be captured for that round.
        if (round.snapshotId == 0) {
            // There is no snapshot ID set, so create one.
            round.snapshotId = votingToken.snapshot();

            // Set the round inflation rate to the current global inflation rate.
            rounds[roundId].inflationRate = inflationRate;

            // Set the round gat percentage to the current global gat rate.
            rounds[roundId].gatPercentage = gatPercentage;

            // Set the rewards expiration time based on end of time of this round and the current global timeout.
            rounds[roundId].rewardsExpirationTime = voteTiming.computeRoundEndTime(roundId).add(
                rewardsExpirationTimeout
            );
        }
    }

    function _resolvePriceRequest(PriceRequest storage priceRequest, VoteInstance storage voteInstance) private {
        if (priceRequest.index == UINT_MAX) {
            return;
        }
        (bool isResolved, int256 resolvedPrice) =
            voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
        require(isResolved, "Can't resolve unresolved request");

        // Delete the resolved price request from pendingPriceRequests.
        uint256 lastIndex = pendingPriceRequests.length - 1;
        PriceRequest storage lastPriceRequest = priceRequests[pendingPriceRequests[lastIndex]];
        lastPriceRequest.index = priceRequest.index;
        pendingPriceRequests[priceRequest.index] = pendingPriceRequests[lastIndex];
        pendingPriceRequests.pop();

        priceRequest.index = UINT_MAX;
        emit PriceResolved(
            priceRequest.lastVotingRound,
            priceRequest.identifier,
            priceRequest.time,
            resolvedPrice,
            priceRequest.ancillaryData
        );
    }

    function _computeGat(uint256 roundId) private view returns (FixedPoint.Unsigned memory) {
        uint256 snapshotId = rounds[roundId].snapshotId;
        if (snapshotId == 0) {
            // No snapshot - return max value to err on the side of caution.
            return FixedPoint.Unsigned(UINT_MAX);
        }

        // Grab the snapshotted supply from the voting token. It's already scaled by 10**18, so we can directly
        // initialize the Unsigned value with the returned uint.
        FixedPoint.Unsigned memory snapshottedSupply = FixedPoint.Unsigned(votingToken.totalSupplyAt(snapshotId));

        // Multiply the total supply at the snapshot by the gatPercentage to get the GAT in number of tokens.
        return snapshottedSupply.mul(rounds[roundId].gatPercentage);
    }

    function _getRequestStatus(PriceRequest storage priceRequest, uint256 currentRoundId)
        private
        view
        returns (RequestStatus)
    {
        if (priceRequest.lastVotingRound == 0) {
            return RequestStatus.NotRequested;
        } else if (priceRequest.lastVotingRound < currentRoundId) {
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (bool isResolved, ) =
                voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
            return isResolved ? RequestStatus.Resolved : RequestStatus.Active;
        } else if (priceRequest.lastVotingRound == currentRoundId) {
            return RequestStatus.Active;
        } else {
            // Means than priceRequest.lastVotingRound > currentRoundId
            return RequestStatus.Future;
        }
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/ExpandedERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/**
 * @title Ownership of this token allows a voter to respond to price requests.
 * @dev Supports snapshotting and allows the Oracle to mint new tokens as rewards.
 */
contract VotingToken is ExpandedERC20, ERC20Snapshot {
    /**
     * @notice Constructs the VotingToken.
     */
    constructor() ExpandedERC20("UMA Voting Token v1", "UMA", 18) ERC20Snapshot() {}

    function decimals() public view virtual override(ERC20, ExpandedERC20) returns (uint8) {
        return super.decimals();
    }

    /**
     * @notice Creates a new snapshot ID.
     * @return uint256 Thew new snapshot ID.
     */
    function snapshot() external returns (uint256) {
        return _snapshot();
    }

    // _transfer, _mint and _burn are ERC20 internal methods that are overridden by ERC20Snapshot,
    // therefore the compiler will complain that VotingToken must override these methods
    // because the two base classes (ERC20 and ERC20Snapshot) both define the same functions

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal virtual override(ERC20) {
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal virtual override(ERC20) {
        super._burn(account, value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for a registry of contracts and contract creators.
 */
interface RegistryInterface {
    /**
     * @notice Registers a new contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties an array of addresses who become parties in the contract.
     * @param contractAddress defines the address of the deployed contract.
     */
    function registerContract(address[] calldata parties, address contractAddress) external;

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view returns (bool);

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view returns (address[] memory);

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view returns (address[] memory);

    /**
     * @notice Adds a party to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be added to the contract.
     */
    function addPartyToContract(address party) external;

    /**
     * @notice Removes a party member to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be removed from the contract.
     */
    function removePartyFromContract(address party) external;

    /**
     * @notice checks if an address is a party in a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingAncillaryInterface {
    struct PendingRequestAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct CommitmentAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct RevealAncillary {
        bytes32 identifier;
        uint256 time;
        int256 price;
        bytes ancillaryData;
        int256 salt;
    }

    // Note: the phases must be in order. Meaning the first enum value must be the first phase, etc.
    // `NUM_PHASES_PLACEHOLDER` is to get the number of phases. It isn't an actual phase, and it should always be last.
    enum Phase { Commit, Reveal, NUM_PHASES_PLACEHOLDER }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(CommitmentAncillary[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(RevealAncillary[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests() external view virtual returns (PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view virtual returns (Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";
import "./VotingAncillaryInterface.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingInterface {
    struct PendingRequest {
        bytes32 identifier;
        uint256 time;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct Commitment {
        bytes32 identifier;
        uint256 time;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct Reveal {
        bytes32 identifier;
        uint256 time;
        int256 price;
        int256 salt;
    }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash
    ) external virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(Commitment[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(Reveal[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests()
        external
        view
        virtual
        returns (VotingAncillaryInterface.PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view virtual returns (VotingAncillaryInterface.Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequest[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}
/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: Unlicense
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity ^0.8.10;

interface IYielder {
    function ownerOf(uint256 _tokenId) external view returns(address);
}

interface IBooster {
    function computeAmount(uint256 amount) external view returns(uint256);
    function computeAmounts(uint256[] calldata amounts, uint256[] calldata yieldingCores, uint256[] calldata tokens) external view returns(uint256);
}

contract HumansOfTheMetaverseToken is ERC20("Hotm", "HOT"), Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    struct YielderSettings {
        uint256 _defaultYieldRate; // fallback for yieldingCoresAmount absence
        uint256 _startTime;
        uint256 _endTime;
        uint256 _timeRate;
        mapping(uint256 => uint256) _tokenYieldingCoresMapping; // tokenId => yieldingCoreId (i.e. job)
        mapping(uint256 => uint256) _yieldingCoresAmountMapping; // yieldingCoreId => amount
        mapping(uint256 => uint256) _lastClaim; // tokenId => date
    }

    struct BoosterSettings {
        address _appliesFor; // yielder
        bool _status;
        EnumerableSet.UintSet _yieldingCores;
        mapping(uint256 => uint256) _boosterStartDates; // tokenId => boosterStartDate
    }

    mapping(address => YielderSettings) yielders;

    mapping(address => BoosterSettings) boosters;

    address[] public boostersAddresses; // boosters should be iterable

    mapping(address => mapping(address => EnumerableSet.UintSet)) tokensOwnerShip; // map econtract addrss => map owner address => yieldingToken

    uint256 allowedPublicTokensMinted = 31207865 ether; // max total supply * 0.6

    constructor() {
        _pause();
    }

    // YIELDERS

    // TODO nu exista listener care sa updateze booster enrolment

    function setYielderSettings(
        uint256 _defaultYieldRate,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _timeRate,
        address _yielderAddress
    ) external onlyOwner {
        YielderSettings storage yielderSettings =  yielders[_yielderAddress];

        yielderSettings._defaultYieldRate = _defaultYieldRate;
        yielderSettings._startTime = _startTime;
        yielderSettings._endTime = _endTime;
        yielderSettings._timeRate = _timeRate;
    }

    function setEndDateForYielder(uint256 _endTime, address _contract) external onlyOwner {
        YielderSettings storage yielderSettings = getYielderSettings(_contract);
        yielderSettings._endTime = _endTime;
    }

    function setStartDateForYielder(uint256 _startTime, address _contract) external onlyOwner {
        YielderSettings storage yielderSettings = getYielderSettings(_contract);
        yielderSettings._startTime = _startTime;
    }

    function setDefaultYieldRateForYielder(uint256 _defaultYieldRate, address _contract) external onlyOwner {
        YielderSettings storage yielderSettings = getYielderSettings(_contract);
        yielderSettings._defaultYieldRate = _defaultYieldRate;
    }

    function setTimeRateForYielder(uint256 _timeRate, address _contract) external onlyOwner {
        YielderSettings storage yielderSettings = getYielderSettings(_contract);
        yielderSettings._timeRate = _timeRate;
    }

    function setYieldingAmountMapping(
        address _yielderAddress,
        uint256[] calldata _yieldingCores,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_amounts.length == _yieldingCores.length, "Provided arrays should have the same length");

        YielderSettings storage yielderSettings = getYielderSettings(_yielderAddress);

        for(uint256 i = 0; i < _yieldingCores.length; ++i) {
            yielderSettings._yieldingCoresAmountMapping[_yieldingCores[i]] = _amounts[i];
        }
    }

    function setTokenYielderMapping(
        address _yielderAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _yieldingCores
    ) external onlyOwner {
        require(_tokenIds.length == _yieldingCores.length, "Provided arrays should have the same length");

        YielderSettings storage yielderSettings = getYielderSettings(_yielderAddress);

        for(uint256 i = 0; i < _tokenIds.length; ++i) {
            yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]] = _yieldingCores[i];
        }
    }

    function getYielderSettings(address _address) internal view returns (YielderSettings storage) {
        YielderSettings storage yielderSettings = yielders[_address];
        require(yielderSettings._startTime != uint256(0), "There is no yielder with provided address");

        return yielderSettings;
    }

    // BOOSTERS

    function setBoosterConfiguration(
        address _appliesFor,
        bool _status,
        address _boosterAddress
    ) external onlyOwner {
        boostersAddresses.push(_boosterAddress);
        BoosterSettings storage boosterSettings = boosters[_boosterAddress];
        boosterSettings._appliesFor=  _appliesFor;
        boosterSettings._status = _status;
    }

    function setBoosterStatus(address _boosterAddress, bool _status) external onlyOwner {
        BoosterSettings storage boosterSettings = getBoosterSettings(_boosterAddress);
        boosterSettings._status = _status;
    }

    function setBoosterAppliesFor(address _boosterAddress, address _appliesFor) external onlyOwner{
        BoosterSettings storage boosterSettings = getBoosterSettings(_boosterAddress);
        boosterSettings._appliesFor = _appliesFor;
    }

    function setBoosterCores(address _boosterAddress, uint256[] calldata _yieldingCoresIds) external onlyOwner {
        BoosterSettings storage boosterSettings = getBoosterSettings(_boosterAddress);
        for (uint256 i = 0; i < _yieldingCoresIds.length; ++i) {
            boosterSettings._yieldingCores.add(_yieldingCoresIds[i]);
        }
    }

    function replaceBoosterCores(address _boosterAddress, uint256[] calldata _yieldingCoresIds) external onlyOwner {
        BoosterSettings storage boosterSettings = getBoosterSettings(_boosterAddress);

        for (uint256 i = 0; i < boosterSettings._yieldingCores.length(); ++i) {
            boosterSettings._yieldingCores.remove(boosterSettings._yieldingCores.at(i));
        }

        for (uint256 i = 0; i < _yieldingCoresIds.length; ++i) {
            boosterSettings._yieldingCores.add(_yieldingCoresIds[i]);
        }
    }

    function getBoosterSettings(address _address) internal view returns (BoosterSettings storage) {
        BoosterSettings storage boosterSettings = boosters[_address];
        require(boosterSettings._appliesFor != address(0), "There is no yielder with provided address");

        return boosterSettings;
    }

    // claim logic

    function claimRewards(
        address _contractAddress,
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant() returns (uint256) {
        YielderSettings storage yielderSettings = getYielderSettings(_contractAddress);

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            processTokenOwnerShip(_contractAddress, _tokenId);
        }

        uint256 totalUnclaimedRewards = computeUnclaimedRewardsAndUpdate(yielderSettings, _contractAddress, _tokenIds);

        claimTokens(totalUnclaimedRewards);

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (block.timestamp > yielderSettings._endTime) {
                yielderSettings._lastClaim[_tokenId] = yielderSettings._endTime;
            } else {
                yielderSettings._lastClaim[_tokenId] = block.timestamp;
            }
        }

        return totalUnclaimedRewards;
    }

    function checkClaimableAmount(address _contractAddress, uint256[] calldata _tokenIds) view external whenNotPaused returns(uint256) {
        YielderSettings storage yielderSettings = getYielderSettings(_contractAddress);

        uint256 totalUnclaimedRewards = computeUnclaimedRewardsSafe(yielderSettings, _contractAddress, _tokenIds);

        return totalUnclaimedRewards;
    }

    function computeUnclaimedRewardsAndUpdate(
        YielderSettings storage _yielderSettings,
        address _yielderAddress,
        uint256[] calldata _tokenIds
    ) internal returns (uint256) {
        uint256 totalReward = 0;

        totalReward += computeBaseAccumulatedRewards(_yielderSettings, _tokenIds);
        totalReward += computeBoostersAccumulatedRewardsAndUpdate(_yielderAddress, _yielderSettings, _tokenIds);

        return totalReward;
    }

    function computeUnclaimedRewardsSafe(
        YielderSettings storage _yielderSettings,
        address _yielderAddress,
        uint256[] calldata _tokenIds
    ) internal view returns (uint256) {
        uint256 totalReward = 0;

        totalReward += computeBaseAccumulatedRewards(_yielderSettings, _tokenIds);
        totalReward += computeBoostersAccumulatedRewardsSafe(_yielderAddress, _yielderSettings, _tokenIds);

        return totalReward;
    }

    function computeBaseAccumulatedRewards(YielderSettings storage _yielderSettings, uint256[] calldata _tokenIds) internal view returns (uint256) {
        uint256 baseAccumulatedRewards = 0;

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 lastClaimDate = getLastClaimForYielder(_yielderSettings, _tokenIds[i]);

            if (lastClaimDate != _yielderSettings._endTime) {
                uint256 secondsElapsed = block.timestamp - lastClaimDate;
                if (_yielderSettings._defaultYieldRate != uint256(0)) {
                    baseAccumulatedRewards += secondsElapsed * _yielderSettings._defaultYieldRate / _yielderSettings._timeRate;
                } else {
                    baseAccumulatedRewards +=
                    secondsElapsed * _yielderSettings._yieldingCoresAmountMapping[_yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]]] / _yielderSettings._timeRate;
                }
            }
        }

        return baseAccumulatedRewards;
    }

    function computeBoostersAccumulatedRewardsAndUpdate(
        address _yielderAddress,
        YielderSettings storage _yielderSettings,
        uint256[] calldata _tokenIds
    ) internal returns (uint256) {

        uint256 boosterAccumulatedRewards = 0;

        for (uint256 boosterIndex = 0; boosterIndex < boostersAddresses.length; ++boosterIndex) {
            BoosterSettings storage boosterSettings = getBoosterSettings(boostersAddresses[boosterIndex]);
            uint256 toBeSentArraysIndex = 0;
            uint256[] memory accumulatedRewardsForBooster = new uint256[](_tokenIds.length);
            uint256[] memory validTokensCandidates = new uint256[](_tokenIds.length);

            if (boosterSettings._appliesFor == _yielderAddress && boosterSettings._status) {
                for (uint256 i = 0; i < _tokenIds.length; ++i) {
                    uint256 lastClaimDate = getLastClaimForBooster(boosterSettings, _tokenIds[i]);
                    if (
                        (
                            boosterSettings._yieldingCores.length() == 0
                            || boosterSettings._yieldingCores.contains(_yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]])
                        ) && _yielderSettings._lastClaim[_tokenIds[i]] != _yielderSettings._endTime
                          && lastClaimDate != uint256(0)
                    ) {

                        uint256 secondsElapsed = block.timestamp - lastClaimDate;

                        if (_yielderSettings._defaultYieldRate != uint256(0)) {
                            accumulatedRewardsForBooster[toBeSentArraysIndex] = secondsElapsed * _yielderSettings._defaultYieldRate / _yielderSettings._timeRate;
                        } else {
                            uint256 tokenYieldingCoresMapping = _yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]];
                            uint256 yieldingCoresAmountMapping = _yielderSettings._yieldingCoresAmountMapping[tokenYieldingCoresMapping];
                            accumulatedRewardsForBooster[toBeSentArraysIndex] =
                            secondsElapsed * yieldingCoresAmountMapping / _yielderSettings._timeRate;
                        }
                        validTokensCandidates[toBeSentArraysIndex] = _tokenIds[i];
                        toBeSentArraysIndex++;
                    }
                }
                if (boosterSettings._yieldingCores.length() != 0) {
                    uint256[] memory yieldingCores = new uint256[](validTokensCandidates.length);

                    for (uint256 i = 0; i < validTokensCandidates.length; ++i) {
                        yieldingCores[i] = _yielderSettings._tokenYieldingCoresMapping[validTokensCandidates[i]];
                    }

                    boosterAccumulatedRewards +=
                    IBooster(boostersAddresses[boosterIndex]).computeAmounts(accumulatedRewardsForBooster, yieldingCores, validTokensCandidates);

                } else {
                    uint256 summedBoosterAccumulatedRewards = 0;
                    for (uint256 i = 0; i < validTokensCandidates.length; ++i) {
                        summedBoosterAccumulatedRewards += accumulatedRewardsForBooster[i];
                    }
                    boosterAccumulatedRewards += IBooster(boostersAddresses[boosterIndex]).computeAmount(summedBoosterAccumulatedRewards);
                }
                for (uint256 i = 0; i < validTokensCandidates.length; ++i) {
                    if (boosterSettings._boosterStartDates[validTokensCandidates[i]] != uint256(0)) {
                        boosterSettings._boosterStartDates[validTokensCandidates[i]] = block.timestamp;
                    }
                }
            }
        }

        return boosterAccumulatedRewards;
    }

    function computeBoostersAccumulatedRewardsSafe(
        address _yielderAddress,
        YielderSettings storage _yielderSettings,
        uint256[] calldata _tokenIds
    ) internal view returns (uint256) {

        uint256 boosterAccumulatedRewards = 0;

        for (uint256 boosterIndex = 0; boosterIndex < boostersAddresses.length; ++boosterIndex) {
            BoosterSettings storage boosterSettings = getBoosterSettings(boostersAddresses[boosterIndex]);
            uint256 toBeSentArraysIndex = 0;
            uint256[] memory accumulatedRewardsForBooster = new uint256[](_tokenIds.length);
            uint256[] memory validTokensCandidates = new uint256[](_tokenIds.length);

            if (boosterSettings._appliesFor == _yielderAddress && boosterSettings._status) {
                for (uint256 i = 0; i < _tokenIds.length; ++i) {
                    uint256 lastClaimDate = getLastClaimForBooster(boosterSettings, _tokenIds[i]); 
                    if (
                        (
                        boosterSettings._yieldingCores.length() == 0
                        || boosterSettings._yieldingCores.contains(_yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]])
                        ) && _yielderSettings._lastClaim[_tokenIds[i]] != _yielderSettings._endTime
                        && lastClaimDate != uint256(0)
                    ) {
                        if (lastClaimDate == uint256(0)) {
                            lastClaimDate = _yielderSettings._startTime;
                        }
                        uint256 secondsElapsed = block.timestamp - lastClaimDate;

                        if (_yielderSettings._defaultYieldRate != uint256(0)) {
                            accumulatedRewardsForBooster[toBeSentArraysIndex] = secondsElapsed * _yielderSettings._defaultYieldRate / _yielderSettings._timeRate;
                        } else {
                            uint256 tokenYieldingCoresMapping = _yielderSettings._tokenYieldingCoresMapping[_tokenIds[i]];
                            uint256 yieldingCoresAmountMapping = _yielderSettings._yieldingCoresAmountMapping[tokenYieldingCoresMapping];
                            accumulatedRewardsForBooster[toBeSentArraysIndex] =
                            secondsElapsed * yieldingCoresAmountMapping / _yielderSettings._timeRate;
                        }
                        validTokensCandidates[toBeSentArraysIndex] = _tokenIds[i];
                        toBeSentArraysIndex++;
                    }
                }
                if (boosterSettings._yieldingCores.length() != 0) {
                    uint256[] memory yieldingCores = new uint256[](validTokensCandidates.length);

                    for (uint256 i = 0; i < validTokensCandidates.length; ++i) {
                        yieldingCores[i] = _yielderSettings._tokenYieldingCoresMapping[validTokensCandidates[i]];
                    }

                    boosterAccumulatedRewards +=
                    IBooster(boostersAddresses[boosterIndex]).computeAmounts(accumulatedRewardsForBooster, yieldingCores, validTokensCandidates);

                } else {
                    uint256 summedBoosterAccumulatedRewards = 0;
                    for (uint256 i = 0; i < validTokensCandidates.length; ++i) {
                        summedBoosterAccumulatedRewards += accumulatedRewardsForBooster[i];
                    }
                    boosterAccumulatedRewards += IBooster(boostersAddresses[boosterIndex]).computeAmount(summedBoosterAccumulatedRewards);
                }
            }
        }

        return boosterAccumulatedRewards;
    }

    function getLastClaimForYielder(YielderSettings storage _yielderSettings, uint256 _tokenId) internal view returns (uint256) {
        uint256 lastClaimDate =  _yielderSettings._lastClaim[_tokenId];
        if (lastClaimDate == uint256(0)) {
            lastClaimDate = _yielderSettings._startTime;
        }

        return lastClaimDate;
    }

    function getLastClaim(address _yielderAddress, uint256 _tokenId) external whenNotPaused view returns (uint256) {
        YielderSettings storage yielderSettings = getYielderSettings(_yielderAddress);
        return getLastClaimForYielder(yielderSettings, _tokenId);
    }

    function getLastClaimForBooster(BoosterSettings storage _boosterSettings, uint256 _tokenId) view internal returns (uint256) {
        uint256 lastClaimDate = _boosterSettings._boosterStartDates[_tokenId];

        return lastClaimDate;
    }


    // UTILS

    function watchTransfer(address _from, address _to, uint256 _tokenId) external {
        getYielderSettings(msg.sender);

        if (_from == address(0)) {
            tokensOwnerShip[msg.sender][_to].add(_tokenId);
        } else {
            tokensOwnerShip[msg.sender][_to].add(_tokenId);
            if (tokensOwnerShip[msg.sender][_from].contains(_tokenId)) {
                tokensOwnerShip[msg.sender][_from].remove(_tokenId);
                if (tokensOwnerShip[msg.sender][_from].length() == 0) {
                    delete tokensOwnerShip[msg.sender][_from];
                }
            }
        }
    }

    function watchBooster(address _collection, uint256[] calldata _tokenIds, uint256[] calldata _startDates) external {
        //boster shall send uint256(0) as start if removed
        BoosterSettings storage boosterSettings = getBoosterSettings(msg.sender);

        if (boosterSettings._appliesFor == _collection) {
            for (uint32 i = 0; i < _tokenIds.length; ++i) {
                boosterSettings._boosterStartDates[_tokenIds[i]] = _startDates[i];
            }
        }
    }

    function claimTokens(uint256 _amount) internal {
        if (allowedPublicTokensMinted - _amount >= 0) {
            _mint(msg.sender, _amount);
            allowedPublicTokensMinted -= _amount;
        } else {
            IERC20(address(this)).transfer(msg.sender, _amount);
        }
    }

    function processTokenOwnerShip(address _contractAddress, uint256 _tokenId) internal {
        if (!tokensOwnerShip[_contractAddress][msg.sender].contains(_tokenId)) {
            address owner = IYielder(_contractAddress).ownerOf(_tokenId);
            if (owner == msg.sender) {
                tokensOwnerShip[_contractAddress][msg.sender].add(_tokenId);
            }
        }
        require(tokensOwnerShip[_contractAddress][msg.sender].contains(_tokenId), "Not the owner of the token");

    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}
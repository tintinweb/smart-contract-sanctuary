/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// File: contracts/OwnershipAgreement.sol

pragma solidity >=0.7.0 <0.9.0;


/// @title Creates an Ownership Agreement, with an optional Operator role
/// @author Dr. Jonathan Shahen at UREEQA
/// @notice TODO
/// @dev Maximum number of Owners is set to 255 (unit8.MAX_VALUE)
contract OwnershipAgreement {
    /*
     * Storage
     */
    enum ResolutionType {
        None, // This indicates that the resolution hasn't been set (default value)
        AddOwner,
        RemoveOwner,
        ReplaceOwner,
        AddOperator,
        RemoveOperator,
        ReplaceOperator,
        UpdateThreshold,
        UpdateTransactionLimit,
        Pause,
        Unpause,
        Custom
    }
    struct Resolution {
        // Has the resolution already been passed
        bool passed;
        // The type of resolution
        ResolutionType resType;
        // The old address, can be address(0). oldAddress and newAddress cannot both equal address(0).
        address oldAddress;
        // The new address, can be address(0). oldAddress and newAddress cannot both equal address(0).
        address newAddress;
    }
    using EnumerableSet for EnumerableSet.AddressSet;
    // Set of owners
    // NOTE: we utilize a set, so we can enumerate the owners and so that the list only contains one instance of an account
    // NOTE: address(0) is not a valid owner
    EnumerableSet.AddressSet private _owners;
    // Value to indicate if the smart contract is paused
    bool private _paused;
    // An address, usually controlled by a computer, that performs regular/automated operations within the smart contract
    // NOTE: address(0) is not a valid operator
    EnumerableSet.AddressSet private _operators;
    // Limit the number of operators
    uint160 public operatorLimit = 1;
    // The number of owners it takes to come to an agreement
    uint160 public ownerAgreementThreshold = 1;
    // Limit per Transaction to impose
    // A limit of zero means no limit imposed
    uint256 public transactionLimit = 0;
    // Stores each vote for each resolution number (int)
    mapping(address => mapping(uint256 => bool)) public ownerVotes;
    // The next available resolution number
    uint256 public nextResolution = 1;
    mapping(address => uint256) lastOwnerResolutionNumber;
    // Stores the resolutions
    mapping(uint256 => Resolution) public resolutions;

    // ////////////////////////////////////////////////////
    // EVENTS
    // ////////////////////////////////////////////////////
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event OwnerReplacement(address oldOwner, address newOwner);

    event OperatorAddition(address newOperator);
    event OperatorRemoval(address oldOperator);
    event OperatorReplacement(address oldOperator, address newOperator);

    event UpdateThreshold(uint160 newThreshold);
    event UpdateNumberOfOperators(uint160 newOperators);
    event UpdateTransactionLimit(uint256 newLimit);
    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);
    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    // ////////////////////////////////////////////////////
    // MODIFIERS
    // ////////////////////////////////////////////////////
    function isValidAddress(address newAddr) public pure {
        require(newAddr != address(0), "Invaild Address");
    }

    modifier onlyOperators() {
        isValidAddress(msg.sender);
        require(
            EnumerableSet.contains(_operators, msg.sender) == true,
            "Only the operator can run this function."
        );
        _;
    }
    modifier onlyOwners() {
        isValidAddress(msg.sender);
        require(
            EnumerableSet.contains(_owners, msg.sender) == true,
            "Only an owner can run this function."
        );
        _;
    }

    modifier onlyOwnersOrOperator() {
        isValidAddress(msg.sender);
        require(
            EnumerableSet.contains(_operators, msg.sender) == true || 
            EnumerableSet.contains(_owners, msg.sender) == true,
            "Only an owner or the operator can run this function."
        );
        _;
    }

    modifier ownerExists(address owner) {
        require(
            EnumerableSet.contains(_owners, owner) == true,
            "Owner does not exists."
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     * Requirements: The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Smart Contract is paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     * Requirements: The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Smart Contract is not paused");
        _;
    }

    /// @dev Modifier to make a function callable only when the amount is within the transaction limit
    modifier withinLimit(uint256 amount) {
        require(transactionLimit == 0 || amount <= transactionLimit, "Amount is over the transaction limit");
        _;
    }

    // ////////////////////////////////////////////////////
    // CONSTRUCTOR
    // ////////////////////////////////////////////////////
    constructor() {
        _addOwner(msg.sender);
        _paused = false;
    }

    // ////////////////////////////////////////////////////
    // VIEW FUNCTIONS
    // ////////////////////////////////////////////////////

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        uint256 len = EnumerableSet.length(_owners);
        address[] memory o = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            o[i] = EnumerableSet.at(_owners, i);
        }

        return o;
    }

    /// @dev Returns the number of owners.
    /// @return Number of owners.
    function getNumberOfOwners() public view returns (uint8) {
        return uint8(EnumerableSet.length(_owners));
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOperators() public view returns (address[] memory) {
        uint256 len = EnumerableSet.length(_operators);
        address[] memory o = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            o[i] = EnumerableSet.at(_operators, i);
        }

        return o;
    }

    /// @dev Returns the number of operators.
    /// @return Number of operators.
    function getNumberOfOperators() public view returns (uint8) {
        return uint8(EnumerableSet.length(_operators));
    }

    /// @dev How many owners does it take to approve a resolution
    /// @return minimum number of owner votes
    function getVoteThreshold() public view returns (uint160) {
        return ownerAgreementThreshold;
    }

    /// @dev Returns the maximum amount a transaction can contain
    /// @return maximum amount or zero is no limit
    function getTransactionLimit() public view returns (uint256) {
        return transactionLimit;
    }

    /// @dev Returns the next available resolution.
    /// @return The next available resolution number
    function getNextResolutionNumber() public view returns (uint256) {
        return nextResolution;
    }

    /// @dev Returns the next available resolution.
    /// @return The next available resolution number
    function getLastOwnerResolutionNumber(address owner) public view returns (uint256) {
        return lastOwnerResolutionNumber[owner];
    }

    /// @dev Returns true if the contract is paused, and false otherwise.
    function paused() public view returns (bool) {
        return _paused;
    }

    /// @dev Helper function to fail if resolution number is already in use.
    function resolutionAlreadyUsed(uint256 resNum) public view {
        require(
            // atleast one of the address must not be equal to address(0)
            !(resolutions[resNum].oldAddress != address(0) ||
                resolutions[resNum].newAddress != address(0)),
            "Resolution is already in use."
        );
    }

    function isResolutionPassed(uint256 resNum) public view returns (bool) {
        return resolutions[resNum].passed;
    }

    function canResolutionPass(uint256 resNum) public view returns (bool) {
        uint256 voteCount = 0;
        uint256 len = EnumerableSet.length(_owners);

        for (uint256 i = 0; i < len; i++) {
            if (ownerVotes[EnumerableSet.at(_owners, i)][resNum] == true) {
                voteCount++;
            }
        }

        return voteCount >= ownerAgreementThreshold;
    }

    // ////////////////////////////////////////////////////
    // PUBLIC FUNCTIONS
    // ////////////////////////////////////////////////////

    /// @notice Vote Yes on a Resolution.
    /// @dev The owner who tips the agreement threshold will pay the gas for performing the resolution.
    /// @return TRUE if the resolution passed
    function voteResolution(uint256 resNum) public onlyOwners() returns (bool) {
        ownerVotes[msg.sender][resNum] = true;

        // If the reolution has already passed, then do nothing
        if (isResolutionPassed(resNum)) {
            return true;
        }

        // If the resolution can now be passed, then do so
        if (canResolutionPass(resNum)) {
            _performResolution(resNum);
            return true;
        }

        // The resolution cannot be passed yet
        return false;
    }

    /// @dev Create a resolution to add an owner. Performs addition if threshold is 1 or zero.
    function createResolutionAddOwner(address newOwner) public onlyOwners() {
        isValidAddress(newOwner);
        require(!EnumerableSet.contains(_owners, newOwner),"newOwner already exists.");

        createResolution(ResolutionType.AddOwner, address(0), newOwner);
    }

    /// @dev Create a resolution to remove an owner. Performs removal if threshold is 1 or zero.
    /// @dev Updates the threshold to keep it less than or equal to the number of new owners
    function createResolutionRemoveOwner(address owner) public onlyOwners() {
        isValidAddress(owner);
        require(getNumberOfOwners() > 1, "Must always be one owner");
        require(EnumerableSet.contains(_owners, owner),"owner is not an owner.");

        createResolution(ResolutionType.RemoveOwner, owner, address(0));
    }

    /// @dev Create a resolution to repalce an owner. Performs replacement if threshold is 1 or zero.
    function createResolutionReplaceOwner(address oldOwner, address newOwner)
        public
        onlyOwners()
    {
        isValidAddress(oldOwner);
        isValidAddress(newOwner);
        require(EnumerableSet.contains(_owners, oldOwner),"oldOwner is not an owner.");
        require(!EnumerableSet.contains(_owners, newOwner),"newOwner already exists.");

        createResolution(ResolutionType.ReplaceOwner, oldOwner, newOwner);
    }

    /// @dev Create a resolution to add an operator. Performs addition if threshold is 1 or zero.
    function createResolutionAddOperator(address newOperator) public onlyOwners() {
        isValidAddress(newOperator);
        require(!EnumerableSet.contains(_operators, newOperator),"newOperator already exists.");

        createResolution(ResolutionType.AddOperator, address(0), newOperator);
    }

    /// @dev Create a resolution to remove the operator. Performs removal if threshold is 1 or zero.
    function createResolutionRemoveOperator(address operator) public onlyOwners() {
        require(EnumerableSet.contains(_operators, operator),"operator is not an Operator.");
        createResolution(ResolutionType.RemoveOperator, operator, address(0));
    }

    /// @dev Create a resolution to replace the operator account. Performs replacement if threshold is 1 or zero.
    function createResolutionReplaceOperator(address oldOperator, address newOperator)
        public
        onlyOwners()
    {
        isValidAddress(oldOperator);
        isValidAddress(newOperator);
        require(EnumerableSet.contains(_operators, oldOperator),"oldOperator is not an Operator.");
        require(!EnumerableSet.contains(_operators, newOperator),"newOperator already exists.");

        createResolution(ResolutionType.ReplaceOperator, oldOperator, newOperator);
    }

    /// @dev Create a resolution to update the transaction limit. Performs update if threshold is 1 or zero.
    function createResolutionUpdateTransactionLimit(uint160 newLimit)
        public
        onlyOwners()
    {
        createResolution(ResolutionType.UpdateTransactionLimit, address(0), address(newLimit));
    }

    /// @dev Create a resolution to update the owner agreement threshold. Performs update if threshold is 1 or zero.
    function createResolutionUpdateThreshold(uint160 threshold)
        public
        onlyOwners()
    {
        createResolution(ResolutionType.UpdateThreshold, address(0), address(threshold));
    }

    /// @dev Pause the contract. Does not require owner agreement.
    function pause() public onlyOwners() {
        _pause();
    }

    /// @dev Create a resolution to unpause the contract. Performs update if threshold is 1 or zero.
    function createResolutionUnpause() public onlyOwners() {
        createResolution(ResolutionType.Unpause, address(1), address(1));
    }

    // ////////////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    // ////////////////////////////////////////////////////
    /// @dev Create a resolution and check if we can call perofrm the resolution with 1 vote.
    function createResolution(ResolutionType resType, address oldAddress, address newAddress) internal {
        uint256 resNum = nextResolution;
        nextResolution++;
        resolutionAlreadyUsed(resNum);

        resolutions[resNum].resType = resType;
        resolutions[resNum].oldAddress = oldAddress;
        resolutions[resNum].newAddress = newAddress;

        ownerVotes[msg.sender][resNum] = true;
        lastOwnerResolutionNumber[msg.sender] = resNum;

        // Check if agreement is already reached
        if (ownerAgreementThreshold <= 1) {
            _performResolution(resNum);
        }
    }

    /// @dev Performs the resolution and then marks it as passed. No checks prevent it from performing the resolutions.
    function _performResolution(uint256 resNum) internal {
        if (resolutions[resNum].resType == ResolutionType.AddOwner) {
            _addOwner(resolutions[resNum].newAddress);
        } else if (resolutions[resNum].resType == ResolutionType.RemoveOwner) {
            _removeOwner(resolutions[resNum].oldAddress);
        } else if (resolutions[resNum].resType == ResolutionType.ReplaceOwner) {
            _replaceOwner(
                resolutions[resNum].oldAddress,
                resolutions[resNum].newAddress
            );
        } else if (
            resolutions[resNum].resType == ResolutionType.AddOperator
        ) {
            _addOperator(resolutions[resNum].newAddress);
        } else if (
            resolutions[resNum].resType == ResolutionType.RemoveOperator
        ) {
            _removeOperator(resolutions[resNum].oldAddress);
        } else if (
            resolutions[resNum].resType == ResolutionType.ReplaceOperator
        ) {
            _replaceOperator(resolutions[resNum].oldAddress,resolutions[resNum].newAddress);
        } else if (
            resolutions[resNum].resType == ResolutionType.UpdateTransactionLimit
        ) {
            _updateTransactionLimit(uint160(resolutions[resNum].newAddress));
        } else if (
            resolutions[resNum].resType == ResolutionType.UpdateThreshold
        ) {
            _updateThreshold(uint160(resolutions[resNum].newAddress));
        } else if (
            resolutions[resNum].resType == ResolutionType.Pause
        ) {
            _pause();
        } else if (
            resolutions[resNum].resType == ResolutionType.Unpause
        ) {
            _unpause();
        }

        resolutions[resNum].passed = true;
    }

    /// @dev
    function _addOwner(address owner) internal {
        EnumerableSet.add(_owners, owner);
        emit OwnerAddition(owner);
    }

    /// @dev
    function _removeOwner(address owner) internal {
        EnumerableSet.remove(_owners, owner);
        emit OwnerRemoval(owner);

        uint8 numOwners = getNumberOfOwners();
        if(ownerAgreementThreshold > numOwners) {
            _updateThreshold(numOwners);
        }
    }

    /// @dev
    function _replaceOwner(address oldOwner, address newOwner) internal {
        EnumerableSet.remove(_owners, oldOwner);
        EnumerableSet.add(_owners, newOwner);
        emit OwnerReplacement(oldOwner, newOwner);
    }

    /// @dev
    function _addOperator(address operator) internal {
        EnumerableSet.add(_operators, operator);
        emit OperatorAddition(operator);
    }

    /// @dev
    function _removeOperator(address operator) internal {
        EnumerableSet.remove(_operators, operator);
        emit OperatorRemoval(operator);
    }

    /// @dev
    function _replaceOperator(address oldOperator, address newOperator) internal {
        emit OperatorReplacement(oldOperator, newOperator);
        EnumerableSet.remove(_operators, oldOperator);
        EnumerableSet.add(_operators, newOperator);
    }

    /// @dev Internal function to update and emit the new transaction limit
    function _updateTransactionLimit(uint256 newLimit) internal {
        emit UpdateTransactionLimit(newLimit);
        transactionLimit = newLimit;
    }

    /// @dev Internal function to update and emit the new voting threshold
    function _updateThreshold(uint160 threshold) internal {
        require(threshold <= getNumberOfOwners(), "Unable to set threshold above the number of owners");
        emit UpdateThreshold(threshold);
        ownerAgreementThreshold = threshold;
    }

    /// @dev Internal function to update and emit the new voting threshold
    function _updateNumberOfOperators(uint160 numOperators) internal {
        require(numOperators >= getNumberOfOperators(), "Unable to set number of Operators below the number of operators");
        emit UpdateNumberOfOperators(numOperators);
        operatorLimit = numOperators;
    }


    /**
     * @dev Triggers stopped state.
     *
     * Requirements: The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements: The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: contracts/URQAToken.sol

pragma solidity >=0.7.0 <0.9.0;



/// @title UREEQA's URQA Token
/// @author Dr. Jonathan Shahen at UREEQA
contract URQAToken is OwnershipAgreement, ERC20 {

    constructor() ERC20("UREEQA Token", "URQA") {
        // Total Supply: 100 million
        _mint(msg.sender, 100_000_000e18);
    }

    /**
     * @dev Batch transfer to reduce gas fees. Utilizes SafeMath and self.transfer
     *
     * Requirements:
     *
     * - `recipients` cannot contain the zero address.
     * - the caller must have a balance of at least SUM `amounts`.
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
        for(uint256 i=0; i< amounts.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Cannot complete token transfer while Contract is Paused");
    }
}
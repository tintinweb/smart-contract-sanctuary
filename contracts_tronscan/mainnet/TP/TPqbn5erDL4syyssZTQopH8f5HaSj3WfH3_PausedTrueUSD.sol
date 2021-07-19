//SourceUnit: PausedTrueUSD.sol

/**
 *  :::==== :::====  :::  === :::===== :::  === :::===  :::==== 
 *  :::==== :::  === :::  === :::      :::  === :::     :::  ===
 *    ===   =======  ===  === ======   ===  ===  =====  ===  ===
 *    ===   === ===  ===  === ===      ===  ===     === ===  ===
 *    ===   ===  ===  ======  ========  ======  ======  ======= 
 */

pragma solidity 0.6.0;

/**
 * Defines the storage layout of the token implementation contract. Any
 * newly declared state variables in future upgrades should be appended
 * to the bottom. Never remove state variables from this list, however variables
 * can be renamed. Please add _Deprecated to deprecated variables.
 */
contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool initialized;

    uint256 _totalSupply;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isBlacklisted;
    mapping(address => bool) public canBurn;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     ** 19         "trueXXX.proxy.owner"                                         Proxy Owner
     ** 27         "trueXXX.pending.proxy.owner"                                 Pending Proxy Owner
     ** 28         "trueXXX.proxy.implementation"                                Proxy Implementation
     ** 64         uint256(address),uint256(14)                                  balanceOf
     ** 64         uint256(address),keccak256(uint256(address),uint256(15))      allowance
     ** 64         uint256(address),keccak256(bytes32,uint256(16))               attributes
     **/
}

pragma solidity 0.6.0;

/**
 * @title ClamableOwnable
 * @dev The ClamableOwnable contract is a copy of Claimable Contract by Zeppelin.
 * and provides basic authorization control functions. Inherits storage layout of
 * ProxyStorage.
 */
contract ClaimableOwnable is ProxyStorage {
    /**
     * @dev emitted when ownership is transferred
     * @param previousOwner previous owner of this contract
     * @param newOwner new owner of this contract
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "only pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the TRC20 standard as defined in the TIP.
 */
interface ITRC20 {
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

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

/**
 * @notice This is a copy of openzeppelin ERC20 contract with removed state variables.
 * Removing state variables has been necessary due to proxy pattern usage.
 * Changes to Openzeppelin ERC20 https://github.com/OpenZeppelin/openzeppelin-contracts/blob/de99bccbfd4ecd19d7369d01b070aa72c64423c9/contracts/token/ERC20/ERC20.sol:
 * - Remove state variables _name, _symbol, _decimals
 * - Use state variables _balances, _allowances, _totalSupply from ProxyStorage
 * - Remove constructor
 * - Contract made abstract
 *
 * See also: ClaimableOwnable.sol and ProxyStorage.sol
 */

pragma solidity 0.6.0;

/**
 * @dev Implementation of the {ITRC20} interface.
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
 * by listening to said events. Other implementations of the TIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {ITRC20-approve}.
 */
abstract contract TRC20 is ClaimableOwnable, Context, ITRC20 {
    using SafeMath for uint256;

    /**
     * @dev Returns the name of the token.
     */
    function name() public virtual pure returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public virtual pure returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18. This is the value {TRC20} uses, 
     * unless {_setupDecimals} is called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {ITRC20-balanceOf} and {ITRC20-transfer}.
     */
    function decimals() public virtual pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {ITRC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ITRC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address, /*_to*/
        uint256 /*_value*/
    ) public override returns (bool) {
        revert("Token Paused");
    }

    /**
     * @dev See {ITRC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address, /*_spender*/
        uint256 /*_value*/
    ) public override returns (bool) {
        revert("Token Paused");
    }

    function transferFrom(
        address, /*_from*/
        address, /*_to*/
        uint256 /*_value*/
    ) public override returns (bool) {
        revert("Token Paused");
    }

    function increaseAllowance(
        address, /*_spender*/
        uint256 /*_addedValue*/
    ) public pure returns (bool) {
        revert("Token Paused");
    }

    function decreaseAllowance(
        address, /*_spender*/
        uint256 /*_subtractedValue*/
    ) public pure returns (bool) {
        revert("Token Paused");
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
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "TRC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "TRC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

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
    // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.6.0;

/**
 * @title ReclaimerToken
 * @dev TRC20 token which allows owner to reclaim TRC20 tokens
 * or trx sent to this contract
 */
abstract contract ReclaimerToken is TRC20 {
    /**
     * @dev send all trx balance in the contract to another address
     * @param _to address to send trx balance to
     */
    function reclaimTrx(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * @dev send all token balance of an arbitrary trc20 token
     * in the contract to another address
     * @param token token to reclaim
     * @param _to address to send trc20 balance to
     */
    function reclaimToken(ITRC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }
}

pragma solidity 0.6.0;

/**
 * @title BurnableTokenWithBounds
 * @dev Burning functions as redeeming money from the system.
 * The platform will keep track of who burns coins,
 * and will send them back the equivalent amount of money (rounded down to the nearest cent).
 */
abstract contract BurnableTokenWithBounds is ReclaimerToken {
    /**
     * @dev Emitted when `value` tokens are burnt from one account (`burner`)
     * @param burner address which burned tokens
     * @param value amount of tokens burned
     */
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Emitted when new burn bounds were set
     * @param newMin new minimum burn amount
     * @param newMax new maximum burn amount
     * @notice `newMin` should never be greater than `newMax`
     */
    event SetBurnBounds(uint256 newMin, uint256 newMax);

    function burn(
        uint256 /*_value*/
    ) public pure {
        revert("Token Paused");
    }

    /**
     * @dev Change the minimum and maximum amount that can be burned at once.
     * Burning may be disabled by setting both to 0 (this will not be done
     * under normal operation, but we can't add checks to disallow it without
     * losing a lot of flexibility since burning could also be as good as disabled
     * by setting the minimum extremely high, and we don't want to lock
     * in any particular cap for the minimum)
     * @param _min minimum amount that can be burned at once
     * @param _max maximum amount that can be burned at once
     */
    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, "BurnableTokenWithBounds: min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }

    /**
     * @dev Checks if amount is within allowed burn bounds and
     * destroys `amount` tokens from `account`, reducing the
     * total supply.
     * @param account account to burn tokens for
     * @param amount amount of tokens to burn
     *
     * Emits a {Burn} event
     */
    function _burn(address account, uint256 amount) internal virtual override {
        require(amount >= burnMin, "BurnableTokenWithBounds: below min burn bound");
        require(amount <= burnMax, "BurnableTokenWithBounds: exceeds max burn bound");

        super._burn(account, amount);
        emit Burn(account, amount);
    }
}

pragma solidity 0.6.0;

/**
 * @title TrueCurrency
 * @dev TrueCurrency is an TRC20 with blacklist & redemption addresses
 *
 * TrueCurrency is a compliant stablecoin with blacklist and redemption
 * addresses. Only the owner can blacklist accounts. Redemption addresses
 * are assigned automatically to the first 0x100000 addresses. Sending
 * tokens to the redemption address will trigger a burn operation. Only
 * the owner can mint or blacklist accounts.
 *
 * This contract is owned by the TokenController, which manages token
 * minting & admin functionality. See TokenController.sol
 *
 * See also: BurnableTokenWithBounds.sol
 *
 * ~~~~ Features ~~~~
 *
 * Redemption Addresses
 * - The first 0x100000 addresses are redemption addresses
 * - Tokens sent to redemption addresses are burned
 * - Redemptions are tracked off-chain
 * - Cannot mint tokens to redemption addresses
 *
 * Blacklist
 * - Owner can blacklist accounts in accordance with local regulatory bodies
 * - Only a court order will merit a blacklist; blacklisting is extremely rare
 *
 * Burn Bounds & CanBurn
 * - Owner can set min & max burn amounts
 * - Only accounts flagged in canBurn are allowed to burn tokens
 * - canBurn prevents tokens from being sent to the incorrect address
 *
 * Reclaimer Token
 * - TRC20 Tokens and Trx sent to this contract can be reclaimed by the owner
 */
abstract contract TrueCurrency is BurnableTokenWithBounds {
    uint256 constant CENT = 10**16;
    uint256 constant REDEMPTION_ADDRESS_COUNT = 0x100000;

    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    /**
     * @dev Emitted when `value` tokens are minted for `to`
     * @param to address to mint tokens for
     * @param value amount of tokens to be minted
     */
    event Mint(address indexed to, uint256 value);

    function mint(
        address, /*_to*/
        uint256 /*_value*/
    ) public view onlyOwner {
        revert("Token Paused");
    }

    /**
     * @dev Set blacklisted status for the account.
     * @param account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address account, bool _isBlacklisted) external onlyOwner {
        require(uint256(account) >= REDEMPTION_ADDRESS_COUNT, "TrueCurrency: blacklisting of redemption address is not allowed");
        isBlacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }

    /**
     * @dev Set canBurn status for the account.
     * @param account address to set canBurn flag for
     * @param _canBurn canBurn flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setCanBurn(address account, bool _canBurn) external onlyOwner {
        canBurn[account] = _canBurn;
    }

    /**
     * @dev Check if neither account is blacklisted before performing transfer
     * If transfer recipient is a redemption address, burns tokens
     * @notice Transfer to redemption address will burn tokens with a 1 cent precision
     * @param sender address of sender
     * @param recipient address of recipient
     * @param amount amount of tokens to transfer
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!isBlacklisted[sender], "TrueCurrency: sender is blacklisted");
        require(!isBlacklisted[recipient], "TrueCurrency: recipient is blacklisted");

        if (isRedemptionAddress(recipient)) {
            super._transfer(sender, recipient, amount.sub(amount.mod(CENT)));
            _burn(recipient, amount.sub(amount.mod(CENT)));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Requere neither accounts to be blacklisted before approval
     * @param owner address of owner giving approval
     * @param spender address of spender to approve for
     * @param amount amount of tokens to approve
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[owner], "TrueCurrency: tokens owner is blacklisted");
        require(!isBlacklisted[spender] || amount == 0, "TrueCurrency: tokens spender is blacklisted");

        super._approve(owner, spender, amount);
    }

    /**
     * @dev Check if tokens can be burned at address before burning
     * @param account account to burn tokens from
     * @param amount amount of tokens to burn
     */
    function _burn(address account, uint256 amount) internal override {
        require(canBurn[account], "TrueCurrency: cannot burn from this address");
        super._burn(account, amount);
    }

    /**
     * @dev First 0x100000-1 addresses (0x0000000000000000000000000000000000000001 to 0x00000000000000000000000000000000000fffff)
     * are the redemption addresses.
     * @param account address to check is a redemption address
     *
     * All transfers to redemption address will trigger token burn.
     *
     * @notice For transfer to succeed, canBurn must be true for redemption address
     *
     * @return is `account` a redemption address
     */
    function isRedemptionAddress(address account) internal pure returns (bool) {
        return uint256(account) < REDEMPTION_ADDRESS_COUNT && uint256(account) != 0;
    }

    function paused() public pure returns (bool) {
        return true;
    }
}

pragma solidity 0.6.0;

/**
 * @title PausedTrueUSD
 * @dev This is the top-level TRC20 contract, but most of the interesting functionality is
 * inherited - see the documentation on the corresponding contracts.
 */
contract PausedTrueUSD is TrueCurrency {
    uint8 constant DECIMALS = 18;
    uint8 constant ROUNDING = 2;

    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
        burnMin = 1000000000000000000000;
        burnMax = 1000000000000000000000000000;
        initialized = true;
    }

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }

    function rounding() public pure returns (uint8) {
        return ROUNDING;
    }

    function name() public override pure returns (string memory) {
        return "TrueUSD";
    }

    function symbol() public override pure returns (string memory) {
        return "TUSD";
    }
}
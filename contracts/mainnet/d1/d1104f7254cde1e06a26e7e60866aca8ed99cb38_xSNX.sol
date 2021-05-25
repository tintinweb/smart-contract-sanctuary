/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

// File: synthetix/contracts/interfaces/ISynth.sol

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}

// File: synthetix/contracts/interfaces/IVirtualSynth.sol

pragma solidity >=0.4.24;


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}

// File: synthetix/contracts/interfaces/ISynthetix.sol

pragma solidity >=0.4.24;



// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableSynthetix(address account) external view returns (uint transferable);

    // Mutative Functions
    function burnSynths(uint amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}

// File: synthetix/contracts/interfaces/IRewardEscrowV2.sol

pragma solidity >=0.4.24;
pragma experimental ABIEncoderV2;

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

interface IRewardEscrowV2 {
    // Views
    function balanceOf(address account) external view returns (uint);

    function numVestingEntries(address account) external view returns (uint);

    function totalEscrowedAccountBalance(address account) external view returns (uint);

    function totalVestedAccountBalance(address account) external view returns (uint);

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint);

    function getVestingEntry(address account, uint256 entryID) external view returns (uint64, uint256);

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function migrateVestingSchedule(address _addressToMigrate) external;

    function migrateAccountEscrowBalances(
        address[] calldata accounts,
        uint256[] calldata escrowBalances,
        uint256[] calldata vestedBalances
    ) external;

    // Account Merging
    function startMergingWindow() external;

    function mergeAccount(address accountToMerge, uint256[] calldata entryIDs) external;

    function nominateAccountToMerge(address account) external;

    function accountMergingIsOpen() external view returns (bool);

    // L2 Migration
    function importVestingEntries(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external;

    // Return amount of SNX transfered to SynthetixBridgeToOptimism deposit contract
    function burnForMigration(address account, uint256[] calldata entryIDs)
        external
        returns (uint256 escrowedAccountBalance, VestingEntries.VestingEntry[] memory vestingEntries);
}

// File: synthetix/contracts/interfaces/IExchangeRates.sol

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozenAtUpperLimit;
        bool frozenAtLowerLimit;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function canFreezeRate(bytes32 currencyKey) external view returns (bool);

    function currentRoundForRate(bytes32 currencyKey) external view returns (uint);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external view returns (uint value);

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function inversePricing(bytes32 currencyKey)
        external
        view
        returns (
            uint entryPoint,
            uint upperLimit,
            uint lowerLimit,
            bool frozenAtUpperLimit,
            bool frozenAtLowerLimit
        );

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(bytes32 currencyKey, uint numRounds)
        external
        view
        returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    // Mutative functions
    function freezeRate(bytes32 currencyKey) external;
}

// File: synthetix/contracts/interfaces/ISynthetixState.sol

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isynthetixstate
interface ISynthetixState {
    // Views
    function debtLedger(uint index) external view returns (uint);

    function issuanceData(address account) external view returns (uint initialDebtOwnership, uint debtEntryIndex);

    function debtLedgerLength() external view returns (uint);

    function hasIssued(address account) external view returns (bool);

    function lastDebtLedgerEntry() external view returns (uint);

    // Mutative functions
    function incrementTotalIssuerCount() external;

    function decrementTotalIssuerCount() external;

    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external;

    function appendDebtLedgerValue(uint value) external;

    function clearIssuanceData(address account) external;
}

// File: synthetix/contracts/interfaces/IAddressResolver.sol

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// File: contracts/interface/ISystemSettings.sol

pragma solidity 0.5.15;

interface ISystemSettings {
    function issuanceRatio() external view returns(uint);
}

// File: contracts/interface/ICurveFi.sol

pragma solidity 0.5.15;

interface ICurveFi {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;
  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;
  function get_dx_underlying(
    int128 i,
    int128 j,
    uint256 dy
  ) external view returns (uint256);
  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
  function get_dx(
    int128 i,
    int128 j,
    uint256 dy
  ) external view returns (uint256);
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
  function get_virtual_price() external view returns (uint256);
}

// File: contracts/interface/ISetToken.sol

pragma solidity 0.5.15;

interface ISetToken {
    function unitShares() external view returns(uint);
    function naturalUnit() external view returns(uint);
    function currentSet() external view returns(address);
    // function getUnits() external view returns (uint256[] memory);
}

// File: contracts/interface/IKyberNetworkProxy.sol

pragma solidity 0.5.15;


contract IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint);
}

// File: contracts/interface/ISetAssetBaseCollateral.sol

pragma solidity 0.5.15;

interface ISetAssetBaseCollateral {
    function getComponents() external view returns(address[] memory);
    function naturalUnit() external view returns(uint);
    function getUnits() external view returns (uint256[] memory);
}

// File: contracts/TradeAccounting.sol

pragma solidity 0.5.15;
















/*
	xSNX Target Allocation (assuming 800% C-RATIO)
	----------------------
	Allocation         |  NAV   | % NAV
	--------------------------------------
	800 SNX @ $1/token | $800   | 100%
	100 sUSD Debt	   | ($100)	| (12.5%)
	75 USD equiv Set   | $75    | 9.375%
	25 USD equiv ETH   | $25    | 3.125%
	--------------------------------------
	Total                $800   | 100%
 */

/*
	Conditions for `isRebalanceTowardsHedgeRequired` to return true
	Assuming 5% rebalance threshold

	Allocation         |  NAV   | % NAV
	--------------------------------------
	800 SNX @ $1/token | $800   | 100.63%
	105 sUSD Debt	   | ($105)	| (13.21%)
	75 USD equiv Set   | $75    | 9.43%
	25 USD equiv ETH   | $25    | 3.14%
	--------------------------------------
	Total                $795   | 100%

	Debt value		   | $105
	Hedge Assets	   | $100
	-------------------------
	Debt/hedge ratio   | 105%
  */

/*
	Conditions for `isRebalanceTowardsSnxRequired` to return true
	Assuming 5% rebalance threshold

	Allocation         |  NAV   | % NAV
	--------------------------------------
	800 SNX @ $1/token | $800   | 99.37%
	100 sUSD Debt	   | ($100)	| (12.42%)
	75 USD equiv Set   | $75    | 9.31%
	30 USD equiv ETH   | $30    | 3.72%
	--------------------------------------
	Total                $805   | 100%

	Hedge Assets	   | $105
	Debt value		   | $100
	-------------------------
	Hedge/debt ratio   | 105%
  */

contract TradeAccounting is Ownable {
    using SafeMath for uint256;

    uint256 private constant TEN = 10;
    uint256 private constant DEC_18 = 1e18;
    uint256 private constant PERCENT = 100;
    uint256 private constant ETH_TARGET = 4; // targets 1/4th of hedge portfolio
    uint256 private constant SLIPPAGE_RATE = 99;
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant RATE_STALE_TIME = 28800; // 8 hours
    uint256 private constant REBALANCE_THRESHOLD = 105; // 5%
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;

    int128 usdcIndex;
    int128 susdIndex;

    ICurveFi private curveFi;
    ISynthetixState private synthetixState;
    IAddressResolver private addressResolver;
    IKyberNetworkProxy private kyberNetworkProxy;

    address private xSNXAdminInstance;
    address private addressValidator;

    address private setAddress;
    address private susdAddress;
    address private usdcAddress;

    address private nextCurveAddress;

    bytes32 constant snx = "SNX";
    bytes32 constant susd = "sUSD";
    bytes32 constant seth = "sETH";

    bytes32[2] synthSymbols;

    address[2] setComponentAddresses;

    bytes32 constant rewardEscrowName = "RewardEscrow";
    bytes32 constant exchangeRatesName = "ExchangeRates";
    bytes32 constant synthetixName = "Synthetix";
    bytes32 constant systemSettingsName = "SystemSettings";
    bytes32 constant rewardEscrowV2Name = "RewardEscrowV2";

    uint256 private constant RATE_STALE_TIME_NEW = 86400; // 24 hours

    function initialize(
        address _setAddress,
        address _kyberProxyAddress,
        address _addressResolver,
        address _susdAddress,
        address _usdcAddress,
        address _addressValidator,
        bytes32[2] memory _synthSymbols,
        address[2] memory _setComponentAddresses,
        address _ownerAddress
    ) public initializer {
        Ownable.initialize(_ownerAddress);

        setAddress = _setAddress;
        kyberNetworkProxy = IKyberNetworkProxy(_kyberProxyAddress);
        addressResolver = IAddressResolver(_addressResolver);
        susdAddress = _susdAddress;
        usdcAddress = _usdcAddress;
        addressValidator = _addressValidator;
        synthSymbols = _synthSymbols;
        setComponentAddresses = _setComponentAddresses;
    }

    modifier onlyXSNXAdmin {
        require(
            msg.sender == xSNXAdminInstance,
            "Only xSNXAdmin contract can call"
        );
        _;
    }

    /* ========================================================================================= */
    /*                                         Kyber/Curve                                       */
    /* ========================================================================================= */

    /*
     * @dev Function that processes all token to token exchanges,
     * sometimes via Kyber and sometimes via a combination of Kyber & Curve
     * @dev Only callable by xSNXAdmin contract
     */
    function swapTokenToToken(
        address fromToken,
        uint256 amount,
        address toToken,
        uint256 minKyberRate,
        uint256 minCurveReturn
    ) public onlyXSNXAdmin {
        if (fromToken == susdAddress) {
            _exchangeUnderlying(susdIndex, usdcIndex, amount, minCurveReturn);

            if (toToken != usdcAddress) {
                uint256 usdcBal = getUsdcBalance();
                _swapTokenToToken(usdcAddress, usdcBal, toToken, minKyberRate);
            }
        } else if (toToken == susdAddress) {
            if (fromToken != usdcAddress) {
                _swapTokenToToken(fromToken, amount, usdcAddress, minKyberRate);
            }

            uint256 usdcBal = getUsdcBalance();
            _exchangeUnderlying(usdcIndex, susdIndex, usdcBal, minCurveReturn);
        } else {
            _swapTokenToToken(fromToken, amount, toToken, minKyberRate);
        }

        IERC20(toToken).transfer(
            xSNXAdminInstance,
            IERC20(toToken).balanceOf(address(this))
        );
    }

    function _swapTokenToToken(
        address _fromToken,
        uint256 _amount,
        address _toToken,
        uint256 _minKyberRate
    ) private {
        kyberNetworkProxy.swapTokenToToken(
            ERC20(_fromToken),
            _amount,
            ERC20(_toToken),
            _minKyberRate
        );
    }

    /*
     * @dev Function that processes all token to ETH exchanges,
     * sometimes via Kyber and sometimes via a combination of Kyber & Curve
     * @dev Only callable by xSNXAdmin contract
     */
    function swapTokenToEther(
        address fromToken,
        uint256 amount,
        uint256 minKyberRate,
        uint256 minCurveReturn
    ) public onlyXSNXAdmin {
        if (fromToken == susdAddress) {
            _exchangeUnderlying(susdIndex, usdcIndex, amount, minCurveReturn);

            uint256 usdcBal = getUsdcBalance();
            _swapTokenToEther(usdcAddress, usdcBal, minKyberRate);
        } else {
            _swapTokenToEther(fromToken, amount, minKyberRate);
        }

        uint256 ethBal = address(this).balance;
        (bool success, ) = msg.sender.call.value(ethBal)("");
        require(success, "Transfer failed");
    }

    function _swapTokenToEther(
        address _fromToken,
        uint256 _amount,
        uint256 _minKyberRate
    ) private {
        kyberNetworkProxy.swapTokenToEther(
            ERC20(_fromToken),
            _amount,
            _minKyberRate
        );
    }

    function _exchangeUnderlying(
        int128 _inputIndex,
        int128 _outputIndex,
        uint256 _amount,
        uint256 _minReturn
    ) private {
        curveFi.exchange_underlying(
            _inputIndex,
            _outputIndex,
            _amount,
            _minReturn
        );
    }

    function getUsdcBalance() internal view returns (uint256) {
        return IERC20(usdcAddress).balanceOf(address(this));
    }

    /* ========================================================================================= */
    /*                                          NAV                                              */
    /* ========================================================================================= */

    function getEthBalance() public view returns (uint256) {
        return address(xSNXAdminInstance).balance;
    }

    /*
     * @dev Helper function for `xSNX.burn` that outputs NAV
     * redemption value in ETH terms
     * @param totalSupply: xSNX.totalSupply()
     * @param tokensToRedeem: xSNX to burn
     */
    function calculateRedemptionValue(
        uint256 totalSupply,
        uint256 tokensToRedeem
    ) public view returns (uint256 valueToRedeem) {
        uint256 snxBalanceOwned = getSnxBalanceOwned();
        uint256 contractDebtValue = getContractDebtValue();

        uint256 pricePerToken = calculateRedeemTokenPrice(
            totalSupply,
            snxBalanceOwned,
            contractDebtValue
        );

        valueToRedeem = pricePerToken.mul(tokensToRedeem).div(DEC_18);
    }

    /*
     * @dev Helper function for `xSNX.mint` that
     * 1) determines whether ETH contribution should be maintained in ETH or exchanged for SNX and
     * 2) outputs the `nonSnxAssetValue` value to be used in NAV calculation
     * @param totalSupply: xSNX.totalSupply()
     */
    function getMintWithEthUtils(uint256 totalSupply)
        public
        view
        returns (bool allocateToEth, uint256 nonSnxAssetValue)
    {
        uint256 setHoldingsInWei = getSetHoldingsValueInWei();

        // called before eth transferred from xSNX to xSNXAdmin
        uint256 ethBalBefore = getEthBalance();

        allocateToEth = shouldAllocateEthToEthReserve(
            setHoldingsInWei,
            ethBalBefore,
            totalSupply
        );
        nonSnxAssetValue = setHoldingsInWei.add(ethBalBefore);
    }

    /*
     * @notice xSNX system targets 25% of hedge portfolio to be maintained in ETH
     * @dev Function produces binary yes allocate/no allocate decision point
     * determining whether ETH sent on xSNX.mint() is held or exchanged
     * @param setHoldingsInWei: value of Set portfolio in ETH terms
     * @param ethBalBefore: value of ETH reserve prior to tx
     * @param totalSupply: xSNX.totalSupply()
     */
    function shouldAllocateEthToEthReserve(
        uint256 setHoldingsInWei,
        uint256 ethBalBefore,
        uint256 totalSupply
    ) public pure returns (bool allocateToEth) {
        if (totalSupply == 0) return false;

        if (ethBalBefore.mul(ETH_TARGET) < ethBalBefore.add(setHoldingsInWei)) {
            // ETH reserve is under target
            return true;
        }

        return false;
    }

    /*
     * @dev Helper function for calculateIssueTokenPrice
     * @dev Called indirectly by `xSNX.mint` and `xSNX.mintWithSnx`
     * @dev Calculates NAV of the fund, including value of escrowed SNX, in ETH terms
     * @param weiPerOneSnx: SNX price in ETH terms
     * @param snxBalanceBefore: SNX balance pre-mint
     * @param nonSnxAssetValue: NAV of non-SNX slice of fund
     */
    function calculateNetAssetValueOnMint(
        uint256 weiPerOneSnx,
        uint256 snxBalanceBefore,
        uint256 nonSnxAssetValue
    ) internal view returns (uint256) {
        uint256 snxTokenValueInWei = snxBalanceBefore.mul(weiPerOneSnx).div(
            DEC_18
        );
        uint256 contractDebtValue = getContractDebtValue();
        uint256 contractDebtValueInWei = calculateDebtValueInWei(
            contractDebtValue
        );
        return
            snxTokenValueInWei.add(nonSnxAssetValue).sub(
                contractDebtValueInWei
            );
    }

    /*
     * @dev Helper function for calculateRedeemTokenPrice
     * @dev Called indirectly by `xSNX.burn`
     * @dev Calculates NAV of the fund, excluding value of escrowed SNX, in ETH terms
     * @param weiPerOneSnx: SNX price in ETH terms
     * @param snxBalanceOwned: non-escrowed SNX balance
     * @param contractDebtValueInWei: sUSD debt balance of fund in ETH terms
     */
    function calculateNetAssetValueOnRedeem(
        uint256 weiPerOneSnx,
        uint256 snxBalanceOwned,
        uint256 contractDebtValueInWei
    ) internal view returns (uint256) {
        uint256 snxTokenValueInWei = snxBalanceOwned.mul(weiPerOneSnx).div(
            DEC_18
        );
        uint256 nonSnxAssetValue = calculateNonSnxAssetValue();
        return
            snxTokenValueInWei.add(nonSnxAssetValue).sub(
                contractDebtValueInWei
            );
    }

    /*
     * @dev NAV value of non-SNX assets, computed in ETH terms
     */
    function calculateNonSnxAssetValue() internal view returns (uint256) {
        return getSetHoldingsValueInWei().add(getEthBalance());
    }

    /*
     * @dev SNX price in ETH terms, calculated for purposes of redemption NAV
     * @notice Return value discounted slightly to better represent liquidation price
     */
    function getWeiPerOneSnxOnRedeem()
        internal
        view
        returns (uint256 weiPerOneSnx)
    {
        uint256 snxUsdPrice = getSnxPrice();
        uint256 ethUsdPrice = getSynthPrice(seth);
        weiPerOneSnx = snxUsdPrice
            .mul(DEC_18)
            .div(ethUsdPrice)
            .mul(SLIPPAGE_RATE) // used to better represent liquidation price as volume scales
            .div(PERCENT);
    }

    /*
     * @dev Returns Synthetix synth symbol for asset currently held in TokenSet (e.g., sETH for WETH)
     * @notice xSNX contract complex only compatible with Sets that hold a single asset at a time
     */
    function getActiveAssetSynthSymbol()
        internal
        view
        returns (bytes32 synthSymbol)
    {
        synthSymbol = getAssetCurrentlyActiveInSet() == setComponentAddresses[0]
            ? (synthSymbols[0])
            : (synthSymbols[1]);
    }

    /*
     * @dev Returns SNX price in ETH terms, calculated for purposes of issuance NAV (when allocateToEth)
     */
    function getWeiPerOneSnxOnMint() internal view returns (uint256) {
        uint256 snxUsd = getSynthPrice(snx);
        uint256 ethUsd = getSynthPrice(seth);
        return snxUsd.mul(DEC_18).div(ethUsd);
    }

    /*
     * @dev Single use function to define initial xSNX issuance
     */
    function getInitialSupply() internal view returns (uint256) {
        return
            IERC20(addressResolver.getAddress(synthetixName))
                .balanceOf(xSNXAdminInstance)
                .mul(INITIAL_SUPPLY_MULTIPLIER);
    }

    /*
     * @dev Helper function for `xSNX.mint` that calculates token issuance
     * @param snxBalanceBefore: SNX balance pre-mint
     * @param ethContributed: ETH payable on mint, less fees
     * @param nonSnxAssetValue: NAV of non-SNX slice of fund
     * @param totalSupply: xSNX.totalSupply()
     */
    function calculateTokensToMintWithEth(
        uint256 snxBalanceBefore,
        uint256 ethContributed,
        uint256 nonSnxAssetValue,
        uint256 totalSupply
    ) public view returns (uint256) {
        if (totalSupply == 0) {
            return getInitialSupply();
        }

        uint256 pricePerToken = calculateIssueTokenPrice(
            getWeiPerOneSnxOnMint(),
            snxBalanceBefore,
            nonSnxAssetValue,
            totalSupply
        );

        return ethContributed.mul(DEC_18).div(pricePerToken);
    }

    /*
     * @dev Helper function for `xSNX.mintWithSnx` that calculates token issuance
     * @param snxBalanceBefore: SNX balance pre-mint
     * @param snxAddedToBalance: SNX contributed by mint
     * @param totalSupply: xSNX.totalSupply()
     */
    function calculateTokensToMintWithSnx(
        uint256 snxBalanceBefore,
        uint256 snxAddedToBalance,
        uint256 totalSupply
    ) public view returns (uint256) {
        if (totalSupply == 0) {
            return getInitialSupply();
        }

        uint256 weiPerOneSnx = getWeiPerOneSnxOnMint();
        // need to derive snx contribution in eth terms for NAV calc
        uint256 proxyEthContribution = weiPerOneSnx.mul(snxAddedToBalance).div(
            DEC_18
        );
        uint256 nonSnxAssetValue = calculateNonSnxAssetValue();
        uint256 pricePerToken = calculateIssueTokenPrice(
            weiPerOneSnx,
            snxBalanceBefore,
            nonSnxAssetValue,
            totalSupply
        );
        return proxyEthContribution.mul(DEC_18).div(pricePerToken);
    }

    /*
     * @dev Called indirectly by `xSNX.mint` and `xSNX.mintWithSnx`
     * @dev Calculates token price on issuance, including value of escrowed SNX
     * @param weiPerOneSnx: SNX price in ETH terms
     * @param snxBalanceBefore: SNX balance pre-mint
     * @param nonSnxAssetValue: Non-SNX slice of fund
     * @param totalSupply: xSNX.totalSupply()
     */
    function calculateIssueTokenPrice(
        uint256 weiPerOneSnx,
        uint256 snxBalanceBefore,
        uint256 nonSnxAssetValue,
        uint256 totalSupply
    ) public view returns (uint256 pricePerToken) {
        pricePerToken = calculateNetAssetValueOnMint(
            weiPerOneSnx,
            snxBalanceBefore,
            nonSnxAssetValue
        )
            .mul(DEC_18)
            .div(totalSupply);
    }

    /*
     * @dev Called indirectly by `xSNX.burn`
     * @dev Calculates token price on redemption, excluding value of escrowed SNX
     * @param totalSupply: xSNX.totalSupply()
     * @param snxBalanceOwned: non-escrowed SNX balance
     * @param contractDebtValue: sUSD debt in USD terms
     */
    function calculateRedeemTokenPrice(
        uint256 totalSupply,
        uint256 snxBalanceOwned,
        uint256 contractDebtValue
    ) public view returns (uint256 pricePerToken) {
        // SNX won't actually be sold (burns are only distributed in available ETH) but
        // this is a proxy for the return value of SNX that would be sold
        uint256 weiPerOneSnx = getWeiPerOneSnxOnRedeem();

        uint256 debtValueInWei = calculateDebtValueInWei(contractDebtValue);
        pricePerToken = calculateNetAssetValueOnRedeem(
            weiPerOneSnx,
            snxBalanceOwned,
            debtValueInWei
        )
            .mul(DEC_18)
            .div(totalSupply);
    }

    /* ========================================================================================= */
    /*                                          Set                                              */
    /* ========================================================================================= */

    /*
     * @dev Balance of underlying asset "active" in Set (e.g., WETH or USDC)
     */
    function getActiveSetAssetBalance() public view returns (uint256) {
        return
            IERC20(getAssetCurrentlyActiveInSet()).balanceOf(xSNXAdminInstance);
    }

    /*
     * @dev Calculates quantity of Set Token equivalent to quantity of underlying asset token
     * @notice rebalancingSetQuantity return value is reduced slightly to ensure successful execution
     * @param componentQuantity: balance of underlying Set asset, e.g., WETH
     */
    function calculateSetQuantity(uint256 componentQuantity)
        public
        view
        returns (uint256 rebalancingSetQuantity)
    {
        uint256 baseSetNaturalUnit = getBaseSetNaturalUnit();
        uint256 baseSetComponentUnits = getBaseSetComponentUnits();
        uint256 baseSetIssuable = componentQuantity.mul(baseSetNaturalUnit).div(
            baseSetComponentUnits
        );

        uint256 rebalancingSetNaturalUnit = getSetNaturalUnit();
        uint256 unitShares = getSetUnitShares();
        rebalancingSetQuantity = baseSetIssuable
            .mul(rebalancingSetNaturalUnit)
            .div(unitShares)
            .mul(99) // ensure sufficient balance in underlying asset
            .div(100)
            .div(rebalancingSetNaturalUnit)
            .mul(rebalancingSetNaturalUnit);
    }

    /*
     * @dev Calculates mintable quantity of Set Token given asset holdings
     */
    function calculateSetIssuanceQuantity()
        public
        view
        returns (uint256 rebalancingSetIssuable)
    {
        uint256 componentQuantity = getActiveSetAssetBalance();
        rebalancingSetIssuable = calculateSetQuantity(componentQuantity);
    }

    /*
     * @dev Calculates Set token to sell given sUSD burn requirements
     * @param totalSusdToBurn: sUSD to burn to fix ratio or unlock staked SNX
     */
    function calculateSetRedemptionQuantity(uint256 totalSusdToBurn)
        public
        view
        returns (uint256 rebalancingSetRedeemable)
    {
        address currentSetAsset = getAssetCurrentlyActiveInSet();

        bytes32 activeAssetSynthSymbol = getActiveAssetSynthSymbol();
        uint256 synthUsd = getSynthPrice(activeAssetSynthSymbol);

        // expectedSetAssetRate = amount of current set asset needed to redeem for 1 sUSD
        uint256 expectedSetAssetRate = DEC_18.mul(DEC_18).div(synthUsd);

        uint256 setAssetCollateralToSell = expectedSetAssetRate
            .mul(totalSusdToBurn)
            .div(DEC_18)
            .mul(103) // err on the high side
            .div(PERCENT);

        uint256 decimals = (TEN**ERC20Detailed(currentSetAsset).decimals());
        setAssetCollateralToSell = setAssetCollateralToSell.mul(decimals).div(
            DEC_18
        );

        rebalancingSetRedeemable = calculateSetQuantity(
            setAssetCollateralToSell
        );
    }

    /*
     * @dev Calculates value of a single 1e18 Set unit in ETH terms
     */
    function calculateEthValueOfOneSetUnit()
        internal
        view
        returns (uint256 ethValue)
    {
        uint256 unitShares = getSetUnitShares();
        uint256 rebalancingSetNaturalUnit = getSetNaturalUnit();
        uint256 baseSetRequired = DEC_18.mul(unitShares).div(
            rebalancingSetNaturalUnit
        );

        uint256 unitsOfUnderlying = getBaseSetComponentUnits();
        uint256 baseSetNaturalUnit = getBaseSetNaturalUnit();
        uint256 componentRequired = baseSetRequired.mul(unitsOfUnderlying).div(
            baseSetNaturalUnit
        );

        address currentSetAsset = getAssetCurrentlyActiveInSet();
        uint256 decimals = (TEN**ERC20Detailed(currentSetAsset).decimals());
        componentRequired = componentRequired.mul(DEC_18).div(decimals);

        bytes32 activeAssetSynthSymbol = getActiveAssetSynthSymbol();

        uint256 synthUsd = getSynthPrice(activeAssetSynthSymbol);
        uint256 ethUsd = getSynthPrice(seth);
        ethValue = componentRequired.mul(synthUsd).div(ethUsd);
    }

    /*
     * @dev Calculates value of Set Holdings in ETH terms
     */
    function getSetHoldingsValueInWei()
        public
        view
        returns (uint256 setValInWei)
    {
        uint256 setCollateralTokens = getSetCollateralTokens();
        bytes32 synthSymbol = getActiveAssetSynthSymbol();
        address currentSetAsset = getAssetCurrentlyActiveInSet();

        uint256 synthUsd = getSynthPrice(synthSymbol);
        uint256 ethUsd = getSynthPrice(seth);

        uint256 decimals = (TEN**ERC20Detailed(currentSetAsset).decimals());
        setCollateralTokens = setCollateralTokens.mul(DEC_18).div(decimals);
        setValInWei = setCollateralTokens.mul(synthUsd).div(ethUsd);
    }

    function getBaseSetNaturalUnit() internal view returns (uint256) {
        return getCurrentCollateralSet().naturalUnit();
    }

    /*
     * @dev Outputs current active Set asset
     * @notice xSNX contracts complex only compatible with Sets that hold a single asset at a time
     */
    function getAssetCurrentlyActiveInSet() public view returns (address) {
        address[] memory currentAllocation = getCurrentCollateralSet()
            .getComponents();
        return currentAllocation[0];
    }

    function getCurrentCollateralSet()
        internal
        view
        returns (ISetAssetBaseCollateral)
    {
        return ISetAssetBaseCollateral(getCurrentSet());
    }

    function getCurrentSet() internal view returns (address) {
        return ISetToken(setAddress).currentSet();
    }

    /*
     * @dev Returns the number of underlying tokens in the current Set asset
     * e.g., the contract's Set holdings are collateralized by 10.4 WETH
     */
    function getSetCollateralTokens() internal view returns (uint256) {
        return
            getSetBalanceCollateral().mul(getBaseSetComponentUnits()).div(
                getBaseSetNaturalUnit()
            );
    }

    function getSetBalanceCollateral() internal view returns (uint256) {
        uint256 unitShares = getSetUnitShares();
        uint256 naturalUnit = getSetNaturalUnit();
        return getContractSetBalance().mul(unitShares).div(naturalUnit);
    }

    function getSetUnitShares() internal view returns (uint256) {
        return ISetToken(setAddress).unitShares();
    }

    function getSetNaturalUnit() internal view returns (uint256) {
        return ISetToken(setAddress).naturalUnit();
    }

    function getContractSetBalance() internal view returns (uint256) {
        return IERC20(setAddress).balanceOf(xSNXAdminInstance);
    }

    function getBaseSetComponentUnits() internal view returns (uint256) {
        return ISetAssetBaseCollateral(getCurrentSet()).getUnits()[0];
    }

    /* ========================================================================================= */
    /*                                         Synthetix	                                     */
    /* ========================================================================================= */

    function getSusdBalance() public view returns (uint256) {
        return IERC20(susdAddress).balanceOf(xSNXAdminInstance);
    }

    function getSnxBalance() public view returns (uint256) {
        return getSnxBalanceOwned().add(getSnxBalanceEscrowed());
    }

    function getSnxBalanceOwned() internal view returns (uint256) {
        return
            IERC20(addressResolver.getAddress(synthetixName)).balanceOf(
                xSNXAdminInstance
            );
    }

    function getSnxBalanceEscrowed() internal view returns (uint256) {
        return
            IRewardEscrowV2(addressResolver.getAddress(rewardEscrowV2Name))
                .balanceOf(xSNXAdminInstance);
    }

    function getContractEscrowedSnxValue() internal view returns (uint256) {
        return getSnxBalanceEscrowed().mul(getSnxPrice()).div(DEC_18);
    }

    function getContractOwnedSnxValue() internal view returns (uint256) {
        return getSnxBalanceOwned().mul(getSnxPrice()).div(DEC_18);
    }

    function getSnxPrice() internal view returns (uint256) {
        (uint256 rate, uint256 time) = IExchangeRates(
            addressResolver.getAddress(exchangeRatesName)
        )
            .rateAndUpdatedTime(snx);
        require(time.add(RATE_STALE_TIME_NEW) > block.timestamp, "Rate stale");
        return rate;
    }

    function getSynthPrice(bytes32 synth) internal view returns (uint256) {
        (uint256 rate, uint256 time) = IExchangeRates(
            addressResolver.getAddress(exchangeRatesName)
        )
            .rateAndUpdatedTime(synth);
        if (synth != susd) {
            require(time.add(RATE_STALE_TIME_NEW) > block.timestamp, "Rate stale");
        }
        return rate;
    }

    /*
     * @dev Converts sUSD debt value into ETH terms
     * @param debtValue: sUSD-denominated debt value
     */
    function calculateDebtValueInWei(uint256 debtValue)
        internal
        view
        returns (uint256 debtBalanceInWei)
    {
        uint256 ethUsd = getSynthPrice(seth);
        debtBalanceInWei = debtValue.mul(DEC_18).div(ethUsd);
    }

    function getContractDebtValue() internal view returns (uint256) {
        return
            ISynthetix(addressResolver.getAddress(synthetixName)).debtBalanceOf(
                xSNXAdminInstance,
                susd
            );
    }

    /*
     * @notice Returns inverse of target C-RATIO
     */
    function getIssuanceRatio() internal view returns (uint256) {
        return
            ISystemSettings(addressResolver.getAddress(systemSettingsName))
                .issuanceRatio();
    }

    /*
     * @notice Returns NAV contribution of SNX holdings in USD terms
     */
    function getContractSnxValue() internal view returns (uint256) {
        return getSnxBalance().mul(getSnxPrice()).div(DEC_18);
    }

    /* ========================================================================================= */
    /*                                       Burning sUSD                                        */
    /* ========================================================================================= */

    /*
     * @dev Calculates sUSD to burn to restore C-RATIO
     * @param snxValueHeld: USD value of SNX
     * @param contractDebtValue: USD value of sUSD debt
     * @param issuanceRatio: Synthetix C-RATIO requirement
     */
    function calculateSusdToBurnToFixRatio(
        uint256 snxValueHeld,
        uint256 contractDebtValue,
        uint256 issuanceRatio
    ) internal pure returns (uint256) {
        uint256 subtractor = issuanceRatio.mul(snxValueHeld).div(DEC_18);

        if (subtractor > contractDebtValue) return 0;
        return contractDebtValue.sub(subtractor);
    }

    /*
     * @dev Calculates sUSD to burn to restore C-RATIO
     */
    function calculateSusdToBurnToFixRatioExternal()
        public
        view
        returns (uint256)
    {
        uint256 snxValueHeld = getContractSnxValue();
        uint256 debtValue = getContractDebtValue();
        uint256 issuanceRatio = getIssuanceRatio();
        return
            calculateSusdToBurnToFixRatio(
                snxValueHeld,
                debtValue,
                issuanceRatio
            );
    }

    /*
     * @dev Calculates sUSD to burn to eclipse value of escrowed SNX
     * @notice Synthetix system requires escrowed SNX to be "unlocked" first
     * @param issuanceRatio: Synthetix C-RATIO requirement
     */
    function calculateSusdToBurnToEclipseEscrowed(uint256 issuanceRatio)
        public
        view
        returns (uint256)
    {
        uint256 escrowedSnxValue = getContractEscrowedSnxValue();
        if (escrowedSnxValue == 0) return 0;

        return escrowedSnxValue.mul(issuanceRatio).div(DEC_18);
    }

    /*
     * @dev Helper function to calculate sUSD burn required for a potential redemption
     * @param tokensToRedeem: potential tokens to burn
     * @param totalSupply: xSNX.totalSupply()
     * @param contractDebtValue: sUSD debt value
     * @param issuanceRatio: Synthetix C-RATIO requirement
     */
    function calculateSusdToBurnForRedemption(
        uint256 tokensToRedeem,
        uint256 totalSupply,
        uint256 contractDebtValue,
        uint256 issuanceRatio
    ) public view returns (uint256 susdToBurn) {
        uint256 nonEscrowedSnxValue = getContractOwnedSnxValue();
        uint256 lockedSnxValue = contractDebtValue.mul(DEC_18).div(
            issuanceRatio
        );
        uint256 valueOfSnxToSell = nonEscrowedSnxValue.mul(tokensToRedeem).div(
            totalSupply
        );
        susdToBurn = (
            lockedSnxValue.add(valueOfSnxToSell).sub(nonEscrowedSnxValue)
        )
            .mul(issuanceRatio)
            .div(DEC_18);
    }

    /* ========================================================================================= */
    /*                                        Rebalances                                         */
    /* ========================================================================================= */

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsHedge()
     */
    function calculateAssetChangesForRebalanceToHedge()
        internal
        view
        returns (uint256 totalSusdToBurn, uint256 snxToSell)
    {
        uint256 snxValueHeld = getContractSnxValue();
        uint256 debtValueInUsd = getContractDebtValue();
        uint256 issuanceRatio = getIssuanceRatio();

        uint256 susdToBurnToFixRatio = calculateSusdToBurnToFixRatio(
            snxValueHeld,
            debtValueInUsd,
            issuanceRatio
        );


            uint256 susdToBurnToEclipseEscrowed
         = calculateSusdToBurnToEclipseEscrowed(issuanceRatio);

        uint256 hedgeAssetsValueInUsd = calculateHedgeAssetsValueInUsd();
        uint256 valueToUnlockInUsd = debtValueInUsd.sub(hedgeAssetsValueInUsd);

        uint256 susdToBurnToUnlockTransfer = valueToUnlockInUsd
            .mul(issuanceRatio)
            .div(DEC_18);

        totalSusdToBurn = (
            susdToBurnToFixRatio.add(susdToBurnToEclipseEscrowed).add(
                susdToBurnToUnlockTransfer
            )
        );
        snxToSell = valueToUnlockInUsd.mul(DEC_18).div(getSnxPrice());
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsSnx()
     */
    function calculateAssetChangesForRebalanceToSnx()
        public
        view
        returns (uint256 setToSell)
    {
        (
            uint256 debtValueInWei,
            uint256 hedgeAssetsBalance
        ) = getRebalanceUtils();
        uint256 setValueToSell = hedgeAssetsBalance.sub(debtValueInWei);
        uint256 ethValueOfOneSet = calculateEthValueOfOneSetUnit();
        setToSell = setValueToSell.mul(DEC_18).div(ethValueOfOneSet);

        // Set quantity must be multiple of natural unit
        uint256 naturalUnit = getSetNaturalUnit();
        setToSell = setToSell.div(naturalUnit).mul(naturalUnit);
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsSnx()
     */
    function getRebalanceTowardsSnxUtils()
        public
        view
        returns (uint256 setToSell, address activeAsset)
    {
        setToSell = calculateAssetChangesForRebalanceToSnx();
        activeAsset = getAssetCurrentlyActiveInSet();
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsSnx(), xSNXAdmin.rebalanceTowardsHedge()
     * @dev Denominated in ETH terms
     */
    function getRebalanceUtils()
        public
        view
        returns (uint256 debtValueInWei, uint256 hedgeAssetsBalance)
    {
        uint256 setHoldingsInWei = getSetHoldingsValueInWei();
        uint256 ethBalance = getEthBalance();

        uint256 debtValue = getContractDebtValue();
        debtValueInWei = calculateDebtValueInWei(debtValue);
        hedgeAssetsBalance = setHoldingsInWei.add(ethBalance);
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsHedge()
     * @dev Denominated in USD terms
     */
    function calculateHedgeAssetsValueInUsd()
        internal
        view
        returns (uint256 hedgeAssetsValueInUsd)
    {
        address currentSetAsset = getAssetCurrentlyActiveInSet();
        uint256 decimals = (TEN**ERC20Detailed(currentSetAsset).decimals());
        uint256 setCollateralTokens = getSetCollateralTokens();
        setCollateralTokens = setCollateralTokens.mul(DEC_18).div(decimals);

        bytes32 activeAssetSynthSymbol = getActiveAssetSynthSymbol();

        uint256 synthUsd = getSynthPrice(activeAssetSynthSymbol);
        uint256 setValueUsd = setCollateralTokens.mul(synthUsd).div(DEC_18);

        uint256 ethBalance = getEthBalance();
        uint256 ethUsd = getSynthPrice(seth);
        uint256 ethValueUsd = ethBalance.mul(ethUsd).div(DEC_18);

        hedgeAssetsValueInUsd = setValueUsd.add(ethValueUsd);
    }

    /*
     * @dev Helper function to determine whether xSNXAdmin.rebalanceTowardsSnx() is required
     */
    function isRebalanceTowardsSnxRequired() public view returns (bool) {
        (
            uint256 debtValueInWei,
            uint256 hedgeAssetsBalance
        ) = getRebalanceUtils();

        if (
            debtValueInWei.mul(REBALANCE_THRESHOLD).div(PERCENT) <
            hedgeAssetsBalance
        ) {
            return true;
        }

        return false;
    }

    /*
     * @dev Helper function to determine whether xSNXAdmin.rebalanceTowardsHedge() is required
     */
    function isRebalanceTowardsHedgeRequired() public view returns (bool) {
        (
            uint256 debtValueInWei,
            uint256 hedgeAssetsBalance
        ) = getRebalanceUtils();

        if (
            hedgeAssetsBalance.mul(REBALANCE_THRESHOLD).div(PERCENT) <
            debtValueInWei
        ) {
            return true;
        }

        return false;
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceTowardsHedge()
     * @notice Will fail if !isRebalanceTowardsHedgeRequired()
     */
    function getRebalanceTowardsHedgeUtils()
        public
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        (
            uint256 totalSusdToBurn,
            uint256 snxToSell
        ) = calculateAssetChangesForRebalanceToHedge();
        address activeAsset = getAssetCurrentlyActiveInSet();
        return (totalSusdToBurn, snxToSell, activeAsset);
    }

    /*
     * @dev Helper for `hedge` function
     * @dev Determines share of sUSD to allocate to ETH
     * @dev Implicitly determines Set allocation as well
     * @param susdBal: sUSD balance post minting
     */
    function getEthAllocationOnHedge(uint256 susdBal)
        public
        view
        returns (uint256 ethAllocation)
    {
        uint256 ethUsd = getSynthPrice(seth);

        uint256 setHoldingsInUsd = getSetHoldingsValueInWei().mul(ethUsd).div(
            DEC_18
        );
        uint256 ethBalInUsd = getEthBalance().mul(ethUsd).div(DEC_18);
        uint256 hedgeAssets = setHoldingsInUsd.add(ethBalInUsd);

        if (ethBalInUsd.mul(ETH_TARGET) >= hedgeAssets.add(susdBal)) {
            // full bal directed toward Set
            // eth allocation is 0
        } else if ((ethBalInUsd.add(susdBal)).mul(ETH_TARGET) < hedgeAssets) {
            // full bal directed toward Eth
            ethAllocation = susdBal;
        } else {
            // fractionate allocation
            ethAllocation = ((hedgeAssets.add(susdBal)).div(ETH_TARGET)).sub(
                ethBalInUsd
            );
        }
    }

    /*
     * @dev Helper function to facilitate xSNXAdmin.rebalanceSetToEth()
     */
    function calculateSetToSellForRebalanceSetToEth()
        public
        view
        returns (uint256 setQuantityToSell)
    {
        uint256 setHoldingsInWei = getSetHoldingsValueInWei();
        uint256 ethBal = getEthBalance();
        uint256 hedgeAssets = setHoldingsInWei.add(ethBal);
        require(
            ethBal.mul(ETH_TARGET) < hedgeAssets,
            "Rebalance not necessary"
        );

        uint256 ethToAdd = ((hedgeAssets.div(ETH_TARGET)).sub(ethBal));
        setQuantityToSell = getContractSetBalance().mul(ethToAdd).div(
            setHoldingsInWei
        );

        uint256 naturalUnit = getSetNaturalUnit();
        setQuantityToSell = setQuantityToSell.div(naturalUnit).mul(naturalUnit);
    }

    /* ========================================================================================= */
    /*                                     Address Setters                                       */
    /* ========================================================================================= */

    function setAdminInstanceAddress(address _xSNXAdminInstance)
        public
        onlyOwner
    {
        if (xSNXAdminInstance == address(0)) {
            xSNXAdminInstance = _xSNXAdminInstance;
        }
    }

    function setCurve(
        address curvePoolAddress,
        int128 _usdcIndex,
        int128 _susdIndex
    ) public onlyOwner {
        if (address(curveFi) == address(0)) {
            // if initial set on deployment, immediately activate Curve address
            curveFi = ICurveFi(curvePoolAddress);
            nextCurveAddress = curvePoolAddress;
        } else {
            // if updating Curve address (i.e., not initial setting of address on deployment),
            // store nextCurveAddress but don't activate until addressValidator has confirmed
            nextCurveAddress = curvePoolAddress;
        }
        usdcIndex = _usdcIndex;
        susdIndex = _susdIndex;
    }

    /* ========================================================================================= */
    /*                                   		 Utils           		                         */
    /* ========================================================================================= */

    // admin on deployment approve [snx, susd, setComponentA, setComponentB]
    function approveKyber(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).approve(address(kyberNetworkProxy), MAX_UINT);
    }

    // admin on deployment approve [susd, usdc]
    function approveCurve(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).approve(address(curveFi), MAX_UINT);
    }

    function confirmCurveAddress(address _nextCurveAddress) public {
        require(msg.sender == addressValidator, "Incorrect caller");
        require(nextCurveAddress == _nextCurveAddress, "Addresses don't match");
        curveFi = ICurveFi(nextCurveAddress);
    }

    function() external payable {}
}

// File: contracts/helpers/Pausable.sol

pragma solidity ^0.5.15;


/* Adapted from OpenZeppelin */
contract Pausable is Initializable {
    /**
     * @dev Emitted when the pause is triggered by a pauser.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted by a pauser.
     */
    event Unpaused();

    bool private _paused;
    address public pauser;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
        pauser = msg.sender;
    }

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer. This function is called when the contract is used in a upgradeable context.
     */
    function initialize(address sender) public initializer {
        _paused = false;
        pauser = sender;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused();
    }

    modifier onlyPauser {
        require(msg.sender == pauser, "Don't have rights");
        _;
    }
}

// File: contracts/interface/IxSNXAdmin.sol

pragma solidity 0.5.15;

contract IxSNXAdmin {
    function sendEthOnRedemption(uint valueToRedeem) external;
}

// File: contracts/xSNX.sol

pragma solidity 0.5.15;










contract xSNX is ERC20, ERC20Detailed, Pausable, Ownable {
    TradeAccounting private tradeAccounting;
    IKyberNetworkProxy private kyberNetworkProxy;

    address xsnxAdmin;
    address snxAddress;
    address susdAddress;

    uint256 public withdrawableEthFees;

    function initialize(
        address payable _tradeAccountingAddress,
        address _kyberProxyAddress,
        address _snxAddress,
        address _susdAddress,
        address _xsnxAdmin,
        address _ownerAddress,
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor,
        uint256 _initialMint
    ) public initializer {
        Ownable.initialize(_ownerAddress);
        ERC20Detailed.initialize("xSNX", "xSNXa", 18);
        Pausable.initialize(_ownerAddress);

        tradeAccounting = TradeAccounting(_tradeAccountingAddress);
        kyberNetworkProxy = IKyberNetworkProxy(_kyberProxyAddress);
        snxAddress = _snxAddress;
        susdAddress = _susdAddress;
        xsnxAdmin = _xsnxAdmin;

        _setFeeDivisors(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
        _mint(msg.sender, _initialMint);
    }

    event Mint(
        address indexed user,
        uint256 timestamp,
        uint256 valueSent,
        uint256 mintAmount,
        bool mintWithEth
    );
    event Burn(
        address indexed user,
        uint256 timestamp,
        uint256 burnAmount,
        uint256 valueToSend
    );
    event WithdrawFees(
        uint256 ethAmount,
        uint256 susdAmount,
        uint256 snxAmount
    );

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    // addresses are locked from transfer after minting or burning
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    /*
     * @notice Mint new xSNX tokens from the contract by sending ETH
     * @dev Exchanges ETH for SNX
     * @dev Min rate ETH/SNX sourced from Kyber in JS
     * @dev: Calculates overall fund NAV in ETH terms, using ETH/SNX implicit conversion rate
     * or ETH/SNX price (via SNX oracle) in case of allocateToEth
     * @dev: Mints/distributes new xSNX tokens based on contribution to NAV
     * @param: minRate: kyberProxy.getExpectedRate eth=>snx
     */
    function mint(uint256 minRate) external payable whenNotPaused notLocked(msg.sender) {
        require(msg.value > 0, "Must send ETH");
        lock(msg.sender);

        uint256 fee = calculateFee(msg.value, feeDivisors.mintFee);
        uint256 ethContribution = msg.value.sub(fee);
        uint256 snxBalanceBefore = tradeAccounting.getSnxBalance();

        uint256 totalSupply = totalSupply();
        (bool allocateToEth, uint256 nonSnxAssetValue) = tradeAccounting
            .getMintWithEthUtils(totalSupply);

        if (!allocateToEth) {
            uint256 snxAcquired = kyberNetworkProxy.swapEtherToToken.value(
                ethContribution
            )(ERC20(snxAddress), minRate);
            require(
                IERC20(snxAddress).transfer(xsnxAdmin, snxAcquired),
                "Transfer failed"
            );
        } else {
            (bool success, ) = xsnxAdmin.call.value(ethContribution)("");
            require(success, "Transfer failed");
        }

        uint256 mintAmount = tradeAccounting.calculateTokensToMintWithEth(
            snxBalanceBefore,
            ethContribution,
            nonSnxAssetValue,
            totalSupply
        );

        emit Mint(msg.sender, block.timestamp, msg.value, mintAmount, true);
        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Mint new xSNX tokens from the contract by sending SNX
     * @notice Won't run without ERC20 approval
     * @dev: Calculates overall fund NAV in ETH terms, using ETH/SNX price (via SNX oracle)
     * @dev: Mints/distributes new xSNX tokens based on contribution to NAV
     * @param: snxAmount: SNX to contribute
     */
    function mintWithSnx(uint256 snxAmount) external whenNotPaused notLocked(msg.sender) {
        require(snxAmount > 0, "Must send SNX");
        lock(msg.sender);
        uint256 snxBalanceBefore = tradeAccounting.getSnxBalance();

        uint256 fee = calculateFee(snxAmount, feeDivisors.mintFee);
        uint256 snxContribution = snxAmount.sub(fee);

        require(
            IERC20(snxAddress).transferFrom(msg.sender, address(this), fee),
            "Transfer failed"
        );
        require(
            IERC20(snxAddress).transferFrom(
                msg.sender,
                xsnxAdmin,
                snxContribution
            ),
            "Transfer failed"
        );

        uint256 mintAmount = tradeAccounting.calculateTokensToMintWithSnx(
            snxBalanceBefore,
            snxContribution,
            totalSupply()
        );

        emit Mint(
            msg.sender,
            block.timestamp,
            snxContribution,
            mintAmount,
            false
        );
        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Redeems and burns xSNX tokens and sends ETH to user
     * @dev Checks if ETH reserve is sufficient to settle redeem obligation
     * @dev Will only redeem if ETH reserve is sufficient
     * @param tokensToRedeem
     */
    function burn(uint256 tokensToRedeem) external notLocked(msg.sender) {
        require(tokensToRedeem > 0, "Must burn tokens");
        lock(msg.sender);

        uint256 valueToRedeem = tradeAccounting.calculateRedemptionValue(
            totalSupply(),
            tokensToRedeem
        );

        require(
            tradeAccounting.getEthBalance() >= valueToRedeem,
            "Redeem amount exceeds available liquidity"
        );

        IxSNXAdmin(xsnxAdmin).sendEthOnRedemption(valueToRedeem);
        uint256 valueToSend = valueToRedeem.sub(
            calculateFee(valueToRedeem, feeDivisors.burnFee)
        );
        super._burn(msg.sender, tokensToRedeem);
        emit Burn(msg.sender, block.timestamp, tokensToRedeem, valueToSend);

        (bool success, ) = msg.sender.call.value(valueToSend)("");
        require(success, "Burn transfer failed");
    }

    function transfer(address recipient, uint256 amount)
        public
        notLocked(msg.sender)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function calculateFee(uint256 _value, uint256 _feeDivisor)
        internal
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 2%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) public onlyOwner {
        _setFeeDivisors(mintFeeDivisor, burnFeeDivisor, claimFeeDivisor);
    }

    function _setFeeDivisors(
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) private {
        require(_mintFeeDivisor == 0 || _mintFeeDivisor >= 50, "Invalid fee");
        require(_burnFeeDivisor == 0 || _burnFeeDivisor >= 100, "Invalid fee");
        require(_claimFeeDivisor >= 25, "Invalid fee");
        feeDivisors.mintFee = _mintFeeDivisor;
        feeDivisors.burnFee = _burnFeeDivisor;
        feeDivisors.claimFee = _claimFeeDivisor;
    }

    /*
     * @notice Withdraws ETH, sUSD and SNX fees to owner address
     */
    function withdrawFees() public onlyOwner {
        uint256 ethFeesToWithdraw = address(this).balance;
        uint256 susdFeesToWithdraw = IERC20(susdAddress).balanceOf(
            address(this)
        );
        uint256 snxFeesToWithdraw = IERC20(snxAddress).balanceOf(address(this));

        (bool success, ) = msg.sender.call.value(ethFeesToWithdraw)("");
        require(success, "Transfer failed");

        IERC20(susdAddress).transfer(msg.sender, susdFeesToWithdraw);
        IERC20(snxAddress).transfer(msg.sender, snxFeesToWithdraw);

        emit WithdrawFees(
            ethFeesToWithdraw,
            susdFeesToWithdraw,
            snxFeesToWithdraw
        );
    }

    /*
     * @notice Emergency function in case of errant transfer of
     * xSNX token directly to contract
     */
    function withdrawNativeToken() public onlyOwner {
        uint256 tokenBal = balanceOf(address(this));
        if (tokenBal > 0) {
            IERC20(address(this)).transfer(msg.sender, tokenBal);
        }
    }

    /*
     * @dev Helper function for xSNXAdmin to calculate and
     * transfer claim fees
     */
    function getClaimFeeDivisor() public view returns (uint256) {
        return feeDivisors.claimFee;
    }

    /**
     *  BlockLock logic: Implements locking of mint, burn, transfer and transferFrom
     *  functions via a notLocked modifier.
     *  Functions are locked per address.
     */
    modifier notLocked(address lockedAddress) {
        require(
            lastLockedBlock[lockedAddress] <= block.number,
            "Function is temporarily locked for this address"
        );
        _;
    }

    /**
     * @dev Lock mint, burn, transfer and transferFrom functions
     *      for _address for BLOCK_LOCK_COUNT blocks
     */
    function lock(address _address) private {
        lastLockedBlock[_address] = block.number + BLOCK_LOCK_COUNT;
    }

    function() external payable {
        require(msg.sender == xsnxAdmin, "Invalid send");
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: contracts/@openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/@openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/@openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     * Counterpart to Solidity's `+` operator.
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
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     * - Subtraction cannot overflow.
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     * Counterpart to Solidity's `*` operator.
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
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/@openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}

// File: contracts/@openzeppelin/contracts/token/ERC20/IERC20.sol

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
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/@openzeppelin/contracts/token/ERC20/IERC20Fee.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20Fee standard.
 */
interface IERC20Fee {
    /**
     * @dev Returns the `_basisPointsRate`
     */
    function basisPointsRate() external view returns (uint256);

    /**
     * @dev Returns the `_minimumFee`
     */
    function minimumFee() external view returns (uint256);

    /**
     * @dev Returns the `_maximumFee`
     */
    function maximumFee() external view returns (uint256);

    /**
     * @dev Returns the `_denominator`
     */
    function denominator() external view returns (uint256);

    /**
     * @dev Returns the special fees parameters for account
     * @param account Account address
     * @return A tuple of (uint256, uint256, uint256, bool) types
     */
    function fees(address account)
        external
        view
        returns (uint256, uint256, uint256, bool);

    /**
     * @dev Returns the `_feesCollector`
     */
    function feesCollector() external view returns (address);

    /**
     * @dev Sets contract fees collector to a new account (`newFeesCollector`).
     * @param newFeesCollector Account address of new fees collector
     * @return A bool value indicating whether the operation succeeded
     */
    function setFeesCollector(address newFeesCollector) external returns (bool);

    /**
     * @dev Sets `_basisPointsRate`, `_minimumFee` and `_maximumFee`
     * @param newBasisPointsRate Value of basis rate
     * @param newMinimumFee Value of minimum fee
     * @param newMaximumFee Value of maximum fee
     * @return A bool value indicating whether the operation succeeded
     */
    function setParams(
        uint256 newBasisPointsRate,
        uint256 newMinimumFee,
        uint256 newMaximumFee
    ) external returns (bool);

    /**
     * @dev Sets `basisPointsRate`, `minimumFee` and `maximumFee`
     * for `account` in `_fees` mapping
     * @param account Account address
     * @param newBasisPoints Value for account basis rate
     * @param newMinFee Value of account minimum fee
     * @param newMaxFee Value of account maximum fee
     * @param state Account special fees state (true/false)
     * @return A bool value indicating whether the operation succeeded
     */
    function setSpecialParams(
        address account,
        uint256 newBasisPoints,
        uint256 newMinFee,
        uint256 newMaxFee,
        bool state
    ) external returns (bool);

    /**
     * @dev Emitted when `_basisPointsRate`, `_minimumFee` and `_maximumFee`
     * parameters have been changed.
     */
    event Params(
        uint256 indexed newBasisPoints,
        uint256 indexed newMinFee,
        uint256 indexed newMaxFee
    );

    /**
     * @dev Emitted when `_basisPointsRate`, `_minimumFee` and `_maximumFee`
     * parameters have been changed for specific account.
     */
    event SpecialParams(
        address indexed account,
        uint256 indexed newBasisPoints,
        uint256 newMinFee,
        uint256 newMaxFee
    );

    /**
     * @dev Emitted when fees are moved to fees collector
     */
    event Fee(address indexed _feesCollector, uint256 indexed fee);

    /**
     * @dev Emitted when `_feesCollector` parameter have been changed
     */
    event FeesCollector(
        address indexed _feesCollector,
        address indexed newFeesCollector
    );
}

// File: contracts/@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol, uint8 decimals)
        public
    {
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
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/@openzeppelin/contracts/token/ERC20/ERC20Fee.sol

pragma solidity ^0.5.0;







/**
 * @dev Implementation of the {IERC20Fee} interface.
*/
contract ERC20Fee is Context, Ownable, IERC20, IERC20Fee, ERC20Detailed {
    using SafeMath for uint256;

    struct SpecialFee {
        uint256 basisPointsRate;
        uint256 minimumFee;
        uint256 maximumFee;
        bool isActive;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => SpecialFee) private _fees;

    uint256 private _totalSupply;

    // additional variables for use if transaction fees ever became necessary
    uint256 private _basisPointsRate;
    uint256 private _minimumFee;
    uint256 private _maximumFee;
    uint256 private _denominator;
    address private _feesCollector;

    /**
     * @dev Sets the values for `name`, `symbol`, `decimals`,
     * `_basisPointsRate`, `_maximumFee`, `_feesCollector`
     * and `_denominator`
     * @param name The name of the token
     * @param symbol The symbol of the token 
     * @param decimals The number of decimals the token uses
     * @notice `name`, `symbol`, `decimals` and _denominator
     * values are immutable: they can only be set once during construction
     */
    constructor(string memory name, string memory symbol, uint8 decimals)
        public
        ERC20Detailed(name, symbol, decimals)
    {
        _basisPointsRate = 0;
        _maximumFee = 0;
        _feesCollector = _msgSender();
        _denominator = 10000;
    }

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
     * @dev See {IERC20Fee-basisPointsRate}.
     */
    function basisPointsRate() public view returns (uint256) {
        return _basisPointsRate;
    }

    /**
     * @dev See {IERC20Fee-minimumFee}.
     */
    function minimumFee() public view returns (uint256) {
        return _minimumFee;
    }

    /**
     * @dev See {IERC20Fee-maximumFee}.
     */
    function maximumFee() public view returns (uint256) {
        return _maximumFee;
    }

    /**
     * @dev See {IERC20Fee-denominator}.
     */
    function denominator() public view returns (uint256) {
        return _denominator;
    }

    /**
     * @dev See {IERC20-fees}.
     */
    function fees(address account)
        public
        view
        returns (uint256, uint256, uint256, bool)
    {
        return (
            _fees[account].basisPointsRate,
            _fees[account].minimumFee,
            _fees[account].maximumFee,
            _fees[account].isActive
        );
    }

    /**
     * @dev See {IERC20Fee-feesCollector}.
     */
    function feesCollector() public view returns (address) {
        return _feesCollector;
    }

    /**
     * @dev See {IERC20Fee-setFeesCollector}.
     */
    function setFeesCollector(address newFeesCollector)
        public
        onlyOwner
        returns (bool)
    {
        require(
            newFeesCollector != address(0),
            "SetFeesCollector: new fees collector is the zero address"
        );
        emit FeesCollector(_feesCollector, newFeesCollector);
        _feesCollector = newFeesCollector;
        return true;
    }

    /**
     * @dev See {IERC20Fee-setParams}.
     */
    function setParams(
        uint256 newBasisPoints,
        uint256 newMinFee,
        uint256 newMaxFee
    ) external onlyOwner returns (bool) {
        _basisPointsRate = newBasisPoints;
        _minimumFee = newMinFee;
        _maximumFee = newMaxFee;
        emit Params(newBasisPoints, newMinFee, newMaxFee);
        return true;
    }

    /**
     * @dev See {IERC20Fee-setSpecialParams}.
     */
    function setSpecialParams(
        address account,
        uint256 newBasisPoints,
        uint256 newMinFee,
        uint256 newMaxFee,
        bool state
    ) external onlyOwner returns (bool) {
        SpecialFee memory newSpecialParams = SpecialFee({
            basisPointsRate: newBasisPoints,
            minimumFee: newMinFee,
            maximumFee: newMaxFee,
            isActive: state
        });

        _fees[account] = newSpecialParams;
        emit SpecialParams(account, newBasisPoints, newMinFee, newMaxFee);
        return true;
    }

    /**
     * @dev Calculates fee for a specific`account`
     * @param account Sender account address
     * @param amount Amount of tokens to send
     * @return An uint256 value representing the account fee
     */
    function calculateFee(address account, uint256 amount)
        internal
        view
        returns (uint256)
    {
        (uint256 basisPoints, uint256 minFee, uint256 maxFee, bool active) = fees(
            account
        );

        if (active) {
            uint256 fee = (amount.mul(basisPoints)).div(_denominator);

            if (fee < minFee) fee = minFee;
            else if (fee > maxFee) fee = maxFee;

            return fee;
        }

        uint256 fee = (amount.mul(_basisPointsRate)).div(_denominator);

        if (fee < _minimumFee) fee = _minimumFee;
        else if (fee > _maximumFee) fee = _maximumFee;

        return fee;
    }

    /**
     * @dev See {IERC20-transfer}.
     * Requirements:
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
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * Emits a {Transfer} event.
     * Requirements:
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount)
        internal
    {
        require(
            sender != address(0),
            "ERC20Fee: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "ERC20Fee: transfer to the zero address"
        );

        uint256 fee = calculateFee(sender, amount);

        require(amount >= fee, "ERC20Fee: amount less then fee");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20Fee: transfer amount exceeds balance"
        );

        uint256 sendAmount = amount.sub(fee);

        _balances[recipient] = _balances[recipient].add(sendAmount);
        emit Transfer(sender, recipient, sendAmount);

        if (fee > 0) {
            _balances[_feesCollector] = _balances[_feesCollector].add(fee);
            emit Fee(_feesCollector, fee);
        }

    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements
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
     * Emits a {Transfer} event with `to` set to the zero address.
     * Requirements
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     * Emits an {Approval} event.
     * Requirements:
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
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

// File: contracts/StableCoin.sol

pragma solidity ^0.5.0;



contract StableCoin is ERC20Fee {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    Roles.Role private _burners;

    /**
     * @dev Emitted when account get access to {MinterRole}
     */
    event MinterAdded(address indexed account);

    /**
     * @dev Emitted when account get access to {BurnerRole}
     */
    event BurnerAdded(address indexed account);

    /**
     * @dev Emitted when an account loses access to the {MinterRole}
     */
    event MinterRemoved(address indexed account);

    /**
     * @dev Emitted when an account loses access to the {BurnerRole}
     */
    event BurnerRemoved(address indexed account);

    /**
     * @dev Throws if caller does not have the {MinterRole}
     */
    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    /**
     * @dev Throws if caller does not have the {BurnerRole}
     */
    modifier onlyBurner() {
        require(
            isBurner(_msgSender()),
            "BurnerRole: caller does not have the Burner role"
        );
        _;
    }

    /**
     * @dev Sets the values for `name`, `symbol`, `decimals`
     * and gives owner {MinterRole} and {BurnerRole}
     * @param name The name of the token
     * @param symbol The symbol of the token 
     * @param decimals The number of decimals the token uses
     * @notice `name`, `symbol` and `decimals`
     * values are immutable: they can only be set once during construction
     */
    constructor(string memory name, string memory symbol, uint8 decimals)
        public
        ERC20Fee(name, symbol, decimals)
    {
        _addMinter(_msgSender());
        _addBurner(_msgSender());
    }

    /**
     * @dev Give an account access to {MinterRole}
     * @param account Account address
     */
    function addMinter(address account) external onlyOwner {
        _addMinter(account);
    }

    /**
     * @dev Give an account access to {BurnerRole}
     * @param account Account address
     */
    function addBurner(address account) external onlyOwner {
        _addBurner(account);
    }

    /**
    /**
     * @dev Remove an account's access to {MinterRole}
     * @param account Account address
     */
    function renounceMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev Remove an account's access to {BurnerRole}
     * @param account Account address
     */
    function renounceBurner(address account) external onlyOwner {
        _removeBurner(account);
    }

    /**
     * @dev Check if an account has {MinterRole}
     * @param account Account address
     * @return bool
     */
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    /**
     * @dev Check if an account has {BurnerRole}
     * @param account Account address
     * @return bool
     */
    function isBurner(address account) public view returns (bool) {
        return _burners.has(account);
    }

    /**
     * @dev Mint `amount` of tokens `to` recipient. See {ERC20-_mint}
     * @param to Account address of recipient
     * @param amount Amount to mint
     * @notice Requirements:
     * the caller must have the {MinterRole}
     * @return bool
     */
    function mint(address to, uint256 amount)
        external
        onlyMinter
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` of tokens from the caller. See {ERC20-_mint}
     * @param amount Amount to burn
     * @notice Requirements:
     * the caller must have the {BurnerRole}
     * @return bool
     */
    function burn(uint256 amount) external onlyBurner returns (bool) {
        _burn(_msgSender(), amount);
    }

    // Internal functions
    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _addBurner(address account) internal {
        _burners.add(account);
        emit BurnerAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    function _removeBurner(address account) internal {
        _burners.remove(account);
        emit BurnerRemoved(account);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed
 * @author OpenZeppelin-Solidity = "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol", and rmeoval
 *  of IERC20 due to " contract binary not set. Can't deploy new instance.
 * This contract may be abstract, not implement an abstract parent's methods completely
 * or not invoke an inherited contract's constructor correctly"
 */

pragma solidity 0.5.12;

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

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
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

pragma solidity 0.5.12;

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/helpers/[email protected]

pragma solidity 0.5.12;

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
        require(
            initializing || isConstructor() || !initialized,
            "Initializable: Contract instance has already been initialized"
        );

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
        uint256 cs;
        // solhint-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// File @sygnum/solidity-base-contracts/contracts/role/base/[email protected]

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.12;


contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Operatorable: caller does not have the operator role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Operatorable: caller does not have the admin role");
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        require(isSystem(msg.sender), "Operatorable: caller does not have the system role");
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        require(isMultisig(msg.sender), "Operatorable: caller does not have multisig role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        require(isAdminOrSystem(msg.sender), "Operatorable: caller does not have the admin role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        require(isOperatorOrSystem(msg.sender), "Operatorable: caller does not have the operator role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        require(isRelay(msg.sender), "Operatorable: caller does not have relay role associated");
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        require(
            isOperator(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        require(
            isAdmin(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the admin role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        require(
            isOperator(msg.sender) || isSystem(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor system nor relay"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract can not be zero");
        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        require(operatorsPending != address(0), "Operatorable: address of new operators contract can not be zero");
        require(msg.sender == operatorsPending, "Operatorable: should be called from new operators contract");
        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract cannot be zero");
        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}


// File contracts/token/ERC20/ERC20SygnumDetailed.sol

/**
 * @title ERC20SygnumDetailed
 * @author Team 3301 <[email protected]>
 * @dev ERC20 Standard Token with additional details and role set.
 */

pragma solidity 0.5.12;


contract ERC20SygnumDetailed is ERC20Detailed, Operatorable {
    bytes4 private _category;
    string private _class;
    address private _issuer;

    event NameUpdated(address issuer, string name, address token);
    event SymbolUpdated(address issuer, string symbol, address token);
    event CategoryUpdated(address issuer, bytes4 category, address token);
    event ClassUpdated(address issuer, string class, address token);
    event IssuerUpdated(address issuer, address newIssuer, address token);

    /**
     * @dev Sets the values for `name`, `symbol`, `decimals`, `category`, `class` and `issuer`. All are
     *  mutable apart from `issuer`, which is immutable.
     * @param name string
     * @param symbol string
     * @param decimals uint8
     * @param category bytes4
     * @param class string
     * @param issuer address
     */
    function _setDetails(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes4 category,
        string memory class,
        address issuer
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _category = category;
        _class = class;
        _issuer = issuer;
    }

    /**
     * @dev Returns the category of the token.
     */
    function category() public view returns (bytes4) {
        return _category;
    }

    /**
     * @dev Returns the class of the token.
     */
    function class() public view returns (string memory) {
        return _class;
    }

    /**
     * @dev Returns the issuer of the token.
     */
    function issuer() public view returns (address) {
        return _issuer;
    }

    /**
     * @dev Updates the name of the token, only callable by Sygnum operator.
     * @param name_ The new name.
     */
    function updateName(string memory name_) public onlyOperator {
        _name = name_;
        emit NameUpdated(msg.sender, _name, address(this));
    }

    /**
     * @dev Updates the symbol of the token, only callable by Sygnum operator.
     * @param symbol_ The new symbol.
     */
    function updateSymbol(string memory symbol_) public onlyOperator {
        _symbol = symbol_;
        emit SymbolUpdated(msg.sender, symbol_, address(this));
    }

    /**
     * @dev Updates the category of the token, only callable by Sygnum operator.
     * @param category_ The new cateogry.
     */
    function updateCategory(bytes4 category_) public onlyOperator {
        _category = category_;
        emit CategoryUpdated(msg.sender, _category, address(this));
    }

    /**
     * @dev Updates the class of the token, only callable by Sygnum operator.
     * @param class_ The new class.
     */
    function updateClass(string memory class_) public onlyOperator {
        _class = class_;
        emit ClassUpdated(msg.sender, _class, address(this));
    }

    /**
     * @dev Updates issuer ownership, only callable by Sygnum operator.
     * @param issuer_ The new issuer.
     */
    function updateIssuer(address issuer_) public onlyOperator {
        _issuer = issuer_;
        emit IssuerUpdated(msg.sender, _issuer, address(this));
    }
}


// File openzeppelin-solidity/contracts/GSN/[email protected]

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
contract Context {
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


// File openzeppelin-solidity/contracts/token/ERC20/[email protected]

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


// File openzeppelin-solidity/contracts/math/[email protected]

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


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Overload/[email protected]

pragma solidity 0.5.12;



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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/interface/[email protected]

pragma solidity 0.5.12;

/**
 * @title IWhitelist
 * @notice Interface for Whitelist contract
 */
contract IWhitelist {
    function isWhitelisted(address _account) external view returns (bool);

    function toggleWhitelist(address _account, bool _toggled) external;
}


// File @sygnum/solidity-base-contracts/contracts/helpers/instance/[email protected]

/**
 * @title Whitelistable
 * @author Team 3301 <[email protected]>
 * @dev Whitelistable contract stores the Whitelist contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.12;



contract Whitelistable is Initializable, Operatorable {
    IWhitelist internal whitelistInst;
    address private whitelistPending;

    event WhitelistContractChanged(address indexed caller, address indexed whitelistAddress);
    event WhitelistContractPending(address indexed caller, address indexed whitelistAddress);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier whenWhitelisted(address _account) {
        require(isWhitelisted(_account), "Whitelistable: account is not whitelisted");
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setWhitelistContract function can be called only by Admin role with
     *       confirmation through the whitelist contract.
     * @param _whitelist Whitelist contract address.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators, address _whitelist) public initializer {
        _setOperatorsContract(_baseOperators);
        _setWhitelistContract(_whitelist);
    }

    /**
     * @dev Set the new the address of Whitelist contract, should be confirmed from whitelist contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _whitelist Whitelist contract address.
     */
    function setWhitelistContract(address _whitelist) public onlyAdmin {
        require(_whitelist != address(0), "Whitelistable: address of new whitelist contract can not be zero");
        whitelistPending = _whitelist;
        emit WhitelistContractPending(msg.sender, _whitelist);
    }

    /**
     * @dev The function should be called from new whitelist contract by admin to insure that whitelistPending address
     *       is the real contract address.
     */
    function confirmWhitelistContract() public {
        require(whitelistPending != address(0), "Whitelistable: address of new whitelist contract can not be zero");
        require(msg.sender == whitelistPending, "Whitelistable: should be called from new whitelist contract");
        _setWhitelistContract(whitelistPending);
    }

    /**
     * @return The address of the Whitelist contract.
     */
    function getWhitelistContract() public view returns (address) {
        return address(whitelistInst);
    }

    /**
     * @return The pending address of the Whitelist contract.
     */
    function getWhitelistPending() public view returns (address) {
        return whitelistPending;
    }

    /**
     * @return If '_account' is whitelisted.
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistInst.isWhitelisted(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setWhitelistContract(address _whitelist) internal {
        require(_whitelist != address(0), "Whitelistable: address of new whitelist contract cannot be zero");
        whitelistInst = IWhitelist(_whitelist);
        emit WhitelistContractChanged(msg.sender, _whitelist);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Whitelist
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure that addresses attempting to particular
 * actions are whitelisted.
 */

pragma solidity 0.5.12;


contract ERC20Whitelist is ERC20, Whitelistable {
    /**
     * @dev Overload transfer function to validate sender and receiver are whitelisted.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public whenWhitelisted(msg.sender) whenWhitelisted(to) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to validate sender and spender are whitelisted.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value)
        public
        whenWhitelisted(msg.sender)
        whenWhitelisted(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to validate sender, from and receiver are whitelisted.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenWhitelisted(msg.sender) whenWhitelisted(from) whenWhitelisted(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance validate sender and spender are whitelisted.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenWhitelisted(spender)
        whenWhitelisted(msg.sender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance validate sender and spender are whitelisted.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenWhitelisted(spender)
        whenWhitelisted(msg.sender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burn function to ensure that account has been whitelisted.
     * @param account address that funds will be burned from.
     * @param value amount of funds that will be burned.
     */
    function _burn(address account, uint256 value) internal whenWhitelisted(account) {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure sender and account have been whitelisted.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount) internal whenWhitelisted(msg.sender) whenWhitelisted(account) {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure account has been whitelisted.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal whenWhitelisted(account) {
        super._mint(account, amount);
    }
}


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

pragma solidity 0.5.12;

contract ITraderOperators {
    function isTrader(address _account) external view returns (bool);

    function addTrader(address _account) external;

    function removeTrader(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/role/trader/[email protected]

/**
 * @title TraderOperatorable
 * @author Team 3301 <[email protected]>
 * @dev TraderOperatorable contract stores TraderOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity 0.5.12;



contract TraderOperatorable is Operatorable {
    ITraderOperators internal traderOperatorsInst;
    address private traderOperatorsPending;

    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the trader role associated.
     */
    modifier onlyTrader() {
        require(isTrader(msg.sender), "TraderOperatorable: caller is not trader");
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator or trader role associated.
     */
    modifier onlyOperatorOrTraderOrSystem() {
        require(
            isOperator(msg.sender) || isTrader(msg.sender) || isSystem(msg.sender),
            "TraderOperatorable: caller is not trader or operator or system"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setTradersOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     */
    function initialize(address _baseOperators, address _traderOperators) public initializer {
        super.initialize(_baseOperators);
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case
     * @param _traderOperators TradeOperators contract address.
     */
    function setTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        require(
            _traderOperators != address(0),
            "TraderOperatorable: address of new traderOperators contract can not be zero"
        );
        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        require(
            traderOperatorsPending != address(0),
            "TraderOperatorable: address of pending traderOperators contract can not be zero"
        );
        require(
            msg.sender == traderOperatorsPending,
            "TraderOperatorable: should be called from new traderOperators contract"
        );
        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns (address) {
        return traderOperatorsPending;
    }

    /**
     * @return If '_account' has trader privileges.
     */
    function isTrader(address _account) public view returns (bool) {
        return traderOperatorsInst.isTrader(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setTraderOperatorsContract(address _traderOperators) internal {
        require(
            _traderOperators != address(0),
            "TraderOperatorable: address of new traderOperators contract can not be zero"
        );
        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/[email protected]

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */
pragma solidity 0.5.12;

contract Pausable is TraderOperatorable {
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool internal _paused;

    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public onlyOperatorOrTraderOrSystem whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public onlyOperatorOrTraderOrSystem whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view returns (bool) {
        return !_paused;
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Pausable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure that the contract has not been paused.
 */

pragma solidity 0.5.12;


contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev Overload transfer function to ensure contract has not been paused.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure contract has not been paused.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure contract has not been paused.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burn function to ensure contract has not been paused.
     * @param account address that funds will be burned from.
     * @param value amount of funds that will be burned.
     */
    function _burn(address account, uint256 value) internal whenNotPaused {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure contract has not been paused.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount) internal whenNotPaused {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure contract has not been paused.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal whenNotPaused {
        super._mint(account, amount);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Mintable
 * @author Team 3301 <[email protected]>
 * @dev For blocking and unblocking particular user funds.
 */

pragma solidity 0.5.12;


contract ERC20Mintable is ERC20, Operatorable {
    /**
     * @dev Overload _mint to ensure only operator or system can mint funds.
     * @param account address that will recieve new funds.
     * @param amount of funds to be minted.
     */
    function _mint(address account, uint256 amount) internal onlyOperatorOrSystem {
        require(amount > 0, "ERC20Mintable: amount has to be greater than 0");
        super._mint(account, amount);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Snapshot
 * @author Team 3301 <[email protected]>
 * @notice Records historical balances.
 */
pragma solidity 0.5.12;


contract ERC20Snapshot is ERC20 {
    using SafeMath for uint256;

    /**
     * @dev `Snapshot` is the structure that attaches a block number to a
     * given value. The block number attached is the one that last changed the value
     */
    struct Snapshot {
        uint256 fromBlock; // `fromBlock` is the block number at which the value was generated from
        uint256 value; // `value` is the amount of tokens at a specific block number
    }

    /**
     * @dev `_snapshotBalances` is the map that tracks the balance of each address, in this
     * contract when the balance changes the block number that the change
     * occurred is also included in the map
     */
    mapping(address => Snapshot[]) private _snapshotBalances;

    // Tracks the history of the `totalSupply` of the token
    Snapshot[] private _snapshotTotalSupply;

    /**
     * @dev Queries the balance of `_owner` at a specific `_blockNumber`
     * @param _owner The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at `_blockNumber`
     */
    function balanceOfAt(address _owner, uint256 _blockNumber) public view returns (uint256) {
        return getValueAt(_snapshotBalances[_owner], _blockNumber);
    }

    /**
     * @dev Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
        return getValueAt(_snapshotTotalSupply, _blockNumber);
    }

    /**
     * @dev `getValueAt` retrieves the number of tokens at a given block number
     * @param checkpoints The history of values being queried
     * @param _block The block number to retrieve the value at
     * @return The number of tokens being queried
     */
    function getValueAt(Snapshot[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length.sub(1)].fromBlock) {
            return checkpoints[checkpoints.length.sub(1)].value;
        }

        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

        // Binary search of the value in the array
        uint256 min;
        uint256 max = checkpoints.length.sub(1);

        while (max > min) {
            uint256 mid = (max.add(min).add(1)).div(2);
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }

        return checkpoints[min].value;
    }

    /**
     * @dev `updateValueAtNow` used to update the `_snapshotBalances` map and the `_snapshotTotalSupply`
     * @param checkpoints The history of data being updated
     * @param _value The new number of tokens
     */
    function updateValueAtNow(Snapshot[] storage checkpoints, uint256 _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].fromBlock < block.number)) {
            checkpoints.push(Snapshot(block.number, _value));
        } else {
            checkpoints[checkpoints.length.sub(1)].value = _value;
        }
    }

    /**
     * @dev Internal function that transfers an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param to The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function transfer(address to, uint256 value) public returns (bool result) {
        result = super.transfer(to, value);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[msg.sender], balanceOf(msg.sender));
        updateValueAtNow(_snapshotBalances[to], balanceOf(to));
    }

    /**
     * @dev Internal function that transfers an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param from The account that funds will be taken from.
     * @param to The account that funds will be given too.
     * @param value The amount of funds to be transferred..
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool result) {
        result = super.transferFrom(from, to, value);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[from], balanceOf(from));
        updateValueAtNow(_snapshotBalances[to], balanceOf(to));
    }

    /**
     * @dev Internal function that confiscates an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param confiscatee The account that funds will be taken from.
     * @param receiver The account that funds will be given too.
     * @param amount The amount of funds to be transferred..
     */
    function _confiscate(
        address confiscatee,
        address receiver,
        uint256 amount
    ) internal {
        super._transfer(confiscatee, receiver, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[confiscatee], balanceOf(confiscatee));
        updateValueAtNow(_snapshotBalances[receiver], balanceOf(receiver));
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address account, uint256 amount) internal {
        super._mint(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal {
        super._burn(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFor(address account, uint256 amount) internal {
        super._burn(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 amount) internal {
        super._burnFrom(account, amount);
        updateValueAtNow(_snapshotTotalSupply, totalSupply());
        updateValueAtNow(_snapshotBalances[account], balanceOf(account));
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Burnable
 * @author Team 3301 <[email protected]>
 * @dev For burning funds from particular user addresses.
 */

pragma solidity 0.5.12;


contract ERC20Burnable is ERC20Snapshot, Operatorable {
    /**
     * @dev Overload ERC20 _burnFor, burning funds from a particular users address.
     * @param account address to burn funds from.
     * @param amount of funds to burn.
     */

    function _burnFor(address account, uint256 amount) internal onlyOperator {
        super._burn(account, amount);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/[email protected]

/**
 * @title Freezable
 * @author Team 3301 <[email protected]>
 * @dev Freezable contract to freeze functionality for particular addresses.  Freezing/unfreezing is controlled
 *       by operators in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity 0.5.12;

contract Freezable is Operatorable {
    mapping(address => bool) public frozen;

    event FreezeToggled(address indexed account, bool frozen);

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Freezable: Empty address");
        _;
    }

    /**
     * @dev Reverts if account address is frozen.
     * @param _account address to validate is not frozen.
     */
    modifier whenNotFrozen(address _account) {
        require(!frozen[_account], "Freezable: account is frozen");
        _;
    }

    /**
     * @dev Reverts if account address is not frozen.
     * @param _account address to validate is frozen.
     */
    modifier whenFrozen(address _account) {
        require(frozen[_account], "Freezable: account is not frozen");
        _;
    }

    /**
     * @dev Getter to determine if address is frozen.
     * @param _account address to determine if frozen or not.
     * @return bool is frozen
     */
    function isFrozen(address _account) public view returns (bool) {
        return frozen[_account];
    }

    /**
     * @dev Toggle freeze/unfreeze on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled freeze/unfreeze.
     */
    function toggleFreeze(address _account, bool _toggled) public onlyValidAddress(_account) onlyOperator {
        frozen[_account] = _toggled;
        emit FreezeToggled(_account, _toggled);
    }

    /**
     * @dev Batch freeze/unfreeze multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled freeze/unfreeze.
     */
    function batchToggleFreeze(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, "Freezable: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleFreeze(_addresses[i], _toggled);
        }
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Freezable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure client addresses are not frozen for particular actions.
 */

pragma solidity 0.5.12;


contract ERC20Freezable is ERC20, Freezable {
    /**
     * @dev Overload transfer function to ensure sender and receiver have not been frozen.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public whenNotFrozen(msg.sender) whenNotFrozen(to) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure sender and receiver have not been frozen.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure sender, approver and receiver have not been frozen.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotFrozen(msg.sender) whenNotFrozen(from) whenNotFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burnfrom function to ensure sender and user to be burned from have not been frozen.
     * @param account account that funds will be burned from.
     * @param amount amount of funds to be burned.
     */
    function _burnFrom(address account, uint256 amount) internal whenNotFrozen(msg.sender) whenNotFrozen(account) {
        super._burnFrom(account, amount);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Destroyable
 * @author Team 3301 <[email protected]>
 * @notice Allows operator to destroy contract.
 */

pragma solidity 0.5.12;

contract ERC20Destroyable is Operatorable {
    event Destroyed(address indexed caller, address indexed account, address indexed contractAddress);

    function destroy(address payable to) public onlyOperator {
        emit Destroyed(msg.sender, to, address(this));
        selfdestruct(to);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Tradeable
 * @author Team 3301 <[email protected]>
 * @dev Trader accounts can approve particular addresses on behalf of a user.
 */

pragma solidity 0.5.12;


contract ERC20Tradeable is ERC20, TraderOperatorable {
    /**
     * @dev Trader can approve users balance to a particular address for a particular amount.
     * @param _owner address that approves the funds.
     * @param _spender address that spends the funds.
     * @param _value amount of funds.
     */
    function approveOnBehalf(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyTrader {
        super._approve(_owner, _spender, _value);
    }
}


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title IBlockerOperators
 * @notice Interface for BlockerOperators contract
 */

pragma solidity 0.5.12;

contract IBlockerOperators {
    function isBlocker(address _account) external view returns (bool);

    function addBlocker(address _account) external;

    function removeBlocker(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/role/blocker/[email protected]

/**
 * @title BlockerOperatorable
 * @author Team 3301 <[email protected]>
 * @dev BlockerOperatorable contract stores BlockerOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity 0.5.12;



contract BlockerOperatorable is Operatorable {
    IBlockerOperators internal blockerOperatorsInst;
    address private blockerOperatorsPending;

    event BlockerOperatorsContractChanged(address indexed caller, address indexed blockerOperatorAddress);
    event BlockerOperatorsContractPending(address indexed caller, address indexed blockerOperatorAddress);

    /**
     * @dev Reverts if sender does not have the blocker role associated.
     */
    modifier onlyBlocker() {
        require(isBlocker(msg.sender), "BlockerOperatorable: caller is not blocker role");
        _;
    }

    /**
     * @dev Reverts if sender does not have the blocker or operator role associated.
     */
    modifier onlyBlockerOrOperator() {
        require(
            isBlocker(msg.sender) || isOperator(msg.sender),
            "BlockerOperatorable: caller is not blocker or operator role"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setBlockerOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function initialize(address _baseOperators, address _blockerOperators) public initializer {
        super.initialize(_baseOperators);
        _setBlockerOperatorsContract(_blockerOperators);
    }

    /**
     * @dev Set the new the address of BlockerOperators contract, should be confirmed from BlockerOperators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function setBlockerOperatorsContract(address _blockerOperators) public onlyAdmin {
        require(
            _blockerOperators != address(0),
            "BlockerOperatorable: address of new blockerOperators contract can not be zero."
        );
        blockerOperatorsPending = _blockerOperators;
        emit BlockerOperatorsContractPending(msg.sender, _blockerOperators);
    }

    /**
     * @dev The function should be called from new BlockerOperators contract by admin to insure that blockerOperatorsPending address
     *       is the real contract address.
     */
    function confirmBlockerOperatorsContract() public {
        require(
            blockerOperatorsPending != address(0),
            "BlockerOperatorable: address of pending blockerOperators contract can not be zero"
        );
        require(
            msg.sender == blockerOperatorsPending,
            "BlockerOperatorable: should be called from new blockerOperators contract"
        );
        _setBlockerOperatorsContract(blockerOperatorsPending);
    }

    /**
     * @return The address of the BlockerOperators contract.
     */
    function getBlockerOperatorsContract() public view returns (address) {
        return address(blockerOperatorsInst);
    }

    /**
     * @return The pending BlockerOperators contract address
     */
    function getBlockerOperatorsPending() public view returns (address) {
        return blockerOperatorsPending;
    }

    /**
     * @return If '_account' has blocker privileges.
     */
    function isBlocker(address _account) public view returns (bool) {
        return blockerOperatorsInst.isBlocker(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setBlockerOperatorsContract(address _blockerOperators) internal {
        require(
            _blockerOperators != address(0),
            "BlockerOperatorable: address of new blockerOperators contract can not be zero"
        );
        blockerOperatorsInst = IBlockerOperators(_blockerOperators);
        emit BlockerOperatorsContractChanged(msg.sender, _blockerOperators);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/ERC20/[email protected]

/**
 * @title ERC20Blockable
 * @author Team 3301 <[email protected]>
 * @dev For blocking and unblocking particular user funds.
 */

pragma solidity 0.5.12;


contract ERC20Blockable is ERC20, BlockerOperatorable {
    uint256 public totalBlockedBalance;

    mapping(address => uint256) public _blockedBalances;

    event Blocked(address indexed blocker, address indexed account, uint256 value);
    event UnBlocked(address indexed blocker, address indexed account, uint256 value);

    /**
     * @dev Block funds, and move funds from _balances into _blockedBalances.
     * @param _account address to block funds.
     * @param _amount of funds to block.
     */
    function block(address _account, uint256 _amount) public onlyBlockerOrOperator {
        _balances[_account] = _balances[_account].sub(_amount);
        _blockedBalances[_account] = _blockedBalances[_account].add(_amount);

        totalBlockedBalance = totalBlockedBalance.add(_amount);
        emit Blocked(msg.sender, _account, _amount);
    }

    /**
     * @dev Unblock funds, and move funds from _blockedBalances into _balances.
     * @param _account address to unblock funds.
     * @param _amount of funds to unblock.
     */
    function unblock(address _account, uint256 _amount) public onlyBlockerOrOperator {
        _balances[_account] = _balances[_account].add(_amount);
        _blockedBalances[_account] = _blockedBalances[_account].sub(_amount);

        totalBlockedBalance = totalBlockedBalance.sub(_amount);
        emit UnBlocked(msg.sender, _account, _amount);
    }

    /**
     * @dev Getter for the amount of blocked balance for a particular address.
     * @param _account address to get blocked balance.
     * @return amount of blocked balance.
     */
    function blockedBalanceOf(address _account) public view returns (uint256) {
        return _blockedBalances[_account];
    }

    /**
     * @dev Getter for the total amount of blocked funds for all users.
     * @return amount of total blocked balance.
     */
    function getTotalBlockedBalance() public view returns (uint256) {
        return totalBlockedBalance;
    }
}


// File contracts/token/SygnumToken.sol

/**
 * @title SygnumToken
 * @author Team 3301 <[email protected]>
 * @notice ERC20 token with additional features.
 */

pragma solidity 0.5.12;










contract SygnumToken is
    ERC20Snapshot,
    ERC20SygnumDetailed,
    ERC20Pausable,
    ERC20Mintable,
    ERC20Whitelist,
    ERC20Tradeable,
    ERC20Blockable,
    ERC20Burnable,
    ERC20Freezable,
    ERC20Destroyable
{
    event Minted(address indexed minter, address indexed account, uint256 value);
    event Burned(address indexed burner, uint256 value);
    event BurnedFor(address indexed burner, address indexed account, uint256 value);
    event Confiscated(address indexed account, uint256 amount, address indexed receiver);

    uint16 internal constant BATCH_LIMIT = 256;

    /**
     * @dev Initialize contracts.
     * @param _baseOperators Base operators contract address.
     * @param _whitelist Whitelist contract address.
     * @param _traderOperators Trader operators contract address.
     * @param _blockerOperators Blocker operators contract address.
     */
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators
    ) public initializer {
        super.initialize(_baseOperators);
        _setWhitelistContract(_whitelist);
        _setTraderOperatorsContract(_traderOperators);
        _setBlockerOperatorsContract(_blockerOperators);
        _setDetails(_name, _symbol, _decimals, _category, _class, _issuer);
    }

    /**
     * @dev Burn.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) public {
        require(!isFrozen(msg.sender), "SygnumToken: Account must not be frozen.");
        super._burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /**
     * @dev BurnFor.
     * @param _account Address to burn tokens for.
     * @param _amount Amount of tokens to burn.
     */
    function burnFor(address _account, uint256 _amount) public {
        super._burnFor(_account, _amount);
        emit BurnedFor(msg.sender, _account, _amount);
    }

    /**
     * @dev BurnFrom.
     * @param _account Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) public {
        super._burnFrom(_account, _amount);
        emit Burned(_account, _amount);
    }

    /**
     * @dev Mint.
     * @param _account Address to mint tokens to.
     * @param _amount Amount to mint.
     */
    function mint(address _account, uint256 _amount) public {
        if (isSystem(msg.sender)) {
            require(!isFrozen(_account), "SygnumToken: Account must not be frozen if system calling.");
        }
        super._mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    /**
     * @dev Confiscate.
     * @param _confiscatee Account to confiscate funds from.
     * @param _receiver Account to transfer confiscated funds to.
     * @param _amount Amount of tokens to confiscate.
     */
    function confiscate(
        address _confiscatee,
        address _receiver,
        uint256 _amount
    ) public onlyOperator whenNotPaused whenWhitelisted(_receiver) whenWhitelisted(_confiscatee) {
        super._confiscate(_confiscatee, _receiver, _amount);
        emit Confiscated(_confiscatee, _amount, _receiver);
    }

    /**
     * @dev Batch burn for.
     * @param _amounts Array of all values to burn.
     * @param _accounts Array of all addresses to burn from.
     */
    function batchBurnFor(address[] memory _accounts, uint256[] memory _amounts) public {
        require(_accounts.length == _amounts.length, "SygnumToken: values and recipients are not equal.");
        require(_accounts.length <= BATCH_LIMIT, "SygnumToken: batch count is greater than BATCH_LIMIT.");
        for (uint256 i = 0; i < _accounts.length; i++) {
            burnFor(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Batch mint.
     * @param _accounts Array of all addresses to mint to.
     * @param _amounts Array of all values to mint.
     */
    function batchMint(address[] memory _accounts, uint256[] memory _amounts) public {
        require(_accounts.length == _amounts.length, "SygnumToken: values and recipients are not equal.");
        require(_accounts.length <= BATCH_LIMIT, "SygnumToken: batch count is greater than BATCH_LIMIT.");
        for (uint256 i = 0; i < _accounts.length; i++) {
            mint(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Batch confiscate to a maximum of 256 addresses.
     * @param _confiscatees array of addresses whose funds are being confiscated
     * @param _receivers array of addresses who's receiving the funds
     * @param _values array of values of funds being confiscated
     */
    function batchConfiscate(
        address[] memory _confiscatees,
        address[] memory _receivers,
        uint256[] memory _values
    ) public returns (bool) {
        require(
            _confiscatees.length == _values.length && _receivers.length == _values.length,
            "SygnumToken: confiscatees, recipients and values are not equal."
        );
        require(_confiscatees.length <= BATCH_LIMIT, "SygnumToken: batch count is greater than BATCH_LIMIT.");
        for (uint256 i = 0; i < _confiscatees.length; i++) {
            confiscate(_confiscatees[i], _receivers[i], _values[i]);
        }
    }
}


// File contracts/token/upgrade/prd/SygnumTokenMetadataUpgrade.sol

/**
 * @title MetadataUpgrade
 * @author Team 3301 <[email protected]>
 * @dev Standard contract to display upgradability usability.  This is an example contract,
 *      that will not be used in production, to show how upgradability will be utilized.
 */
pragma solidity 0.5.12;

contract SygnumTokenMetadataUpgrade is SygnumToken {
    string public tokenURI;
    bool public initializedMetadataUpgrade;
    event TokenUriUpdated(string newToken);

    // changed back to public for tests
    function initializeContractsAndConstructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes4 _category,
        string memory _class,
        address _issuer,
        address _baseOperators,
        address _whitelist,
        address _traderOperators,
        address _blockerOperators,
        string memory _tokenURI
    ) public {
        require(!initializedMetadataUpgrade, "SygnumTokenMetadataUpgrade: already initialized");
        super.initializeContractsAndConstructor(
            _name,
            _symbol,
            _decimals,
            _category,
            _class,
            _issuer,
            _baseOperators,
            _whitelist,
            _traderOperators,
            _blockerOperators
        );
        tokenURI = _tokenURI;
        initializedMetadataUpgrade = true;
    }

    function updateTokenURI(string memory _newToken) public onlyOperator {
        tokenURI = _newToken;
        emit TokenUriUpdated(_newToken);
    }
}
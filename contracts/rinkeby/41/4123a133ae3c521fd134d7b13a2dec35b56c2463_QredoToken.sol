// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./utils/Authorizable.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";

// QredoToken => QT
contract QredoToken is Authorizable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _circulatingSupply;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 initialSupply_) public {
        require(bytes(name_).length > 0, "QT:constructor::name_ is undefined");
        require(bytes(symbol_).length > 0, "QT:constructor::symbol_ is undefined");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        
        if(initialSupply_ > 0){
            _mint(_msgSender(), initialSupply_);
        }
    }

    //*************************************************** PUBLIC ***************************************************//
    
    /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        * - `recipient` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
    */
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
        *
        * This internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        *
        * Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
        *
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        require(spender != address(0),"QT::increaseAllowance:spender must be different than 0");
        
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
        *
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        require(spender != address(0),"QT::decreaseAllowance:spender must be different than 0");

        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "QT::decreaseAllowance: decreased allowance below zero");
        
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    /**
        * @dev Moves `amount` tokens from `sender` to `recipient` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} and {Approve} events
        *
        * Requirements:
        * - `sender` and `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        * - the caller must have allowance for ``sender``'s tokens of at least
        * `amount`..
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "QT::transferFrom: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens
     * @param value The amount of tokens to mint
     */
    function mint(address to, uint256 value) external override onlyAuthorized() returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    //*************************************************** VIEWS ***************************************************//
    
    /**
        * @dev Returns the name of the token.
    */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
        * @dev Returns the symbol of the token, usually a shorter version of the
        * name.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
        * @dev Returns the number of decimals used to get its user representation.
        * For example, if `decimals` equals `2`, a balance of `505` tokens should
        * be displayed to a user as `5,05` (`505 / 10 ** 2`).
        *
        * Tokens usually opt for a value of 18, imitating the relationship between
        * Ether and Wei. This is the value {ERC20} uses, unless this function is
        * overridden;
        *
        * NOTE: This information is only used for _display_ purposes: it in
        * no way affects any of the arithmetic of the contract, including
        * {ERC20Proxy-balanceOf}, {ERC20Storage-balanceOf}  and {ERC20Logic-transfer}.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
        * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
        * @dev Returns the amount of tokens in existence.
    */
    function circulatingSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }
    
    /**
        * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve}, {increaseAllowance}, {decreaseAllowance} or {transferFrom} are called.
    */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    //*************************************************** INTERNAL ***************************************************//
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "QT::_transfer: transfer from the zero address");
        require(recipient != address(0), "QT::_transfer: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "QT::_transfer: transfer amount exceeds balance");

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "QT::_approve: approve from the zero address");
        require(spender != address(0), "QT::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "QT::_mint:mint to the zero address");
        require(_circulatingSupply.add(amount) <= _totalSupply, "QT::_mint:mint exceeds totalSupply");
        require(amount > 0, "QT::_mint:amount must be greater than zero");

        _circulatingSupply = _circulatingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "QT::_burn:burn from the zero address");
        require(amount > 0, "QT::_burn:amount must be greater than zero");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "QT::_burn:burn amount exceeds balance");

        _balances[account] = accountBalance.sub(amount);
        _circulatingSupply = _circulatingSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () public {
        address msgSender = _msgSender();
        require(msgSender != address(0), "Ownable:constructor:msgSender zero address");
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
        * @dev Returns the address of the current owner.
    */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
        * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable::onlyOwner:caller is not the owner");
        _;
    }

    /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable::transferOwnership:new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../ownable/Ownable.sol";
import "../../interfaces/IAuthorizable.sol";

abstract contract Authorizable is IAuthorizable, Ownable {

    mapping(address => bool) private _authorized;

    /* -------------------------------------------------------- MODIFIERS -------------------------------------------------------- */

    /**
        * @dev Throws if called by any account other than _authorized.
    */
    modifier onlyAuthorized() {
        require(_authorized[_msgSender()], "Authorizable::onlyAuthorized:Only authorized address can call");
        _;
    }

    /* -------------------------------------------------------- SETTERS -------------------------------------------------------- */
    
    /**
        * @dev Add _authorized account {add} if it's not _authorized.
        * Can only be called by the current owner.
        *
        * Emits a {_Authorized} event.
        * Requirements:
        * - `add` cannot be the zero address.
        * - `add` cannot be _authorized already.
    */
    function addAuthorized(address add) onlyOwner external override returns(bool){
        require(add != address(0), "Authorizable::addAuthorized:toAdd address must be different than 0");
        require(!_authorized[add], "Authorizable::addAuthorized:toAdd is already authorized");
        _authorized[add] = true;
        emit Authorized(add, true);
        return true;
    }

    /**
        * @dev Remove _authorized account {remove} if it's _authorized.
        * Can only be called by the current owner.
        *
        * Emits a {Authorized} event.
        * Requirements:
        * - `remove` cannot be the zero address.
        * - `remove` must be _authorized already.
    */
    function removeAuthorized(address remove) onlyOwner external override returns(bool) {
        require(remove != address(0), "Authorizable::removeAuthorized:remove address must be different than 0");
        require(_authorized[remove], "Authorizable::removeAuthorized:remove is not authorized");
        _authorized[remove] = false;
        emit Authorized(remove, false);
        return true;
    }

    /* -------------------------------------------------------- VIEWS -------------------------------------------------------- */

    /**
        * @dev Returns the bool if the {auth} address is _authorized.
    */
    function isAuthorized(address auth) external override view returns(bool){
        return _authorized[auth];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IAuthorizable {
    function addAuthorized(address _toAdd) external returns (bool);
    function removeAuthorized(address _toRemove) external returns (bool);
    function isAuthorized(address _auth) external view returns (bool);

    event Authorized(address indexed auth, bool isAuthorized);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IERC20 {
    //*************************************************** PUBLIC ***************************************************//
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender,uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender,uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    
    //*************************************************** VIEWS ***************************************************//
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    //*************************************************** EVENTS ***************************************************//
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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
/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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

pragma solidity >=0.6.0 <0.8.0;

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
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
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

pragma solidity >=0.6.0 <0.8.0;

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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WrappedToken is ERC20, Ownable {
    event Burn(address indexed _sender, address indexed _to, uint256 amount);
    address public miner;

    constructor(address _miner, string memory name, string memory symbol) 
        public ERC20(name, symbol) {
        miner = _miner;
    }

    function burn(uint256 amount, address to) public {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), to, amount);
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == miner, "WrappedToken: unauthorized");
        _mint(account, amount);
    }
    
    function setMiner(address _miner) public onlyOwner {
        miner = _miner;
    }
}



abstract contract Operator is Ownable {
    address public operator;
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        operator = msg.sender;
        emit OperatorTransferred(address(0), operator);
    }

    modifier onlyOperator() {
        require(operator == msg.sender, 'Operator:onlyOperator');
        _;
    }

    function transferOperator(address newOperator) public onlyOwner {
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }
}

contract MintOracle is Operator {
    struct PriceFeed {
        address token;
        uint256 price;
    }
    
    struct PriceInfo{
        uint256 price;
        uint256 updateTime;
    }
    
    mapping(address => PriceInfo) public allPrice;
    
    function feed(address[] calldata tokens, uint256[] calldata prices) external onlyOperator {
        require(tokens.length == prices.length, "MintOracle:array not match");
        for (uint256 i = 0; i < prices.length; i++) {
            address token = tokens[i];
            require(token != address(0), "MintOracle: feed zero address");
            require(prices[i] > 0, "MintOracle: feed zero price");
            allPrice[token].updateTime = block.timestamp;
            allPrice[token].price = prices[i];
        }
    }
    
    function getPrice(address token) external view returns (uint256 price, uint256 updateTime) {
        price = allPrice[token].price;
        updateTime = allPrice[token].updateTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}


contract StableMint is Ownable {
    using SafeMath for uint256;
    using TransferHelper for address;
    
    struct CollateralConfig {
        address token; 
        uint256 liquidateDiscount; 
        uint256 minCollateralRatio; 
        uint256 endPrice;
    }
    
    struct KeyFlag {
        uint256 key;
        bool deleted; 
    }
    
    struct Session {
        uint256 idx; 
        address owner;
        address collateral;
        uint256 collateralAmount;
        uint256 assetAmount;
    }
    
    struct IndexValue {
        uint256 keyIndex; 
        uint256 collateralKeyIndex; 
        uint256 userKeyIndex; 
        Session value;
    }
    
    struct itmap {
        mapping(uint256 => IndexValue) data; 
        mapping(address => uint256[]) indexCollateral; 
        mapping(address => uint256[]) indexUser; 
        KeyFlag[] keys; 
        uint256 size; 
    }
    
    uint256 public constant MAX_LIMIT = 30;
    uint256 public constant BASE = 1e18;
    address public oracle;
    address public assetToken;
    address public feeTo;
    uint256 public feeRate = 2e16;
    uint256 public sessionID = 1; 
    mapping(address =>CollateralConfig) public collateralConfig;
    itmap sessions;
    
    event Open(uint256 session, address depositToken, uint256 mintAmount, uint256 depositAmount);
    event Deposit(uint256 session, uint256 depositAmount);
    event Withdraw(uint256 session, uint256 withdrawAmount, uint256 fee);
    event Mint(uint256 session, uint256 mintAmount);
    event Burn(uint256 session, uint256 burnAmount);
    event Liquidate(uint256 session, address owner, uint256 returnCollateralAmount, uint256 burnAssetAmount, uint256 fee);
    
    constructor(address _assetToken, address _oracle, address _feeTo) public {
        assetToken = _assetToken;
        oracle = _oracle;
        feeTo = _feeTo;
    }
    
    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
    
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= BASE, "StableMint: feeRate overflow");
        feeRate = _feeRate;
    }
    
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    function updateCollateral(address collateralToken, uint256 liquidateDiscount, uint256 minCollateralRatio) external onlyOwner {
        require(collateralToken != address(0), "StableMint: zero address");
        require(liquidateDiscount <= BASE, "StableMint: liquidateDiscount overflow");
        require(minCollateralRatio >= BASE, "StableMint: minCollateralRatio overflow");
        collateralConfig[collateralToken].token = collateralToken;
        collateralConfig[collateralToken].liquidateDiscount = liquidateDiscount;
        collateralConfig[collateralToken].minCollateralRatio = minCollateralRatio;
        collateralConfig[collateralToken].endPrice = 0;
    }
    
    function migrate(address collateralToken, uint256 endPrice) external onlyOwner {
        require(endPrice > 0, "StableMint: endPrice > 0");
        require(collateralConfig[collateralToken].endPrice == 0, "StableMint: asset was already abandoned or migrated");
        require(collateralConfig[collateralToken].token == collateralToken, "StableMint: asset was not registered");
        collateralConfig[collateralToken].minCollateralRatio = BASE;
        collateralConfig[collateralToken].endPrice = endPrice;
        collateralConfig[collateralToken].minCollateralRatio = BASE;
        collateralConfig[collateralToken].endPrice = endPrice;
    }
    
    function open(address collateralToken, uint256 collateralAmount, uint256 collateralRatio) external {
        require(assetToken != collateralToken, "StableMint: assetToken can't equal collateralToken");
        require(collateralConfig[collateralToken].endPrice == 0, "StableMint: asset was already abandoned or migrated");
        require(collateralAmount > 0, "StableMint: zero collateralAmount");
        require(collateralRatio >= collateralConfig[collateralToken].minCollateralRatio, "StableMint: low collateral ratio than minimum");
        
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        uint256 price = _loadPrice(collateralToken);
        uint256 mintAmount = _matchAsset(collateralAmount, price, collateralRatio);
        require(mintAmount > 0, "StableMint: mintAmount is zero");

        _itmapInsertOrUpdate(sessionID, Session({idx:sessionID, owner:msg.sender, collateral:collateralToken, collateralAmount:collateralAmount, assetAmount:mintAmount}));
        ++sessionID;
  
        WrappedToken(assetToken).mint(msg.sender, mintAmount);
        emit Open(sessionID - 1, collateralToken, mintAmount, collateralAmount);
    }
    
    function deposit(uint256 _sessionID, uint256 collateralAmount) external {
        require( sessions.data[_sessionID].value.idx > 0, "StableMint: zero sessionID");
        Session storage session = sessions.data[_sessionID].value;
        require(session.owner == msg.sender, "StableMint: deposit not owner");
        require(collateralAmount > 0, "StableMint: zero collateralAmount");
        require(collateralConfig[session.collateral].endPrice == 0, "StableMint: deposit operation is not allowed for the deprecated asset");
        session.collateralAmount = session.collateralAmount.add(collateralAmount);
        emit Deposit(sessionID, collateralAmount);
    }
    
    function withdraw(uint256 _sessionID, uint256 withdrawAmount) public {
        Session storage session = _getSession(_sessionID);
        require(session.owner == msg.sender, "StableMint: withdraw not owner");
        require(withdrawAmount > 0, "StableMint: zero withdrawAmount");
        require(withdrawAmount <= session.collateralAmount, "StableMint: withdrawAmount over than provide");

        uint256 price = _loadPrice(session.collateral);
        uint256 collateralAmount = session.collateralAmount.sub(withdrawAmount);
        uint256 minCollateralAmount = _matchCollateral(session.assetAmount, price, collateralConfig[session.collateral].minCollateralRatio);
        require(minCollateralAmount <= collateralAmount, "StableMint: collateral less than minCollateralRatio");

        session.collateralAmount = collateralAmount;
        uint256 fee = feeTo == address(0) ? 0 : withdrawAmount.mul(feeRate).div(BASE);
        withdrawAmount = withdrawAmount.sub(fee);
        session.collateral.safeTransfer(msg.sender, withdrawAmount);
        if (fee > 0) {
            session.collateral.safeTransfer(feeTo, fee);
        }
        if (session.collateralAmount == 0 && session.assetAmount == 0) {
            _itmapRemove(_sessionID);
        }

        emit Withdraw(_sessionID, withdrawAmount, fee);
    }
    
    function mint(uint256 _sessionID, uint256 mintAmount) external {
        Session storage session = _getSession(_sessionID);
        require(session.owner == msg.sender, "StableMint: mint not owner");
        require(mintAmount > 0, "StableMint: zero mintAmount");
        require(collateralConfig[session.collateral].endPrice == 0, "StableMint: asset was already abandoned or migrated");

        uint256 price = _loadPrice(session.collateral);
        uint256 assetAmount = session.assetAmount.add(mintAmount);
        uint256 minCollateralAmount = _matchAsset(assetAmount, price, collateralConfig[session.collateral].minCollateralRatio);
        require(minCollateralAmount < session.collateralAmount, "StableMint: mintAmount over than minCollateralRatio");

        session.assetAmount = assetAmount;
        WrappedToken(assetToken).mint(msg.sender, mintAmount);
        emit Mint(_sessionID, mintAmount);
    }
    
    function burn(uint256 _sessionID, uint256 burnAmount) public {
        Session storage session = _getSession(_sessionID);
        require(burnAmount > 0, "StableMint: zero burnAmount");
        require(burnAmount <= session.assetAmount, "StableMint: cannot burn asset more than mint");
        assetToken.safeTransferFrom(msg.sender, address(this), burnAmount);

        uint256 endPrice = collateralConfig[session.collateral].endPrice;
        if (endPrice != 0) {
            uint256 refundCollateral = burnAmount.mul(endPrice).div(BASE);
            session.assetAmount = session.assetAmount.sub(burnAmount);
            session.collateralAmount = session.collateralAmount.sub(refundCollateral);
            session.collateral.safeTransfer(msg.sender, refundCollateral);
            if (session.collateralAmount == 0 && session.assetAmount == 0) {
                _itmapRemove(_sessionID);
            }
        } else {
            require(session.owner == msg.sender, "StableMint: burn not owner");
            session.assetAmount = session.assetAmount.sub(burnAmount);
        }
        
        WrappedToken(assetToken).burn(burnAmount, msg.sender);
        emit Burn(_sessionID, burnAmount);
    }
    
    function close(uint256 _sessionID) public {
        Session storage session = _getSession(_sessionID);
        burn(_sessionID, session.assetAmount);
        withdraw(_sessionID, session.collateralAmount);
    }
    
    function liquidate(uint256 _sessionID, uint256 liquidateAmount) external {
        Session storage session = _getSession(_sessionID);
        require(liquidateAmount > 0, "StableMint: zero assetAmount");
        require(liquidateAmount <= session.assetAmount, "StableMint: liquidateAmount more than assetAmount");
        assetToken.safeTransferFrom(msg.sender, address(this), liquidateAmount);
        uint256 price = _loadPrice(session.collateral);
        uint256 minCollateralAmount = _matchCollateral(session.assetAmount, price, collateralConfig[session.collateral].minCollateralRatio);
        require(minCollateralAmount >= session.collateralAmount, "NenoMint: liquidate safe session");
        
        uint256 discount = collateralConfig[session.collateral].liquidateDiscount;
        uint256 discountCollateralAmount = liquidateAmount.mul(BASE).mul(BASE).div(price).div(discount);

        uint256 refundAmount = 0;
        uint256 returnAmount = session.collateralAmount;
        if (discountCollateralAmount > session.collateralAmount) {
            refundAmount = discountCollateralAmount.sub(session.collateralAmount).mul(price).mul(discount).div(BASE).div(BASE);
            assetToken.safeTransfer(msg.sender, refundAmount);
        } else {
            returnAmount = discountCollateralAmount;
        }
        liquidateAmount = liquidateAmount.sub(refundAmount);
        uint256 leftAssetAmount = session.assetAmount.sub(liquidateAmount);
        uint256 leftCollateralAmount = session.collateralAmount.sub(returnAmount);

        if (leftCollateralAmount == 0) {
            _itmapRemove(_sessionID);
        } else if (leftAssetAmount == 0) {
            _itmapRemove(_sessionID);
            session.collateral.safeTransfer(session.owner, leftCollateralAmount);
        } else {
            session.collateralAmount = leftCollateralAmount;
            session.assetAmount = leftAssetAmount;
        }
        WrappedToken(assetToken).burn(liquidateAmount, msg.sender);

        uint256 fee = feeTo == address(0) ? 0 : returnAmount.mul(feeRate).div(BASE);
        returnAmount = returnAmount.sub(fee);
        session.collateral.safeTransfer(msg.sender, returnAmount);
        if (fee > 0) {
            session.collateral.safeTransfer(feeTo, fee);
        }
        emit Liquidate( _sessionID, session.owner, returnAmount, liquidateAmount, fee);
    }
    
    function _getSession(uint256 _sessionID) view internal returns (Session storage) {
        require(sessions.data[_sessionID].value.idx > 0, "StableMint: invalid sessionID");
        return sessions.data[_sessionID].value;
    }
    
    function getSession(uint256 _sessionID) view external returns (Session memory) {
        return _getSession(_sessionID);
    }
    
    function getSessions(uint256 start, uint256 limit, bool isAsc) external view returns (Session[] memory sessionsResponse, uint256 len) {
        if (limit == 0) {
            return (sessionsResponse , len);
        }
        if (limit > MAX_LIMIT) {
            limit = MAX_LIMIT;
        }
        sessionsResponse = new Session[](limit);
        len = 0;
        uint256 keyindex = 1; 
        if (start != 0) {
            if (!_itmapContains(start) ) {
                return (sessionsResponse , len);
            }
            keyindex = _itmapKeyindex(start);
        }
        if (isAsc) {
            if (start != 0) {
                keyindex++;
            }
            if (keyindex >= sessionID) {
                return (sessionsResponse, len);
            }
            if (_itmapDelete(keyindex)) {
                keyindex = _itmapIterateNext(keyindex);
            }
            for ( uint256 i = keyindex; _itmapIterateValid(i) && (len < limit);
                i = _itmapIterateNext(i)) {
                sessionsResponse[len++] = _itmapIterateGet(i);
            }
        } else {
            if (start == 0) {
                keyindex = _itmapKeyindex(sessionID - 1);
            } else {
                if (keyindex <= 1) {
                    return (sessionsResponse, len);
                }
                keyindex--;
            } 
            if (_itmapDelete(keyindex)) {
                keyindex = _itmapIteratePrev(keyindex);
            }
            for (uint256 i = keyindex; _itmapIterateValid(i) && (len < limit);
                i = _itmapIteratePrev(i)) {
                sessionsResponse[len++] = _itmapIterateGet(i);
            }
        }
    }

    function getSessionsByUser(address user, uint256 start, uint256 limit, bool isAsc) external view returns (Session[] memory sessionsResponse, uint256 len) {
        if (limit == 0) {
            return (sessionsResponse , len);
        }
        if (limit > MAX_LIMIT) {
            limit = MAX_LIMIT;
        }
        sessionsResponse = new Session[](limit);
        len = 0;
        uint256[] storage userSessions = sessions.indexUser[user];
        if (start > 0 && !_itmapContains(start)) {
            return (sessionsResponse, len);
        }
        uint256 subIndex = _itmapUserKeyindex(start);
        if (start > 0) {
            if (subIndex == 0) {
                return (sessionsResponse, len);
            }
            subIndex--;
        }
        if (isAsc) {
            if (start != 0) {
                subIndex++;
            }
            for (uint256 i = subIndex; (i < userSessions.length) && (len < limit);
                i++) {
                if (_itmapDelete(_itmapKeyindex(userSessions[i]))) {
                    continue;
                }
                sessionsResponse[len++] = sessions.data[userSessions[i]].value;
            }
        } else {
            if (start == 0) {
                subIndex = userSessions.length;
            }
            int256 index = int256(subIndex);
            index--;
            for (int256 i = index; (i >= 0) && (len < limit); i--) {
                if (_itmapDelete(_itmapKeyindex(userSessions[uint256(i)]))) {
                    continue;
                }
                sessionsResponse[len++] = sessions.data[userSessions[uint256(i)]].value;
            }
        }
    }

    function getSessionsByColetarel(address collateral, uint256 start, uint256 limit, bool isAsc) external view returns (Session[] memory sessionsResponse, uint256 len) {
        if (limit == 0) {
            return (sessionsResponse , len);
        }
        if (limit > MAX_LIMIT) {
            limit = MAX_LIMIT;
        }
        sessionsResponse = new Session[](limit);
        len = 0;
        uint256[] storage collateralSessions = sessions.indexCollateral[collateral];
        if (start > 0 && !_itmapContains(start)) {
            return (sessionsResponse, len);
        }
        uint256 subIndex = _itmapCollateralKeyindex(start);
        if (start > 0) {
            if (subIndex == 0) { 
                return (sessionsResponse, len);
            }
            subIndex--;
        }
        if (isAsc) {
            if (start != 0) {
                subIndex++;
            }
            for ( uint256 i = subIndex; (i < collateralSessions.length) && (len < limit);
                i++) {
                if (_itmapDelete(_itmapKeyindex(collateralSessions[i]))) {
                    continue;
                }
                sessionsResponse[len++] = sessions.data[collateralSessions[i]].value;
            }
        } else {
            if (start == 0) {
                subIndex = collateralSessions.length;
            }
            int256 index = int256(subIndex);
            index--;
            for (int256 i = index; (i >= 0) && (len < limit); i--) {
                if (_itmapDelete(_itmapKeyindex(collateralSessions[uint256(i)]))) {
                    continue;
                }
                sessionsResponse[len++] = sessions.data[collateralSessions[uint256(i)]].value;
            }
        }
    }
    
    function matchAsset(address collateralToken, uint256 collateralAmount, uint256 collateralRatio) view public returns (uint256) {
        uint256 price = _loadPrice(collateralToken);
        return _matchAsset(collateralAmount, price, collateralRatio);
    }
    
    function matchCollateral(address collateralToken, uint256 assetAmount, uint256 collateralRatio) view public returns (uint256) {
        uint256 price = _loadPrice(collateralToken);
        return _matchCollateral(assetAmount, price, collateralRatio);
    }
    
    function _loadPrice(address token) internal view returns (uint256) {
        (uint256 price, ) = MintOracle(oracle).getPrice(token);
        require(price > 0, "StableMint: zero price");
        return price;
    }
    
    function _matchAsset(uint256 collateralAmount, uint256 price, uint256 collateralRatio) pure internal returns (uint256) {
        return collateralAmount.mul(price).div(collateralRatio);
    }
    
    function _matchCollateral(uint256 assetAmount, uint256 price, uint256 collateralRatio) pure internal returns (uint256) {
        return assetAmount.mul(collateralRatio).div(price);
    }
    
    function _itmapInsertOrUpdate(uint256 key, Session memory value) internal returns (bool) {
        uint256 keyIndex = sessions.data[key].keyIndex;
        sessions.data[key].value = value;
        if (keyIndex > 0) return false;

        sessions.keys.push(KeyFlag({key: key, deleted: false}));
        sessions.data[key].keyIndex = sessions.keys.length;
        sessions.indexCollateral[value.collateral].push(key);
        sessions.data[key].collateralKeyIndex = sessions.indexCollateral[value.collateral].length;
        sessions.indexUser[value.owner].push(key);
        sessions.data[key].userKeyIndex = sessions.indexUser[value.owner].length;
        sessions.size++;
        return true;
    }

    function _itmapRemove(uint256 key) internal returns (bool) {
        uint256 keyIndex = sessions.data[key].keyIndex;
        require(keyIndex > 0, "_itmapRemove internal error");
        if (sessions.keys[keyIndex - 1].deleted) return false;
        delete sessions.data[key].value;
        sessions.keys[keyIndex - 1].deleted = true;
        sessions.size--;
        return true;
    }

    function _itmapContains(uint256 key) internal view returns (bool) {
        return sessions.data[key].keyIndex > 0;
    }

    function _itmapKeyindex(uint256 key) internal view returns (uint256) {
        return sessions.data[key].keyIndex;
    }

    function _itmapUserKeyindex(uint256 key) internal view returns (uint256) {
        return sessions.data[key].userKeyIndex;
    }

    function _itmapCollateralKeyindex(uint256 key) internal view returns (uint256) {
        return sessions.data[key].collateralKeyIndex;
    }

    function _itmapDelete(uint256 keyIndex) internal view returns (bool) {
        if (keyIndex == 0) {
            return true;
        }
        return sessions.keys[keyIndex-1].deleted;
    }

    function _itmapIterateValid(uint256 keyIndex) internal view returns (bool) {
        return keyIndex != 0 && keyIndex <= sessions.keys.length;
    }

    function _itmapIterateNext(uint256 keyIndex) internal view returns (uint256) {
        keyIndex++;
        while (
            keyIndex < sessions.keys.length && sessions.keys[keyIndex-1].deleted
        ) keyIndex++;
        return keyIndex;
    }

    function _itmapIteratePrev(uint256 keyIndex) internal view returns (uint256) {
        if (keyIndex > sessions.keys.length || keyIndex == 0) return sessions.keys.length;

        keyIndex--;
        while (keyIndex > 0 && sessions.keys[keyIndex-1].deleted) keyIndex--;
        return keyIndex;
    }

    function _itmapIterateGet(uint256 keyIndex) internal view returns (Session storage value) {
        value = sessions.data[sessions.keys[keyIndex-1].key].value;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/ERC20Token.sol

pragma solidity ^0.7.6;


contract ERC20Token is ERC20 {
    using SafeMath for uint256;
    uint public identifier;
    address public owner;
    uint256 public price;
    uint8 public result;
    modifier isOwner {
        require(msg.sender == owner, "not an owner");
    _;}
    constructor(uint _identifier, string memory name_, string memory symbol_, uint8 decimals_, uint256 _price, uint8 _result) ERC20(name_, symbol_) {
        _setupDecimals(decimals_);
        identifier = _identifier;
        owner = msg.sender;
        price = _price;
        result = _result;
    }
    function mint(address account, uint256 amount) public isOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public isOwner {
        _burn(account, amount);
    }

}

// File: contracts/Wallet.sol

pragma solidity ^0.7.6;


contract Wallet{
    using SafeMath for uint;
    address public owner;

    mapping(address => uint) public deposits;
    event Deposited(address indexed from, address holder, uint quantity, uint balance);
    event DepositMoved(address indexed from, address holder, uint quantity, uint balance);
    constructor () {
        owner = msg.sender;
    }
    function deposit(address holder) public payable {
        deposits[holder] += msg.value;
        emit Deposited(msg.sender, holder, msg.value, deposits[holder]);
    }
    function moveDeposit(address holder, uint amount) public isOwner{
        require(deposits[holder] >= amount, 'Insufficient deposit');
        deposits[holder] -= amount;
        msg.sender.transfer(amount);
        emit DepositMoved(msg.sender, holder, amount, deposits[holder]);
    }
    function withdraw(uint amount) public returns (bool success){
        require(amount <= deposits[msg.sender], 'Insufficient Deposit');
        deposits[msg.sender] -= amount;
        msg.sender.transfer(amount);
        return true;
    }
    function getDeposit(address holder) public returns (uint256 deposit){
        return deposits[holder];
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    receive() payable external{}
}

// File: contracts/FinancialOption.sol

pragma solidity ^0.7.6;




contract FinancialOption {
    using SafeMath for uint256;
    Wallet public wallet;
    address payable public owner;
    enum Direction {
        Unresolved,
        Yes,
        No
    }

    uint256 scaling = 1000000; //1000000;
    uint256 operatorCommission = 0;//10000; //divided by scaling, 0.1 percent
    uint256 creatorCommission = 0;//30000; //divided by scaling, 0.3 percent

    struct BinaryOption {
        uint256 identifier;
        bool isPrivate;
        string subjectArea;
        string condition;
        uint256 lockingTime;
        uint256 expiry;
        Direction outcome;
        address creator;
        uint256 totalAyes;
        uint256 totalNoos;
    }
    struct Prediction {
        address trader;
        uint256 value;
    }
    BinaryOption[] public options;
    mapping(bytes32 => bool) optionExists;
    mapping(uint256 => Prediction[]) public ayes; //optionId => (address => betAmount)
    mapping(uint256 => Prediction[]) public noos;
    mapping(address => uint256) public deposits;
    mapping(uint256 => address) public yesContracts;
    mapping(uint256 => address) public noContracts;

    event OptionCreated(
        uint256 identifier,
        string indexed subject,
        string condition,
        uint256 lockingTime,
        uint256 expiry
    );
    event OptionPlaced(
        uint256 indexed identifier,
        address trader,
        Direction prediction,
        uint256 amount,
        uint256 totalAyes, 
        uint256 totalNoos
    );
    event OptionResolved(uint256 indexed identifier, Direction prediction);
    event OptionCalculate(
        uint256 indexed identifier,
        uint256 yPrice,
        uint256 nPrice,
        uint256 yTotal,
        uint256 noTotal
    );
    event OptionPaidOut(
        uint256 indexed identifier,
        Direction result,
        address trader,
        uint256 price,
        uint256 units,
        uint256 crComm,
        uint256 opComm
    );

    constructor() {
        owner = msg.sender;
        wallet = new Wallet();
    }

    function setOperatorCommission(uint _operatorCommission) external isOwner{
        require(_operatorCommission < scaling / 100) ; //less than 1 percent
        operatorCommission = _operatorCommission;
    }
    function setCreatorCommission(uint _creatorCommission) external isOwner{
        require(_creatorCommission < scaling / 100) ; //less than 1 percent
        creatorCommission = _creatorCommission;
    }
    function setScaling(uint _scaling) external isOwner{
        scaling = _scaling;
    }
    function createOptionPrivate(
        string calldata subjectArea,
        string calldata condition,
        uint256 lockingTime,
        uint256 expiry
    ) external {
        createOptionInternal(subjectArea, condition, lockingTime, expiry, true);
    }

    function createOptionPublic(
        string calldata subjectArea,
        string calldata condition,
        uint256 lockingTime,
        uint256 expiry
    ) external isOwner {
        createOptionInternal(
            subjectArea,
            condition,
            lockingTime,
            expiry,
            false
        );
    }

    function createOptionInternal(
        string calldata subjectArea,
        string calldata condition,
        uint256 lockingTime,
        uint256 expiry,
        bool isPrivate
    ) internal {
        bytes32 identifier = keccak256(
            abi.encodePacked(subjectArea, condition, expiry)
        );
        require(!optionExists[identifier], "Option already exists");
        require(expiry > lockingTime, "Expiry should be later than Locking");
        options.push(
            BinaryOption(
                options.length,
                isPrivate,
                subjectArea,
                condition,
                lockingTime,
                expiry,
                Direction.Unresolved,
                msg.sender,
                0,0
            )
        );
        //options.push(binary);
        optionExists[identifier] = true;
        emit OptionCreated(
            options.length,
            subjectArea,
            condition,
            lockingTime,
            expiry
        );
    }

    function getOptionsLength() external view returns (uint256 len) {
        return options.length;
    }

    function makePrediction(uint256 identifier, Direction prediction)
        external
        payable
    {
        require(options[identifier].expiry > 0, "Invalid Option");
        require(
            options[identifier].lockingTime > block.timestamp,
            "Locked. No more predictions allowed"
        );
        require(
            options[identifier].expiry > block.timestamp,
            "Expired. No more predictions allowed"
        );
        require(
            prediction == Direction.Yes || prediction == Direction.No,
            "Invalid Direction"
        );
        BinaryOption storage option = options[identifier];
        if (prediction == Direction.Yes) {
            ayes[identifier].push(Prediction(msg.sender, msg.value));
        } else if (prediction == Direction.No) {
            noos[identifier].push(Prediction(msg.sender, msg.value));
        }
        (uint256 totalAyes, uint256 totalNoos, uint256 ylen, uint256 nolen) = getTotals(identifier);
        option.totalAyes = totalAyes;
        option.totalNoos = totalNoos;
        emit OptionPlaced(identifier, msg.sender, prediction, msg.value, totalAyes, totalNoos);
    }

    function calculateTokens(uint256 identifier) internal {
        (uint256 totalAyes, uint256 totalNoos, uint256 ylen, uint256 nolen) = getTotals(identifier);
        uint256 totalPot = totalAyes + totalNoos;
        uint256 yesPrice = (scaling * totalPot) / totalAyes;
        uint256 noPrice = (scaling * totalPot) / totalNoos;

        _mintTokens(identifier, yesPrice, noPrice, ylen, nolen);
        emit OptionCalculate(
            identifier,
            yesPrice,
            noPrice,
            totalAyes,
            totalNoos
        );
    }
    function getTotals(uint256 identifier) internal returns (uint256 totalAyes, uint256 totalNoos, uint256 ylen, uint256 nolen){
        BinaryOption memory option = options[identifier];
        uint256 ylen = ayes[identifier].length;
        uint256 nolen = noos[identifier].length;
        uint256 totalAyes = 0;
        uint256 totalNoos = 0;
        for (uint256 i = 0; i < ylen; i++) {
            totalAyes += ayes[identifier][i].value;
        }
        for (uint256 i = 0; i < nolen; i++) {
            totalNoos += noos[identifier][i].value;
        }
        return (totalAyes, totalNoos, ylen, nolen);
    }
    function _mintTokens(
        uint256 identifier,
        uint256 yesPrice,
        uint256 noPrice,
        uint256 ylen,
        uint256 nolen
    ) internal {
        ERC20Token yesToken = new ERC20Token(
            identifier,
            "Yes",
            "Yes",
            0,
            yesPrice,
            uint8(Direction.Yes)
        );
        yesContracts[identifier] = address(yesToken);
        ERC20Token noToken = new ERC20Token(
            identifier,
            "No",
            "No",
            0,
            noPrice,
            uint8(Direction.No)
        );
        noContracts[identifier] = address(noToken);
        for (uint256 i = 0; i < ylen; i++) {
            yesToken.mint(
                ayes[identifier][i].trader,
                ayes[identifier][i].value
            );
        }
        for (uint256 i = 0; i < nolen; i++) {
            noToken.mint(noos[identifier][i].trader, noos[identifier][i].value);
        }
    }

    function setOptionResultPrivate(uint256 identifier, Direction result)
        external
    {
        setOptionResultInternal(identifier, result, true);
    }

    function setOptionResultPublic(uint256 identifier, Direction result)
        external
        isOwner
    {
        setOptionResultInternal(identifier, result, false);
    }

    function setOptionResultInternal(
        uint256 identifier,
        Direction result,
        bool isPrivate
    ) internal {
        require(options[identifier].expiry > 0, "Invalid Option");
        require(
            block.timestamp > options[identifier].expiry,
            "Not yet expired"
        );
        require(
            result == Direction.Yes || result == Direction.No,
            "Invalid Direction"
        );
        BinaryOption storage option = options[identifier];
        if (isPrivate) require(option.isPrivate, "Privacy violated");
        if (isPrivate)
            require(
                msg.sender == owner || msg.sender == option.creator,
                "Not the option owner"
            );
        calculateTokens(identifier);
        option.outcome = result;
        emit OptionResolved(identifier, result);
    }

    function receivePayment(uint256 identifier) external {
        BinaryOption memory option = options[identifier];
        require(option.expiry > 0, "Invalid Option");
        require(
            option.outcome != Direction.Unresolved,
            "Option not yet Resolved"
        );
        uint256 price = 0;
        uint256 balance = 0;
        if (option.outcome == Direction.Yes) {
            ERC20Token yesContract = ERC20Token(yesContracts[identifier]);
            balance = yesContract.balanceOf(msg.sender);
            require(balance > 0, "Balance of Yes token 0. Option result Yes");
            yesContract.burn(msg.sender, balance);
            price = yesContract.price();
        } else if (option.outcome == Direction.No) {
            ERC20Token noContract = ERC20Token(noContracts[identifier]);
            balance = noContract.balanceOf(msg.sender);
            require(balance > 0, "Balance of No token 0. Option result No");
            noContract.burn(msg.sender, balance);
            price = noContract.price();
        }
        uint256 amt = (balance * price) / scaling;
        uint256 opCommission = (amt * operatorCommission) / scaling;
        uint256 cCommission = (amt * creatorCommission) / scaling;
        wallet.deposit{value: amt - opCommission - cCommission}(
            msg.sender
        );
        wallet.deposit{value: opCommission}(owner);
        wallet.deposit{value: cCommission}(option.creator);
        OptionPaidOut(
            identifier,
            option.outcome,
            msg.sender,
            price,
            (balance * price) / scaling,
            cCommission,
            opCommission
        );
    }

    receive() external payable {}

    modifier isOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
}
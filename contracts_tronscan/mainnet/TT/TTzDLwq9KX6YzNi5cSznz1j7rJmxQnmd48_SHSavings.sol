//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    

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
        _transfer(msg.sender, recipient, amount);
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
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
    
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

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
    constructor (string memory name, string memory symbol, uint8 decimals) public {
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
}



//SourceUnit: IERC20.sol

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


//SourceUnit: SHDAO.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract SHDAO is ERC20, ERC20Detailed {

    uint256 public _locked;
    uint256 private _lastTime140;
    uint256 private _lastTime30;
    address private _140;
    address private _30;
    address private _149;
    uint256 private _days140;
    uint256 private _days30;

    constructor () public ERC20Detailed("SHDAO", "SHDAO", 6) {
        _lastTime140 = 1614700799;
        _lastTime30 = 1614700799 + 86400; // 比主玩法晚一天
        _totalSupply = 3190000 * (10 ** uint256(decimals()));
        _locked = 3190000 * (10 ** uint256(decimals()));
    }

    function issue140() public returns (bool){
        require(block.timestamp.sub(_lastTime140) > 86400, "It's not time yet");
        require(_days140 <= 600, "over");
        uint256 amount = 2100 * (10 ** uint256(decimals()));
        if(_days140 == 600){
            amount = 140000 * (10 ** uint256(decimals()));
        }
        _locked = _locked.sub(amount);
        _balances[_140] = _balances[_140].add(amount);

        _lastTime140 = _lastTime140.add(86400);
        _days140 = _days140.add(1);

        emit Transfer(address(0), _140, amount);

        return true;
    }

    function issue30() public returns (bool){
        require(block.timestamp.sub(_lastTime30) > 86400, "It's not time yet");
        require(_days30 < 600, "over");
        uint256 amount = 500 * (10 ** uint256(decimals()));
        _locked = _locked.sub(amount);
        _balances[_30] = _balances[_30].add(amount);

        _lastTime30 = _lastTime30.add(86400);
        _days30 = _days30.add(1);

        emit Transfer(address(0), _30, amount);

        return true;
    }

    function bind140(address address140) public returns (bool){
        require(_140 == address(0), "binded");
        _140 = address140;
        return true;
    }
    
    function bind30(address address30) public returns (bool){
        require(_30 == address(0), "binded");
        _30 = address30;
        return true;
    }
    
    function bind149(address address149) public returns (bool){
        require(_149 == address(0), "binded");
        _149 = address149;
        uint256 amount = 1490000 * (10 ** uint256(decimals()));
        _balances[_149] = _balances[_149].add(amount);
        _locked = _locked.sub(amount);
        emit Transfer(address(0), _149, amount);
        return true;
    }
}

//SourceUnit: SHSavings.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";

contract SHSavings {

    using SafeMath for uint256;

    IERC20 private _sh;
    uint256 public _totalSupply;
    uint256 public _days;
    uint256 public _lastTime;
    uint256 public _totalDestory;
    uint256 public _totalDraw;

    uint256 public _today10;
    uint256 public _today30;
    uint256 public _today90;
    
    struct UserOrderInfo{
        uint256 start;
        uint256 count;
        uint256 totalDestory;
        uint256 totalDraw;
        OrderInfo[] orders;
    }

    struct OrderInfo{
        uint256 leftDays;
        uint256 dayRevenue;
        uint256 lastDrawDay;
    }

    mapping (address => UserOrderInfo) public _orderInfo;

    event Play10(address indexed from, uint256 indexed amount);
    event Play30(address indexed from, uint256 indexed amount);
    event Play90(address indexed from, uint256 indexed amount);
    event Draw(address indexed from, uint256 indexed amount);

    constructor () public{
        // !!!!!!!!!!!!!important ! replace
        _sh = IERC20(0x41af5f244eab134eb7c8a458942b048ada95478f96);
        _totalSupply = 1490000 * 1000000;
        _lastTime = 1614700799;
        // first day can not play
        // _today10 = 0;
        // _today30 = 0;
        // _today90 = 0;
    }

    function issue() public returns (bool){
        require(block.timestamp.sub(_lastTime) > 86400, "It's not time yet");
        _days = _days.add(1);
        _lastTime = _lastTime.add(86400);
        _today10 = 100 * (1000000);
        _today30 = 300 * (1000000);
        _today90 = 600 * (1000000);
        return true;
    }
    
    function play10(uint256 amount) public returns (bool){
        require(_today10 >= amount, "limited");
        require(receive(amount));
        _today10 = _today10.sub(amount);
        require(makeOrder(amount, 10, 105), "make order error");
        emit Play10(msg.sender, amount);
        return true;
    }

    function play30(uint256 amount) public returns (bool){
        require(_today30 >= amount, "limited");
        require(receive(amount));
        _today30 = _today30.sub(amount);
        require(makeOrder(amount, 30, 121), "make order error");
        emit Play30(msg.sender, amount);
        return true;
    }

    function play90(uint256 amount) public returns (bool){
        require(_today90 >= amount, "limited");
        require(receive(amount));
        _today90 = _today90.sub(amount);
        require(makeOrder(amount, 90, 190), "make order error");
        emit Play90(msg.sender, amount);
        return true;
    }

    function makeOrder(uint256 amount, uint256 totalDays, uint256 rate) internal returns (bool){
        // total 105%
        _totalSupply = _totalSupply.sub(amount.mul(rate).div(100));
        // every day 10.5% total 10 days
        _orderInfo[msg.sender].orders.push(OrderInfo(totalDays, amount.mul(rate).div(100).div(totalDays), _days));
        _orderInfo[msg.sender].count = _orderInfo[msg.sender].count.add(1);
        return true;
    }

    function receive(uint256 amount) internal returns (bool){
        require(amount > 0, "amount zero");
        require(_sh.transferFrom(msg.sender, address(0), amount), "transfer error");
        _orderInfo[msg.sender].totalDestory = _orderInfo[msg.sender].totalDestory.add(amount);
        _totalDestory = _totalDestory.add(amount);
        return true;
    }

    function draw(uint256 orders) public returns (bool){
        require(orders > 0, "orders zero");
        uint256 result = 0;
        uint256 index = _orderInfo[msg.sender].start;
        uint256 end = _orderInfo[msg.sender].count;
        while(orders > 0 && index < end){
            uint256 maxTimes = min(_days - _orderInfo[msg.sender].orders[index].lastDrawDay, _orderInfo[msg.sender].orders[index].leftDays);

            _orderInfo[msg.sender].orders[index].leftDays = _orderInfo[msg.sender].orders[index].leftDays.sub(maxTimes);
            _orderInfo[msg.sender].orders[index].lastDrawDay = _orderInfo[msg.sender].orders[index].lastDrawDay.add(maxTimes);

            result = result.add(_orderInfo[msg.sender].orders[index].dayRevenue.mul(maxTimes));

            if(_orderInfo[msg.sender].orders[index].leftDays == 0){
                if(_orderInfo[msg.sender].start == index){
                    _orderInfo[msg.sender].start = _orderInfo[msg.sender].start.add(1);
                }
            }
            index ++;
            orders --;
        }
        if(result > 0){
            require(_sh.transfer(msg.sender, result), "transfer error");
            _totalDraw = _totalDraw.add(result);
            _orderInfo[msg.sender].totalDraw = _orderInfo[msg.sender].totalDraw.add(result);
            emit Draw(msg.sender, result);
        }
        return true;
    }

    function calc(uint256 orders) public view returns(uint256){
        uint256 result = 0;
        uint256 index = _orderInfo[msg.sender].start;
        uint256 end = _orderInfo[msg.sender].count;
        while(orders > 0 && index < end){
            uint256 maxTimes = min(_days - _orderInfo[msg.sender].orders[index].lastDrawDay, _orderInfo[msg.sender].orders[index].leftDays);
            result = result.add(_orderInfo[msg.sender].orders[index].dayRevenue.mul(maxTimes));
            index ++;
            orders --;
        }
        return result;
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256){
        if(a > b){
            return a;
        }
        return b;
    }
    function min(uint256 a, uint256 b) internal pure returns(uint256){
        if(a < b){
            return a;
        }
        return b;
    }
    function getOrder(uint256 index) public view returns(uint256 leftDay, uint256 dayRenvenue, uint256 lastDrawDay){
        return (
            _orderInfo[msg.sender].orders[index].leftDays,
            _orderInfo[msg.sender].orders[index].dayRevenue,
            _orderInfo[msg.sender].orders[index].lastDrawDay
        );
    }
    function getDestory(address account) public view returns(uint256){
        return _orderInfo[account].totalDestory;
    }
    function getDraw(address account) public view returns(uint256){
        return _orderInfo[account].totalDraw;
    }
}

//SourceUnit: SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
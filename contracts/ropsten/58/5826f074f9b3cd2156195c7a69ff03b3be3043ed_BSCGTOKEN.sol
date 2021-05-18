/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.4.23;


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

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _cap;
    
     constructor() public {
        _totalSupply = 0;
        _cap = 100000000*10**18;
     }
     
      /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    /**
    *@dev Returns the cap on the token's total supply.
    */
  function MaxTotalSupply() public view returns (uint256) {
        return _cap;
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
        require(_totalSupply.add(amount) <= _cap, "Cannot mint more than cap");
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
}

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

   /**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function stake() public returns (bool);
    function coinAge() public constant returns (uint256);
    function annualInterest() external constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

library WithPeriod {
    function get(uint periodDuration, uint8 offset, bool offsetBackward)
        internal
        view
        returns (uint256)
    {
        require(offset <= 3000, "range check 0..3000");

        uint256 sisa = block.timestamp % periodDuration;
        uint256 start = block.timestamp - sisa;

        if (offsetBackward) return start - offset * periodDuration;
        else return start + offset * periodDuration;
    }
}

contract BSCGTOKEN is Ownable, ERC20, ERC20Detailed, PoSTokenStandard {
    using SafeMath for uint256;
    
    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 0 days; // minimum age for coin age: 0D
    uint public stakeMaxAge = 1 days; // stake age of full weight: 1D
    uint public maxMintProofOfStake = 10**17; // default 10% annual interest
    uint256 private _totalSupply;
    uint256 private _cap;
    

    struct FreezeCounter {
        uint256 period;
        uint256 newlyFrozen;
        uint256 cummulative;
    }

    // token frozen by address
    // address -> amount frozen
    mapping(address => FreezeCounter) public frozen;

    // to track if address already claim divident for particular period
    // period -> address -> claimed
    mapping(uint256 => mapping(address => bool)) public dividendClaimer;

    // total native token to be distributed
    // period -> bnb
    mapping(uint256 => uint256) public dividendValue;

    // total frozen token
    uint256 public totalFrozen = 0;
    mapping(uint256 => uint256) public frozenToday;
    mapping(uint256 => uint256) public unFrozenToday;
    // this is for calculating the claim, if frozenYesterday = 0 -> frozenYesterday = totalFrozen - frozenToday
    mapping(uint256 => uint256) public frozenYesterday;

    uint256 public periodDuration = 86400;

    uint8 public devFee = 5;
    uint256 public totalForDev = 0;
    bool public allowTotalWithdraw = true;

    // emited when player freeze their balance
    event Froze(
        address who,
        uint256 locked,
        uint256 totalLocked,
        uint256 totalFrozen
    );

    // emited when player unfreeze their balance
    event UnFroze(address who, uint256 released, uint256 totalFrozen);

    // when dev withdraw fund
    event DevWithdraw(address who, uint256 amount);

    // when claim
    event Claimed(address who, uint256 amount);

    // when dividend changes
    event DividendValue(uint256 amount, uint256 period);


    constructor(uint256 _periodDuration)
        public
        ERC20Detailed("BSCGTOKEN", "BSCG", 18)
    {
        periodDuration = _periodDuration;
        // STRICTLY NO PREMINE!
        // _mint(msg.sender, 200_000_000 ether);
    }

    function disableTotalWithdraw() public onlyOwner {
        allowTotalWithdraw = false;
    }

    // donation..
    function() external payable {
        totalForDev = totalForDev.add(msg.value);
    }

    // alpha release helper function.. this function is needed
    function totalWithdraw() public onlyOwner {
        require(allowTotalWithdraw, "total withdraw disabled");
        address(uint160(owner())).transfer(address(this).balance);
    }

    function devWithdraw(uint256 request) public {
        require(
            request < totalForDev,
            "dev should not withdraw greater than what he has"
        );
        address(uint160(owner())).transfer(request);
        emit DevWithdraw(owner(), request);
    }

    // add dividend for current period
    function addDividendValue() public payable {
        uint256 period = WithPeriod.get(periodDuration, 0, true);
        dividendValue[period] = dividendValue[period].add(msg.value);
        emit DividendValue(dividendValue[period], period);
    }


    function getPeriod(uint8 offset, bool forward)
        public
        view
        returns (uint256)
    {
        return WithPeriod.get(periodDuration, offset, forward);
    }

    function freeze() public {
        uint256 today = WithPeriod.get(periodDuration, 0, true);

        uint256 balance = balanceOf(msg.sender);

        if (balance > 0) {
            _burn(msg.sender, balance);
            totalFrozen = totalFrozen.add(balance);
            frozenToday[today] = frozenToday[today].add(balance);

            FreezeCounter storage counter = frozen[msg.sender];

            // if period changed, then we are adding last one to cummulative
            if (counter.period < today) {
                counter.cummulative = counter.cummulative.add(
                    counter.newlyFrozen
                );
                counter.newlyFrozen = 0;
                counter.period = today;
            }

            counter.newlyFrozen = counter.newlyFrozen.add(balance);

            emit Froze(msg.sender, balance, counter.newlyFrozen.add(counter.cummulative), totalFrozen);
        }
    }

    function unfreeze() public {
        FreezeCounter storage counter = frozen[msg.sender];

        uint256 balance = counter.cummulative.add(counter.newlyFrozen);

        if (balance > 0) {
            uint256 today = WithPeriod.get(periodDuration, 0, true);
            uint256 yesterday = WithPeriod.get(periodDuration, 1, true);

            if (
                dividendValue[yesterday] > 0 &&
                dividendClaimer[yesterday][msg.sender] == false
            ) {
                claimDividend(msg.sender);
            }

            counter.cummulative = 0;
            counter.newlyFrozen = 0;
            counter.period = today;

            totalFrozen = totalFrozen.sub(balance);
            unFrozenToday[today] = unFrozenToday[today].add(balance);

            _mint(msg.sender, balance);

            emit UnFroze(msg.sender, balance, totalFrozen);
        }
    }

    function claimDividend(address who) public {
        uint256 today = WithPeriod.get(periodDuration, 0, true);
        uint256 yesterday = WithPeriod.get(periodDuration, 1, true);
        uint256 priorYesterday = WithPeriod.get(periodDuration, 2, true);

        // emit DebugNumber("dividend value", dividendValue[yesterday]);

        require(dividendValue[yesterday] > 0, "we have nothing to claim");

        require(
            dividendClaimer[yesterday][who] == false,
            "dividend already claimed"
        );

        dividendClaimer[yesterday][who] = true;

        if (frozenYesterday[yesterday] == 0) {
            frozenYesterday[yesterday] = frozenYesterday[priorYesterday]
                .add(frozenToday[yesterday])
                .sub(unFrozenToday[yesterday]);
        }

        FreezeCounter storage counter = frozen[who];

        if (counter.period < today) {
            counter.cummulative = counter.cummulative.add(counter.newlyFrozen);
            counter.newlyFrozen = 0;
            counter.period = today;
        }
    }
   

    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canPoSMint() {
      require(_totalSupply < _cap, "Cannot mint more than cap");
        _;
    }
    
   function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function BSCGT() public {
        _totalSupply = 0;
        _cap = 100000000*10**18;

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = _totalSupply;
        _totalSupply = _totalSupply;
    }

    function stake() canPoSMint public returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        _totalSupply = _totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() external view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() public constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() external constant returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 1000%  APY when we select the stakeMaxAge (1 day) as the compounding period.
            interest = (2450 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 500% APY
            interest = (1800 * maxMintProofOfStake).div(100);
        }

        return (_coinAge * interest).div(365);
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        _totalSupply = _totalSupply.sub(_value);
        _cap = _cap.sub(_value*10);

        emit Burn(msg.sender, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) public onlyOwner returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
        emit Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    } 
}
/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
abstract contract ERC20 is Context, IERC20 {
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Token is Ownable, ERC20 {
    using SafeMath for uint256;
    
    event Staked(
        address lpToken,
        address user,
        uint256 amount
    );
    
    event Unstaked(
        address user,
        address lpToken,
        uint256 amount
    );
    
    event RewardWithdrawn(
        address user,
        uint256 amount
    );
    
    uint256 private constant rewardMultiplier = 1e17;
    
    struct Stake {
        mapping(address => uint256) lpToStakeAmount; // lp token address to token amount
        uint256 totalStakedAmountByUser; // sum of all lp tokens
        uint256 lastInteractionBlockNumber; // block number at last withdraw
        address[] lpTokens; // list of all lps
    }
    
    mapping(address => Stake) public userToStakes; // user to stake
    uint256 public totalStakedAmount; // sum of stakes by all of the users across all lp
    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    struct TokenStake {
        uint256 amount;
        uint256 lastInteractionTimestamp;
        uint256 stakingPeriodEndTime;
        uint256 rate;
    }
    
    mapping(address => TokenStake) public userToTokenStakes; // user to test token stake
    
    struct Lockup {
        uint256 duration; // duration in seconds
        uint256 rate; // reward rate
    }
    Lockup[8] public lockupPeriods;
    
    IERC20 public swapToken = IERC20(0xEEd2B7756E295A9300e53dD049AeB0751899BAe3);
    uint256 public swapTokenDecimals = 18;
    address public swapTreasury = 0x4eFfA0933a1099b8F95E34964c36Dfd9b7B1A49a;
    
    uint256 public totalTokensStakedAmount;
    
    uint256 public blockMiningTime = 15;
    uint256 public constant MAX_SUPPLY = 6000000 * 10 ** 18;
    
    constructor() public ERC20("TokenBot", "TKB", 18) {
        // _mint(_msgSender(), 1000 * 10 ** 18); // for testing
        // lockupPeriods[0] = Lockup(200, 1e15); for testing
        lockupPeriods[0] = Lockup(604800, 1e15);
        lockupPeriods[1] = Lockup(2592000, 4e15);
        lockupPeriods[2] = Lockup(5184000, 8e15);
        lockupPeriods[3] = Lockup(7776000, 12e15);
        lockupPeriods[4] = Lockup(15552000, 24e15);
        lockupPeriods[5] = Lockup(31104000, 48e15);
        lockupPeriods[6] = Lockup(63113904, 96e15);
        lockupPeriods[7] = Lockup(126227808, 192e15);
    }
    
    function changeBlockMiningTime(uint256 newTime) external onlyOwner {
        require(
            newTime != 0,
            "new time cannot be zero"
        );
        blockMiningTime = newTime;
    }
    
    function swapAndStakeDOG(
        uint256 swapTokenAmount
    ) external {
        require(
            swapTokenAmount != 0,
            "swapTokenAmount should be greater than 0"
        );
        
        require(
            swapToken.transferFrom(_msgSender(), swapTreasury, swapTokenAmount),
            "#transferFrom failed"
        );
        
        uint256 tokensReceived = swapTokenAmount.mul(10 ** uint256(decimals()))
            .div(250 * 10 ** swapTokenDecimals);
        _mint(_msgSender(), tokensReceived);
        
        stakeTKB(tokensReceived, 0);
    }
    
    function stakeTKB(
        uint256 stakeAmount,
        uint256 lockUpPeriodIdx // 0 - 7 - is represented by index of `lockupPeriods` array.
    ) public {
        require(
            stakeAmount != 0,
            "stakeAmount should be greater than 0"
        );
        
        require(
            lockUpPeriodIdx <= 7,
            "lock lockUpPeriodIdx should be between 0 and 7"
        );
        
        TokenStake storage currentStake = userToTokenStakes[_msgSender()];
        require(
            currentStake.amount == 0,
            "address has already staked"
        );
        
        currentStake.amount = stakeAmount;
        
        currentStake.stakingPeriodEndTime = block.timestamp.add(
            lockupPeriods[lockUpPeriodIdx].duration
        );
        
        currentStake.rate = lockupPeriods[lockUpPeriodIdx].rate;
        
        currentStake.lastInteractionTimestamp = block.timestamp;
        totalTokensStakedAmount = totalTokensStakedAmount.add(stakeAmount);
        
        _transfer(_msgSender(), address(this), stakeAmount);
        
        emit Staked(
            address(this),
            msg.sender,
            stakeAmount
        );
    }
    
    function unstakeTKB() external {
        uint256 amountToUnstake = userToTokenStakes[_msgSender()].amount;
        bool executeUnstaking;
        
        if (amountToUnstake != 0) {
            if (userToTokenStakes[_msgSender()].stakingPeriodEndTime <= block.timestamp) {
                executeUnstaking = true;
            }
            
            if (totalSupply() == MAX_SUPPLY) {
                executeUnstaking = true;
            }
        }
        require(
            executeUnstaking,
            "cannot unstake"
        );
        _withdrawRewardTKB(_msgSender());
        totalTokensStakedAmount = totalTokensStakedAmount.sub(amountToUnstake);
        delete userToTokenStakes[_msgSender()];
        _transfer(address(this), _msgSender(), amountToUnstake);

        emit Unstaked(address(this), _msgSender(), amountToUnstake);
    }    
        
    function withdrawRewardTKB() external {
        _withdrawRewardTKB(_msgSender());
    }
    
    function getTKBRewardByAddress(address user) public view returns(uint256) {
        TokenStake storage currentStake = userToTokenStakes[user];
        
        uint256 secondsElapsed;
        if (block.timestamp > currentStake.stakingPeriodEndTime) {
            if (currentStake.stakingPeriodEndTime < currentStake.lastInteractionTimestamp) {
                return 0;
            }
            secondsElapsed = currentStake.stakingPeriodEndTime
                .sub(currentStake.lastInteractionTimestamp);
        } else {
            secondsElapsed = block.timestamp
                .sub(currentStake.lastInteractionTimestamp);   
        }
        
        uint256 stakeAmount = currentStake.amount;
        uint256 blockCountElapsed = secondsElapsed.div(blockMiningTime);
        
        if (blockCountElapsed == 0 || stakeAmount == 0) {
            return 0;
        }
        
        return currentStake.rate
            .mul(blockCountElapsed)
            .mul(stakeAmount)
            .div(totalTokensStakedAmount);
    }
    
    function _withdrawRewardTKB(address user) internal {
        uint256 rewardAmount = getTKBRewardByAddress(user);
        if (rewardAmount != 0) {
            _mint(_msgSender(), rewardAmount);
            emit RewardWithdrawn(user, rewardAmount);
        }
        userToTokenStakes[_msgSender()].lastInteractionTimestamp = block.timestamp;
    }
    
    function stakeLP(
        uint256 stakeAmount
    ) external {
        require(
            stakeAmount != 0,
            "stakeAmount should be greater than 0"
        );
        
        // only for testing, should be removed.
        // address lpToken = tokenA;

        address lpToken = uniswapFactory.getPair(
            address(this),
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
        
        _withdrawRewardLP(_msgSender());
        
        totalStakedAmount = totalStakedAmount.add(stakeAmount); // add stake amount to sum of all stakes across al lps
        
        Stake storage currentStake = userToStakes[_msgSender()];
        uint256 oldStakeAmountByLP = currentStake.lpToStakeAmount[lpToken];
        
        if (oldStakeAmountByLP == 0) {
            currentStake.lpTokens.push(lpToken);
        }
        
        currentStake.lpToStakeAmount[lpToken] = oldStakeAmountByLP // add stake amount by lp
            .add(stakeAmount);
        
        currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser // add stake amount to sum of all stakes by user
            .add(stakeAmount);
        
        require(
            IERC20(lpToken).transferFrom(_msgSender(), address(this), stakeAmount), // get the tokens from user to the contract
            "#transferFrom failed"
        );
        
        emit Staked(
            lpToken,
            msg.sender,
            stakeAmount
        );
    }
    
    function unstakeLP(
        address[] calldata lpTokens    
    ) external {
        _withdrawRewardLP(_msgSender());
        Stake storage currentStake = userToStakes[_msgSender()];
        address[] storage tokens = currentStake.lpTokens; 
        uint256 stakeAmountToDeduct;
        
        // unstake user for lp tokens provided in the array
        for (uint256 i; i < lpTokens.length; i++) {
            uint256 stakeAmount = currentStake.lpToStakeAmount[
                lpTokens[i]
            ];
            
            if (stakeAmount == 0) {
                revert("unstaking an invalid LP token");
            }
            
            delete currentStake.lpToStakeAmount[
                lpTokens[i]
            ];
            
            currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser
                .sub(stakeAmount);
            
            stakeAmountToDeduct = stakeAmountToDeduct.add(stakeAmount);
            
            for (uint256 p; p < tokens.length; p++) {
                if (lpTokens[i] == tokens[p]) {
                    tokens[p] = tokens[tokens.length - 1];
                    tokens.pop();
                }
            }
            
            require(
                IERC20(lpTokens[i]).transfer(_msgSender(), stakeAmount), // transfer staked tokens back to the user
                "#transfer failed"
            );
            
            emit Unstaked(lpTokens[i], _msgSender(), stakeAmount);
        }
        
        totalStakedAmount = totalStakedAmount.sub(stakeAmountToDeduct); // subtract unstaked amount from total staked amount
    }
    
    function withdrawRewardLP() external {
        _withdrawRewardLP(_msgSender());
    }
    
    function getBlockCountSinceLastIntreraction(address user) public view returns(uint256) {
        uint256 lastInteractionBlockNum = userToStakes[user].lastInteractionBlockNumber;
        if (lastInteractionBlockNum == 0) {
            return 0;
        }
        
        return block.number.sub(lastInteractionBlockNum);
    }
    
    function getTotalStakeAmountByUser(address user) public view returns(uint256) {
        return userToStakes[user].totalStakedAmountByUser;
    }
    
    function getAllLPsByUser(address user) public view returns(address[] memory) {
        return userToStakes[user].lpTokens;
    }
    
    function getStakeAmountByUserByLP(
        address lp,
        address user
    ) public view returns(uint256) {
        return userToStakes[user].lpToStakeAmount[lp];
    }
    
    function getLPRewardByAddress(
        address user
    ) public view returns(uint256) {
        if (totalStakedAmount == 0) {
            return 0;
        }
        
        Stake storage currentStake = userToStakes[user];
        
        uint256 blockCount = block.number
            .sub(currentStake.lastInteractionBlockNumber);
        
        uint256 totalReward = blockCount.mul(rewardMultiplier);
        
        return totalReward
            .mul(currentStake.totalStakedAmountByUser)
            .div(totalStakedAmount);
    }
    
    function _withdrawRewardLP(address user) internal {
        uint256 rewardAmount = getLPRewardByAddress(user);
        
        if (rewardAmount != 0) {
            _mint(user, rewardAmount); // mint reward Tokens for the user
            emit RewardWithdrawn(user, rewardAmount);
        }
        
        userToStakes[user].lastInteractionBlockNumber = block.number;
    }

    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply().add(amount) <= MAX_SUPPLY,
            "total supply exceeds max supply"
        );
        super._mint(account, amount);
    }
}
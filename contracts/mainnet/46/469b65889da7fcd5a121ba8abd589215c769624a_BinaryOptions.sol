/**
 *Submitted for verification at Etherscan.io on 2021-01-16
*/

pragma solidity ^0.6.6;



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

// SPDX-License-Identifier: MIT

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
contract BIOPToken is ERC20 {
    using SafeMath for uint256;
    address public binaryOptions = 0x0000000000000000000000000000000000000000;
    address public gov;
    address public owner;
    uint256 public earlyClaimsAvailable = 450000000000000000000000000000;
    uint256 public totalClaimsAvailable = 300000000000000000000000000000;
    bool public earlyClaims = true;
    bool public binaryOptionsSet = false;

    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
      owner = msg.sender;
    }
    
    modifier onlyBinaryOptions() {
        require(binaryOptions == msg.sender, "Ownable: caller is not the Binary Options Contract");
        _;
    }
    modifier onlyOwner() {
        require(binaryOptions == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function updateEarlyClaim(uint256 amount) external onlyBinaryOptions {
        require(totalClaimsAvailable.sub(amount) >= 0, "insufficent claims available");
        require (earlyClaims, "Launch has closed");
        
        earlyClaimsAvailable = earlyClaimsAvailable.sub(amount);
        _mint(tx.origin, amount);
        if (earlyClaimsAvailable <= 0) {
            earlyClaims = false;
        }
    }

     function updateClaim( uint256 amount) external onlyBinaryOptions {
        require(totalClaimsAvailable.sub(amount) >= 0, "insufficent claims available");
        totalClaimsAvailable.sub(amount);
        _mint(tx.origin, amount);
    }

    function setupBinaryOptions(address payable options_) external {
        require(binaryOptionsSet != true, "binary options is already set");
        binaryOptions = options_;
    }

    function setupGovernance(address payable gov_) external onlyOwner {
        _mint(owner, 100000000000000000000000000000);
        _mint(gov_, 450000000000000000000000000000);
        owner = 0x0000000000000000000000000000000000000000;
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}



interface IRC {
    /**
     * @notice Returns the rate to pay out for a given amount
     * @param amount the bet amount to calc a payout for
     * @param maxAvailable the total pooled ETH unlocked and available to bet
     * @return profit total possible profit amount
     */
    function rate(uint256 amount, uint256 maxAvailable) external view returns (uint256);

}

contract RateCalc is IRC {
    using SafeMath for uint256;
     /**
     * @notice Calculates maximum option buyer profit
     * @param amount Option amount
     * @return profit total possible profit amount
     */
    function rate(uint256 amount, uint256 maxAvailable) external view override returns (uint256)  {
        require(amount <= maxAvailable, "greater then pool funds available");
        uint256 oneTenth = amount.div(10);
        uint256 halfMax = maxAvailable.div(2);
        if (amount > halfMax) {
            return amount.mul(2).add(oneTenth).add(oneTenth);
        } else {
            if(oneTenth > 0) {
                return amount.mul(2).sub(oneTenth);
            } else {
                uint256 oneThird = amount.div(4);
                require(oneThird > 0, "invalid bet amount");
                return amount.mul(2).sub(oneThird);
            }
        }
        
    }
}



/**
 * @title Binary Options Eth Pool
 * @author github.com/Shalquiana
 * @dev Pool ETH Tokens and use it for optionss
 * Biop
 */
contract BinaryOptions is ERC20 {
    using SafeMath for uint256;
    address payable devFund;
    address payable owner;
    address public biop;
    address public rcAddress;//address of current rate calculators
    mapping(address=>uint256) public nextWithdraw;
    mapping(address=>bool) public enabledPairs;
    uint256 public minTime;
    uint256 public maxTime;
    address public defaultPair;
    uint256 public lockedAmount;
    uint256 public exerciserFee = 50;//in tenth percent
    uint256 public expirerFee = 50;//in tenth percent
    uint256 public devFundBetFee = 2;//tenth of percent
    uint256 public poolLockSeconds = 2 days;
    uint256 public contractCreated;
    uint256 public launchEnd;
    bool public open = true;
    Option[] public options;
    
    //reward amounts
    uint256 aStakeReward = 120000000000000000000;
    uint256 bStakeReward = 60000000000000000000;
    uint256 betReward = 40000000000000000000;
    uint256 exerciseReward = 2000000000000000000;


    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    /* Types */
    enum OptionType {Put, Call}
    enum State {Active, Exercised, Expired}
    struct Option {
        State state;
        address payable holder;
        uint256 strikePrice;
        uint256 purchaseValue;
        uint256 lockedValue;//purchaseAmount+possible reward for correct bet
        uint256 expiration;
        OptionType optionType;
        address priceProvider;
    }

    /* Events */
     event Create(
        uint256 indexed id,
        address payable account,
        uint256 strikePrice,
        uint256 lockedValue,
        OptionType direction
    );
    event Payout(uint256 poolLost, address winner);
    event Exercise(uint256 indexed id);
    event Expire(uint256 indexed id);


    function getMaxAvailable() public view returns(uint256) {
        uint256 balance = address(this).balance;
        if (balance > lockedAmount) {
            return balance.sub(lockedAmount);
        } else {
            return 0;
        }
    }

    constructor(string memory name_, string memory symbol_, address pp_, address biop_, address rateCalc_) public ERC20(name_, symbol_){
        devFund = msg.sender;
        owner = msg.sender;
        biop = biop_;
        rcAddress = rateCalc_;
        lockedAmount = 0;
        contractCreated = block.timestamp;
        launchEnd = block.timestamp+28 days;
        enabledPairs[pp_] = true; //default pair ETH/USD
        defaultPair = pp_;
        minTime = 900;//15 minutes
        maxTime = 60 minutes;
    }

    /**
     * @dev the default price provider. This is a convenience method
     */
    function defaultPriceProvider() public view returns (address) {
        return defaultPair;
    }


     /**
     * @dev add a price provider to the enabledPairs list
     * @param newRC_ the address of the AggregatorV3Interface price provider contract address to add.
     */
    function setRateCalcAddress(address newRC_) external onlyOwner {
        rcAddress = newRC_; 
    }

    /**
     * @dev add a price provider to the enabledPairs list
     * @param newPP_ the address of the AggregatorV3Interface price provider contract address to add.
     */
    function addPP(address newPP_) external onlyOwner {
        enabledPairs[newPP_] = true; 
    }

   

    /**
     * @dev remove a price provider from the enabledPairs list
     * @param oldPP_ the address of the AggregatorV3Interface price provider contract address to remove.
     */
    function removePP(address oldPP_) external onlyOwner {
        enabledPairs[oldPP_] = false;
    }

    /**
     * @dev update the max time for option bets
     * @param newMax_ the new maximum time (in seconds) an option may be created for (inclusive).
     */
    function setMaxTime(uint256 newMax_) external onlyOwner {
        maxTime = newMax_;
    }

    /**
     * @dev update the max time for option bets
     * @param newMin_ the new minimum time (in seconds) an option may be created for (inclusive).
     */
    function setMinTime(uint256 newMin_) external onlyOwner {
        minTime = newMin_;
    }

    /**
     * @dev address of this contract, convenience method
     */
    function thisAddress() public view returns (address){
        return address(this);
    }

    /**
     * @dev set the fee users can recieve for exercising other users options
     * @param exerciserFee_ the new fee (in tenth percent) for exercising a options itm
     */
    function updateExerciserFee(uint256 exerciserFee_) external onlyOwner {
        require(exerciserFee_ > 1 && exerciserFee_ < 500, "invalid fee");
        exerciserFee = exerciserFee_;
    }

     /**
     * @dev set the fee users can recieve for expiring other users options
     * @param expirerFee_ the new fee (in tenth percent) for expiring a options
     */
    function updateExpirerFee(uint256 expirerFee_) external onlyOwner {
        require(expirerFee_ > 1 && expirerFee_ < 50, "invalid fee");
        expirerFee = expirerFee_;
    }

    /**
     * @dev set the fee users pay to buy an option
     * @param devFundBetFee_ the new fee (in tenth percent) to buy an option
     */
    function updateDevFundBetFee(uint256 devFundBetFee_) external onlyOwner {
        require(devFundBetFee_ >= 0 && devFundBetFee_ < 50, "invalid fee");
        devFundBetFee = devFundBetFee_;
    }

     /**
     * @dev update the pool stake lock up time.
     * @param newLockSeconds_ the new lock time, in seconds
     */
    function updatePoolLockSeconds(uint256 newLockSeconds_) external onlyOwner {
        require(newLockSeconds_ >= 0 && newLockSeconds_ < 14 days, "invalid fee");
        poolLockSeconds = newLockSeconds_;
    }

    /**
     * @dev used to transfer ownership
     * @param newOwner_ the address of governance contract which takes over control
     */
    function transferOwner(address payable newOwner_) external onlyOwner {
        owner = newOwner_;
    }
    
    /**
     * @dev used to transfer devfund 
     * @param newDevFund the address of governance contract which takes over control
     */
    function transferDevFund(address payable newDevFund) external onlyOwner {
        devFund = newDevFund;
    }


     /**
     * @dev used to send this pool into EOL mode when a newer one is open
     */
    function closeStaking() external onlyOwner {
        open = false;
    }

    /**
     * @dev update the amount of early user governance tokens that have been assigned
     * @param amount the amount assigned
     */
    function updateRewards(uint256 amount) internal {
        BIOPToken b = BIOPToken(biop);
        if (b.earlyClaims()) {
            b.updateEarlyClaim(amount.mul(4));
        } else if (b.totalClaimsAvailable() > 0){
            b.updateClaim(amount);
        }
    }


    /**
     * @dev send ETH to the pool. Recieve pETH token representing your claim.
     * If rewards are available recieve BIOP governance tokens as well.
    */
    function stake() external payable {
        require(open == true, "pool deposits has closed");
        require(msg.value >= 100, "stake to small");
        if (block.timestamp < launchEnd) {
            nextWithdraw[msg.sender] = block.timestamp + 14 days;
            _mint(msg.sender, msg.value);
        } else {
            nextWithdraw[msg.sender] = block.timestamp + poolLockSeconds;
            _mint(msg.sender, msg.value);
        }

        if (msg.value >= 2000000000000000000) {
            updateRewards(aStakeReward);
        } else {
            updateRewards(bStakeReward);
        }
    }

    /**
     * @dev recieve ETH from the pool. 
     * If the current time is before your next available withdraw a 1% fee will be applied.
     * @param amount The amount of pETH to send the pool.
    */
    function withdraw(uint256 amount) public {
       require (balanceOf(msg.sender) >= amount, "Insufficent Share Balance");

        uint256 valueToRecieve = amount.mul(address(this).balance).div(totalSupply());
        _burn(msg.sender, amount);
        if (block.timestamp <= nextWithdraw[msg.sender]) {
            //early withdraw fee
            uint256 penalty = valueToRecieve.div(100);
            require(devFund.send(penalty), "transfer failed");
            require(msg.sender.send(valueToRecieve.sub(penalty)), "transfer failed");
        } else {
            require(msg.sender.send(valueToRecieve), "transfer failed");
        }
    }

     /**
    @dev Open a new call or put options.
    @param type_ type of option to buy
    @param pp_ the address of the price provider to use (must be in the list of enabledPairs)
    @param time_ the time until your options expiration (must be minTime < time_ > maxTime)
    */
    function bet(OptionType type_, address pp_, uint256 time_) external payable {
        require(
            type_ == OptionType.Call || type_ == OptionType.Put,
            "Wrong option type"
        );
        require(
            time_ >= minTime && time_ <= maxTime,
            "Invalid time"
        );
        require(msg.value >= 100, "bet to small");
        require(enabledPairs[pp_], "Invalid  price provider");
        uint depositValue;
        if (devFundBetFee > 0) {
            uint256 fee = msg.value.div(devFundBetFee).div(100);
            require(devFund.send(fee), "devFund fee transfer failed");
            depositValue = msg.value.sub(fee);
            
        } else {
            depositValue = msg.value;
        }

        RateCalc rc = RateCalc(rcAddress);
        uint256 lockValue = getMaxAvailable();
        lockValue = rc.rate(depositValue, lockValue.sub(depositValue));
        


         
        AggregatorV3Interface priceProvider = AggregatorV3Interface(pp_);
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint256 optionID = options.length;
        uint256 totalLock = lockValue.add(depositValue);
        Option memory op = Option(
            State.Active,
            msg.sender,
            uint256(latestPrice),
            depositValue,
            totalLock,//purchaseAmount+possible reward for correct bet
            block.timestamp + time_,//all options 1hr to start
            type_,
            pp_
        );
        lock(totalLock);
        options.push(op);
        emit Create(optionID, msg.sender, uint256(latestPrice), totalLock, type_);
        updateRewards(betReward);
    }

     /**
     * @notice exercises a option
     * @param optionID id of the option to exercise
     */
    function exercise(uint256 optionID)
        external
    {
        Option memory option = options[optionID];
        require(block.timestamp <= option.expiration, "expiration date margin has passed");
        AggregatorV3Interface priceProvider = AggregatorV3Interface(option.priceProvider);
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint256 uLatestPrice = uint256(latestPrice);
        if (option.optionType == OptionType.Call) {
            require(uLatestPrice > option.strikePrice, "price is to low");
        } else {
            require(uLatestPrice < option.strikePrice, "price is to high");
        }

        //option expires ITM, we pay out
        payout(option.lockedValue.sub(option.purchaseValue), msg.sender, option.holder);
        
        lockedAmount = lockedAmount.sub(option.lockedValue);
        emit Exercise(optionID);
        updateRewards(exerciseReward);
    }

     /**
     * @notice expires a option
     * @param optionID id of the option to expire
     */
    function expire(uint256 optionID)
        external
    {
        Option memory option = options[optionID];
        require(block.timestamp > option.expiration, "expiration date has not passed");
        unlock(option.lockedValue.sub(option.purchaseValue), msg.sender, expirerFee);
        emit Expire(optionID);
        lockedAmount = lockedAmount.sub(option.lockedValue);

        updateRewards(exerciseReward);
    }

    /**
    @dev called by BinaryOptions contract to lock pool value coresponding to new binary options bought. 
    @param amount amount in ETH to lock from the pool total.
    */
    function lock(uint256 amount) internal {
        lockedAmount = lockedAmount.add(amount);
    }

    /**
    @dev called by BinaryOptions contract to unlock pool value coresponding to an option expiring otm. 
    @param amount amount in ETH to unlock
    @param goodSamaritan the user paying to unlock these funds, they recieve a fee
    */
    function unlock(uint256 amount, address payable goodSamaritan, uint256 eFee) internal {
        require(amount <= lockedAmount, "insufficent locked pool balance to unlock");
        uint256 fee = amount.div(eFee).div(100);
        if (fee > 0) {
            require(goodSamaritan.send(fee), "good samaritan transfer failed");
        }
    }

    /**
    @dev called by BinaryOptions contract to payout pool value coresponding to binary options expiring itm. 
    @param amount amount in BIOP to unlock
    @param exerciser address calling the exercise/expire function, this may the winner or another user who then earns a fee.
    @param winner address of the winner.
    @notice exerciser fees are subject to change see updateFeePercent above.
    */
    function payout(uint256 amount, address payable exerciser, address payable winner) internal {
        require(amount <= lockedAmount, "insufficent pool balance available to payout");
        require(amount <= address(this).balance, "insufficent balance in pool");
        if (exerciser != winner) {
            //good samaratin fee
            uint256 fee = amount.div(exerciserFee).div(100);
            if (fee > 0) {
                require(exerciser.send(fee), "exerciser transfer failed");
                require(winner.send(amount.sub(fee)), "winner transfer failed");
            }
        } else {  
            require(winner.send(amount), "winner transfer failed");
        }
        emit Payout(amount, winner);
    }

}
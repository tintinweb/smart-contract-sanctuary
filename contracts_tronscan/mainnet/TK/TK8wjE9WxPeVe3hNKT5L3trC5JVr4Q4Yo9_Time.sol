//SourceUnit: time_trc20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the trc token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

contract TRC20TokenImplementation is Context, ITRC20, Initializable {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool internal _mintable;

    constructor() public {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Returns if the token is mintable or not
     */
    function mintable() external view returns (bool) {
        return _mintable;
    }

    /**
     * @dev Returns the trc token owner.
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {TRC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {TRC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {TRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {TRC20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {TRC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {TRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {TRC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {TRC20-approve}.
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
     * problems described in {TRC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     * - `_mintable` must be true
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(_mintable, "this token is not mintable");
        _mint(_msgSender(), amount);
        return true;
    }

    /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
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
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
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
        require(account != address(0), "TRC20: mint to the zero address");

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
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
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
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "TRC20: burn amount exceeds allowance"));
    }
}

contract Time is TRC20TokenImplementation {

    address private _liquidity;
    address private _baseCurrency;

    uint256 private _startPrice;
    uint256 private _endPrice;
    uint256 private _nextStartPrice;
    uint256 private _nextEndPrice;

    uint256 private _startTimeStamp;
    uint256 private _endTimeStamp;
    uint256 private _nextStartTimeStamp;
    uint256 private _nextEndTimeStamp;

    event LiquidityChanged(address previousLiquidity, address newLiquidity);
    event BaseCurrencyChanged(address previousBaseCurrency, address newBaseCurrency, uint256 rate);
    event TimeBought(uint256 timeAmount, uint256 baseCurrencyAmount, address buyer);
    event TimeSold(uint256 timeAmount, uint256 baseCurrencyAmount, address seller);
    event InterestProved(uint256 nextStartTimeStamp, uint256 nextEndTimeStamp, uint256 nextStartPrice, uint256 nextEndPrice, uint256 releasedCoins);

    constructor() public {
    }

    /**
     * @dev sets initials supply and the owner
     */
    function initialize(string calldata name, string calldata symbol, uint8 decimals, uint256 amount, bool mintable, address owner, address liquidityIn, address baseCurrencyIn) external initializer {
        _owner = owner;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mintable = mintable;
        _liquidity = liquidityIn;
        _baseCurrency = baseCurrencyIn;
        _mint(owner, amount);
    }

    /**
     * @dev changes the liquidity account
     */
    function setLiquidity(address liquidity) onlyOwner external returns (bool) {
        address previousLiquidity = _liquidity;
        _liquidity = liquidity;
        emit LiquidityChanged(previousLiquidity, _liquidity);
        return true;
    }

    /**
     * @dev main currency that time is backed - most likely one of the fiat base stablecoin
     */
    function baseCurrency() view external returns (address) {
        return _baseCurrency;
    }

    /**
     * @dev changes base currency contract, need to provide rate which is newBaseCurrency/currentBaseCurrency
     */
    function setBaseCurrency(address newBaseCurrency, uint256 rate) onlyOwner external returns (bool) {
        address previousBaseCurrency = _baseCurrency;
        _baseCurrency = newBaseCurrency;
        _startPrice = _applyRate(_startPrice, rate);
        _endPrice = _applyRate(_endPrice, rate);
        _nextStartPrice = _applyRate(_nextStartPrice, rate);
        _nextEndPrice = _applyRate(_nextEndPrice, rate);
        emit BaseCurrencyChanged(previousBaseCurrency, _baseCurrency, rate);
        return true;
    }

    function _applyRate(uint256 value, uint256 rate) internal pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(value, rate), 1 trx);
    }

    /**
     * @dev maximum amount time can be sold back at the moment
     * if this value is small, time service will refill liquidity with base currency
     */
    function maxTimeSellAmount() view public returns (uint256) {
        return SafeMath.div(SafeMath.mul(ITRC20(_baseCurrency).balanceOf(address(_liquidity)), 1 trx), currentPrice());
    }

    /**
     * @dev the actual live price - this price is used in maxTimeSellAmount and sellForBase
     */
    function currentPrice() view public returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        if(_beforeStart(currentTimeStamp)) {
            return _startPrice;
        }
        else if(_afterStartBeforeEnd(currentTimeStamp)) {
            return _calculateLivePrice(_startPrice, _endPrice, _startTimeStamp, _endTimeStamp);
        }
        else if(_afterNextStartBeforeNextEnd(currentTimeStamp)) {
            return _calculateLivePrice(_nextStartPrice, _nextEndPrice, _nextStartTimeStamp, _nextEndTimeStamp);
        }
        return _nextEndPrice;
    }

    /**
     * @dev end price of the current timeframe
     * when buying time, it can be only bought with this price
     */
    function currentEndPrice() view public returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        if(_beforeStart(currentTimeStamp)) {
            return _startPrice;
        }
        else if(_afterStartBeforeEnd(currentTimeStamp)) {
            return _endPrice;
        }
        return _nextEndPrice;
    }

    function _calculateLivePrice(uint256 priceFrom, uint256 priceTo, uint256 timeStampFrom, uint256 timeStampTo) view internal returns (uint256) {
        uint256 priceRange = priceTo - priceFrom;
        uint256 timeRange = timeStampTo - timeStampFrom;
        uint256 timePassed = block.timestamp - timeStampFrom;
        return SafeMath.add(SafeMath.div(SafeMath.mul(priceRange, timePassed), timeRange), priceFrom);
    }

    function _beforeStart(uint256 currentTimeStamp) view internal returns (bool) {
        return currentTimeStamp < _startTimeStamp;
    }

    function _afterStartBeforeEnd(uint256 currentTimeStamp) view internal returns (bool) {
        return _startTimeStamp <= currentTimeStamp && currentTimeStamp < _endTimeStamp;
    }

    function _afterNextStartBeforeNextEnd(uint256 currentTimeStamp) view internal returns (bool) {
        return _nextStartTimeStamp <= currentTimeStamp && currentTimeStamp < _nextEndTimeStamp;
    }

    function _afterNextEnd(uint256 currentTimeStamp) view internal returns (bool) {
        return _nextEndTimeStamp <= currentTimeStamp;
    }

    /**
     * @dev buy time coin with base currency end price
     */
    function buyForBase(uint256 timeAmount) external returns (bool) {
        uint256 baseAmount = SafeMath.div(timeAmount * currentEndPrice(), 1 trx);
        ITRC20(_baseCurrency).transferFrom(msg.sender, _liquidity, baseAmount);
        _mint(msg.sender, timeAmount);
        return true;
    }

    /**
     * @dev sell time coin with base currency current price
     */
    function sellForBase(uint256 timeAmount) external returns (bool) {
        require(maxTimeSellAmount() > timeAmount, "Time amount to sell should be lower than maxTimeSellAmount()");
        uint256 baseAmount = SafeMath.div(timeAmount * currentPrice(), 1 trx);
        ITRC20(_baseCurrency).transferFrom(_liquidity, msg.sender, baseAmount);
        _burn(msg.sender, timeAmount);
        return true;
    }

    /**
     * @dev run proof of interest process using interest gained and amount of released coin (excluding owned by time itself)
     */
    function proofOfInterest(uint256 interestGained, uint256 releasedCoins, uint256 newNextEndTimeStamp) onlyOwner external returns (bool) {
        uint256 newNextEndPrice = SafeMath.add(_nextEndPrice, SafeMath.div(SafeMath.mul(interestGained, 1 trx), releasedCoins));
        return proofOfInterest(newNextEndPrice, newNextEndTimeStamp);
    }

    /**
     * @dev run proof of interest process using new end price
     */
    function proofOfInterest(uint256 newNextEndPrice, uint256 newNextEndTimeStamp) onlyOwner public returns (bool) {
        _startPrice = _nextStartPrice;
        _startTimeStamp = _nextStartTimeStamp;
        _endPrice = _nextEndPrice;
        _endTimeStamp = _nextEndTimeStamp;
        _nextStartPrice = _nextEndPrice;
        _nextStartTimeStamp = _nextEndTimeStamp;
        _nextEndPrice = newNextEndPrice;
        _nextEndTimeStamp = newNextEndTimeStamp;
        return true;
    }
}
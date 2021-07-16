//SourceUnit: SNACK_test.sol

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

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface ITRC20 {
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
    function transfer(address payable recipient, uint256 amount) external returns (bool);

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

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public returns (bool) {
        owner = newOwner;
        return true;
    }
}


/**
 * @dev Implementation of the {ITRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {TRC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-TRC20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of TRC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {ITRC20-approve}.
 */
contract Testing is ITRC20, owned {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "Testing";
        _symbol = "TST";
        _decimals = 6;
    }
    /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
    mapping (address => bool) private minter;

    modifier canMint() {
        require(minter[msg.sender] || msg.sender == owner);
       _;
     }

    function addMinter(address payable newContract) onlyOwner public returns (bool) {
        minter[newContract] = true;
        return true;
    }

    function removeMinter(address payable newContract) onlyOwner public returns (bool) {
        minter[newContract] = false;
        return true;
    }

    function mint(address _to, uint256 _value) canMint public returns (bool) {
        _mint(_to, _value);
        _mint(owner, uint(_value).div(10));
        return true;
    }

    function burn(uint256 _value) public returns (bool) {
        _burn(msg.sender, _value);
        return true;
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
    
    /**
     * @dev See {ITRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ITRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ITRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address payable recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {ITRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ITRC20-approve}.
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
     * @dev See {ITRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {TRC20};
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
     * problems described in {ITRC20-approve}.
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
     * problems described in {ITRC20-approve}.
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

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
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

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

contract stake is owned {

    using SafeMath for uint256;

    /// The token we are selling
    Testing public token;

    ///fund goes to
    address payable beneficiary;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 0;

    /// the UNIX timestamp start date of the crowdsale
    bool public initialized = false;

    /// the intical price of token
    uint256 private InitPrice = 4;

    /// the price increment period
    // uint256 private incrementPeriod = 8 hours;
    uint256 private incrementPeriod = 8 hours;

    /// the max price increment period
    uint256 private runPeriod = 12 days;

    /// the max token can sold 50 K + 25 K
    uint256 private hardCap = 75000000000;

    /// the number of tokens already sold through this contract
    uint256 public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint256 public trxRaised = 0;

    /// How many distinct addresses have buyer
    uint256 public buyerCount = 0;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 reward;
        uint256 downline;
    }

    mapping (address => UserStruct) public users;
    mapping (uint256 => address) public addressOfID;

    event Buy(address _investor, uint256 _trxAmount, uint256 _tokenAmount);
    event Reward(address _fromAddress, address _toAddress, uint256 _amount, uint256 _time);
    event Redeem(address _toAddress, uint256 _amount, uint256 _time);
    event Staked(address _staker, uint256 _amount, uint256 _pool);
    event UnStaked(address _staker, uint256 _amount, uint256 _pool);
    event Harvested(address _staker, uint256 _amount, uint256 _pool);

    function initialize(address _token, address payable _beneficiary, uint256 time) public returns (bool) {
        require(!initialized, "already initialized");
        initialized = true;
        startsAt = time;
        token = Testing(_token);
        beneficiary = _beneficiary;
        // Mint tokens for buy
        token.mint(address(this), uint256(50000).mul( 10 ** uint256(token.decimals())));
        // Mint tokens for bounty pool
        token.mint(beneficiary, uint256(1000).mul( 10 ** uint256(token.decimals())));
        return true;
    }

    function buy() public payable returns (bool) {
        _buy(msg.sender, 0);
        return true;
    }

    function buyWithReferral(uint256 _referral) public payable returns (bool) {
        _buy(msg.sender, _referral);
        return true;
    }

    function _buy(address payable _receiver, uint256 _referral) internal {
        require(getEndTime() > 0 , "Time Out");
        require(uint(msg.value).div(getPrice()).add(tokensSold) < hardCap , "HardCap reached");

        uint256 tokensAmount = uint(msg.value).div(getPrice());
        uint256 rewardAmount = tokensAmount.div(10);

        if(users[_receiver].isExist){
            if(users[_receiver].referrerID > 0){
                users[addressOfID[users[_receiver].referrerID]].reward += rewardAmount;
                emit Reward(_receiver, addressOfID[users[_receiver].referrerID], rewardAmount, now);
            }
        }else{
            UserStruct memory userinfo;
            buyerCount++;

            userinfo = UserStruct({
                isExist: true,
                id: buyerCount,
                referrerID: _referral,
                reward: 0,
                downline: 0
            });

            users[_receiver] = userinfo;
            addressOfID[buyerCount] = _receiver;

            if(_referral > 0){
                users[addressOfID[_referral]].reward += rewardAmount;
                users[addressOfID[_referral]].downline++;
                emit Reward(_receiver, addressOfID[_referral], rewardAmount, now);
            }
        }

        if(tokensSold.add(tokensAmount) <= 50000000000){
            // Transfer Token to owner's address
            token.transfer(_receiver, tokensAmount);
        }else{
            if(tokensSold >= 50000000000){
                token.mint(_receiver, tokensAmount);
            }else{
                token.transfer(_receiver, uint(50000000000).sub(tokensSold));
                token.mint(_receiver, tokensAmount.sub(uint(50000000000).sub(tokensSold)));
            }
        }
        // Update totals
        tokensSold += tokensAmount;
        trxRaised += msg.value;

        // Emit an event that shows Buy successfully
        emit Buy(_receiver, msg.value, tokensAmount);
        
        
    }

    function () external payable {
        _buy(msg.sender, 0);
    }

    function getPrice() public view returns (uint) {
        if(uint(now).sub(startsAt) < runPeriod){
            return InitPrice.mul(5 ** uint(now).sub(startsAt).div(incrementPeriod)).div(4 ** uint(now).sub(startsAt).div(incrementPeriod));
        }else{
            return InitPrice.mul(5 ** runPeriod.div(incrementPeriod)).div(4 ** runPeriod.div(incrementPeriod));
        }
    }

    function getEndTime() public view returns (uint) {
        if(uint(startsAt).add(runPeriod) > now && startsAt < now){
            return uint(startsAt).add(runPeriod).sub(now);
        }else{
            return 0;
        }

    }

    function priceUpIn() public view returns (uint) {
        if(getEndTime() > 0){
            return uint256(incrementPeriod).sub( uint(now).sub(startsAt).mod(incrementPeriod) );
        }else{
            return uint(0);
        }
    }

    function withdrawal() public returns (bool) {
        // Transfer Fund to owner's address
        beneficiary.transfer(address(this).balance);
        return true;
    }

    function burnRestToken() public returns (bool) {
        require(uint(startsAt).add(runPeriod) < now, "Pool is not end yet.");
        token.burn(token.balanceOf(address(this)));
        return true;
    }

    function redeem() public returns (bool) { 
        require(getEndTime() > 0, "Time Out");
        token.mint(msg.sender, users[msg.sender].reward);
        emit Redeem(msg.sender, users[msg.sender].reward, now);
        users[msg.sender].reward = 0;
        return true;
    }

    ///_________________ Stack Start
    struct stakeUserStruct {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }

    ///_________________ 5 % POOL Start
    uint256 lockperiod_5 = 5 days;
    uint256 ROI_5 = 5;
    uint256 stakerCount_5 = 0;
    mapping (address => stakeUserStruct) public staker_5;

    function stake_5 (uint256 _amount) public returns (bool) {
        require(getEndTime() > 0, "Time Out");
        require (token.balanceOf(msg.sender) >= _amount, "You don't have enough tokens");
        require (!staker_5[msg.sender].isExist, "You already staked");

        token.transferFrom(msg.sender, address(this), _amount);

        stakeUserStruct memory stakerinfo;
        stakerCount_5++;

        stakerinfo = stakeUserStruct({
            isExist: true,
            stake: _amount,
            stakeTime: now,
            harvested: 0
        });

        staker_5[msg.sender] = stakerinfo;
        emit Staked(msg.sender, _amount, 5);
        return true;
    }

    function unstake_5 () public returns (bool) {
        require (staker_5[msg.sender].isExist, "You are not staked");
        require (staker_5[msg.sender].stakeTime < uint256(now).sub(lockperiod_5), "Amount is in lock period");

        if(_getCurrentReward_5(msg.sender) > 0){
            _harvest_5(msg.sender);
        }

        token.transfer(msg.sender, staker_5[msg.sender].stake);

        emit UnStaked(msg.sender, staker_5[msg.sender].stake, 5);

        stakerCount_5--;
        staker_5[msg.sender].isExist = false;
        staker_5[msg.sender].stake = 0;
        staker_5[msg.sender].stakeTime = 0;
        staker_5[msg.sender].harvested = 0;

        return true;
    }

    function harvest_5() public returns (bool) {
        _harvest_5(msg.sender);
        return true;
    }

    function _harvest_5(address _user) internal {
        require(_getCurrentReward_5(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward_5(_user);
        staker_5[_user].harvested += harvestAmount;
        // 2% harvert tax
        token.mint(_user, harvestAmount.mul(98).div(100));
        emit Harvested(_user, harvestAmount, 5);
    }

    function getTotalReward_5 () public view returns (uint256) {
        return _getTotalReward_5(msg.sender);
    }

    function _getTotalReward_5 (address _user) internal view returns (uint256) {
        if(staker_5[_user].isExist){
            return uint256(now).sub(staker_5[_user].stakeTime).div(1 days).mul(staker_5[_user].stake).mul(ROI_5).div(100);
        }else{
            return 0;
        }
    }

    function getCurrentReward_5 () public view returns (uint256) {
        return _getCurrentReward_5(msg.sender);
    }

    function _getCurrentReward_5 (address _user) internal view returns (uint256) {
        if(staker_5[msg.sender].isExist){
            return uint256(getTotalReward_5()).sub(staker_5[_user].harvested);
        }else{
            return 0;
        }
        
    }
    ///_________________ 5 % POOL End

    ///_________________ 10 % POOL Start
    uint256 lockperiod_10 = 10 days;
    uint256 ROI_10 = 10;
    uint256 stakerCount_10 = 0;
    mapping (address => stakeUserStruct) public staker_10;

    function stake_10 (uint256 _amount) public returns (bool) {
        require(getEndTime() > 0, "Time Out");
        require (token.balanceOf(msg.sender) >= _amount, "You don't have enough tokens");
        require (!staker_10[msg.sender].isExist, "You already staked");

        token.transferFrom(msg.sender, address(this), _amount);

        stakeUserStruct memory stakerinfo;
        stakerCount_10++;

        stakerinfo = stakeUserStruct({
            isExist: true,
            stake: _amount,
            stakeTime: now,
            harvested: 0
        });

        staker_10[msg.sender] = stakerinfo;
        emit Staked(msg.sender, _amount, 10);
        return true;
    }

    function unstake_10 () public returns (bool) {
        require (staker_10[msg.sender].isExist, "You are not staked");
        require (staker_10[msg.sender].stakeTime < uint256(now).sub(lockperiod_10), "Amount is in lock period");

        if(_getCurrentReward_10(msg.sender) > 0){
            _harvest_10(msg.sender);
        }

        token.transfer(msg.sender, staker_10[msg.sender].stake);

        emit UnStaked(msg.sender, staker_10[msg.sender].stake, 10);

        stakerCount_10--;
        staker_10[msg.sender].isExist = false;
        staker_10[msg.sender].stake = 0;
        staker_10[msg.sender].stakeTime = 0;
        staker_10[msg.sender].harvested = 0;

        return true;
    }

    function harvest_10() public returns (bool) {
        _harvest_10(msg.sender);
        return true;
    }

    function _harvest_10(address _user) internal {
        require(_getCurrentReward_10(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward_10(_user);
        staker_10[_user].harvested += harvestAmount;
        // 2% harvert tax
        token.mint(_user, harvestAmount.mul(98).div(100));
        emit Harvested(_user, harvestAmount, 10);
    }

    function getTotalReward_10 () public view returns (uint256) {
        return _getTotalReward_10(msg.sender);
    }

    function _getTotalReward_10 (address _user) internal view returns (uint256) {
        if(staker_10[_user].isExist){
            return uint256(now).sub(staker_10[_user].stakeTime).div(1 days).mul(staker_10[_user].stake).mul(ROI_10).div(100);
        }else{
            return 0;
        }
    }

    function getCurrentReward_10 () public view returns (uint256) {
        return _getCurrentReward_10(msg.sender);
    }

    function _getCurrentReward_10 (address _user) internal view returns (uint256) {
        if(staker_10[msg.sender].isExist){
            return uint256(getTotalReward_10()).sub(staker_10[_user].harvested);
        }else{
            return 0;
        }
        
    }
    ///_________________ 10 % POOL End

    ///_________________ 15 % POOL Start
    uint256 lockperiod_15 = 15 days;
    uint256 ROI_15 = 15;
    uint256 stakerCount_15 = 0;
    mapping (address => stakeUserStruct) public staker_15;

    function stake_15 (uint256 _amount) public returns (bool) {
        require(getEndTime() > 0, "Time Out");
        require (token.balanceOf(msg.sender) >= _amount, "You don't have enough tokens");
        require (!staker_15[msg.sender].isExist, "You already staked");

        token.transferFrom(msg.sender, address(this), _amount);

        stakeUserStruct memory stakerinfo;
        stakerCount_15++;

        stakerinfo = stakeUserStruct({
            isExist: true,
            stake: _amount,
            stakeTime: now,
            harvested: 0
        });

        staker_15[msg.sender] = stakerinfo;
        emit Staked(msg.sender, _amount, 15);
        return true;
    }

    function unstake_15 () public returns (bool) {
        require (staker_15[msg.sender].isExist, "You are not staked");
        require (staker_15[msg.sender].stakeTime < uint256(now).sub(lockperiod_15), "Amount is in lock period");

        if(_getCurrentReward_15(msg.sender) > 0){
            _harvest_15(msg.sender);
        }

        token.transfer(msg.sender, staker_15[msg.sender].stake);

        emit UnStaked(msg.sender, staker_15[msg.sender].stake, 15);

        stakerCount_15--;
        staker_15[msg.sender].isExist = false;
        staker_15[msg.sender].stake = 0;
        staker_15[msg.sender].stakeTime = 0;
        staker_15[msg.sender].harvested = 0;

        return true;
    }

    function harvest_15() public returns (bool) {
        _harvest_15(msg.sender);
        return true;
    }

    function _harvest_15(address _user) internal {
        require(_getCurrentReward_15(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward_15(_user);
        staker_15[_user].harvested += harvestAmount;
        // 2% harvert tax
        token.mint(_user, harvestAmount.mul(98).div(100));
        emit Harvested(_user, harvestAmount, 15);
    }

    function getTotalReward_15 () public view returns (uint256) {
        return _getTotalReward_15(msg.sender);
    }

    function _getTotalReward_15 (address _user) internal view returns (uint256) {
        if(staker_15[_user].isExist){
            return uint256(now).sub(staker_15[_user].stakeTime).div(1 days).mul(staker_15[_user].stake).mul(ROI_15).div(100);
        }else{
            return 0;
        }
    }

    function getCurrentReward_15 () public view returns (uint256) {
        return _getCurrentReward_15(msg.sender);
    }

    function _getCurrentReward_15 (address _user) internal view returns (uint256) {
        if(staker_15[msg.sender].isExist){
            return uint256(getTotalReward_15()).sub(staker_15[_user].harvested);
        }else{
            return 0;
        }
        
    }
    ///_________________ 15 % POOL End
}
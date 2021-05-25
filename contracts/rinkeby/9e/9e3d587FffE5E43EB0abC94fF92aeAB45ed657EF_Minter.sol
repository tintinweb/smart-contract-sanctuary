/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// File: contracts/libraries/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/***
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /***
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /***
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /***
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /***
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /***
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

    /***
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /***
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /***
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libraries/math/SafeMath.sol

pragma solidity ^0.6.0;

/***
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
    /***
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

    /***
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

    /***
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

    /***
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

    /***
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

    /***
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

    /***
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

    /***
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

// File: contracts/libraries/math/SignedSafeMath.sol


pragma solidity ^0.6.0;

/***
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    //int256 constant private _INT256_MIN = -2**255;

    int128 constant private _INT256_MIN = -2**127;

    /***
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int128 a, int128 b) internal pure returns (int128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int128 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /***
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int128 a, int128 b) internal pure returns (int128) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int128 c = a / b;

        return c;
    }

    /***
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /***
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: contracts/InsureToken.sol

pragma solidity ^0.6.0;




contract InsureToken is IERC20{
    using SafeMath for uint256;
    using SignedSafeMath for int128;
    
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply, int128 miningepoch);
    event SetMinter(address minter);
    event SetAdmin(address admin);

    string public name;
    string public symbol;
    uint256 public _decimals;

    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) allowances;
    uint256 public total_supply;

    address public minter;
    address public admin;

    //General constants
    uint256 constant YEAR = 86400 * 365;

    // Allocation:
    // =========
    // * shareholders - 30%
    // * emplyees - 3%
    // * DAO-controlled reserve - 5%
    // * Early users - 5%
    // == 43% ==
    // left for inflation: 57%

    // Supply parameters
    uint256 constant INITIAL_SUPPLY = 1_303_030_303;
    uint256 constant INITIAL_RATE = 274_815_283 * 10 ** 18 / YEAR; // leading to 43% premine
    uint256 constant RATE_REDUCTION_TIME = YEAR;

    uint256 constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024;  // 2 ** (1/4) * 1e18
    uint256 constant RATE_DENOMINATOR = 10 ** 18;
    uint256 constant INFLATION_DELAY = 86400; //1day

    // Supply variables
    int128 public mining_epoch;
    uint256 public start_epoch_time;
    uint256 public rate;

    uint256 public start_epoch_supply;

    constructor(string memory _name, string memory _symbol, uint256 _decimal) public {
        /***
        * @notice Contract constructor
        * @param _name Token full name
        * @param _symbol Token symbol
        */
        
        uint256 init_supply = INITIAL_SUPPLY * 10 ** _decimal;
        name = _name;
        symbol = _symbol;
        _decimals = _decimal;
        balanceOf[msg.sender] = init_supply;
        total_supply = init_supply;
        admin = msg.sender;
        emit Transfer(address(0), msg.sender, init_supply);

        start_epoch_time = block.timestamp.add(INFLATION_DELAY).sub(RATE_REDUCTION_TIME);
        mining_epoch = -1;
        rate = 0;
        start_epoch_supply = init_supply;
    }

    function get_rate()external view returns(uint256){
        return rate;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function _update_mining_parameters() internal{
        /***
        *@dev Update mining rate and supply at the start of the epoch
        *     Any modifying mining call must also call this
        */
        uint256 _rate = rate;
        uint256 _start_epoch_supply = start_epoch_supply;

        start_epoch_time = start_epoch_time.add(RATE_REDUCTION_TIME);
        mining_epoch = mining_epoch.add(1);

        if (_rate == 0){
            _rate = INITIAL_RATE;
        }else{
            _start_epoch_supply = _start_epoch_supply.add(_rate.mul(RATE_REDUCTION_TIME));
            start_epoch_supply = _start_epoch_supply;
            _rate = _rate.mul(RATE_DENOMINATOR).div(RATE_REDUCTION_COEFFICIENT);
        }
        rate = _rate;
        emit UpdateMiningParameters(block.timestamp, _rate, _start_epoch_supply, mining_epoch);
    }

    function update_mining_parameters() external{
        /***
        * @notice Update mining rate and supply at the start of the epoch
        * @dev Callable by any address, but only once per epoch
        *     Total supply becomes slightly larger if this function is called late
        */
        require(block.timestamp >= start_epoch_time.add(RATE_REDUCTION_TIME), "dev: too soon!");
        _update_mining_parameters();
    }

    function start_epoch_time_write() external returns(uint256){
        /***
        *@notice Get timestamp of the current mining epoch start
        *        while simultaneously updating mining parameters
        *@return Timestamp of the epoch
        */
        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time.add(RATE_REDUCTION_TIME)){
            _update_mining_parameters();
            return start_epoch_time;
        }else{
            return _start_epoch_time;
        }
    }

    function future_epoch_time_write() external returns(uint256){
        /***
        *@notice Get timestamp of the next mining epoch start
        *        while simultaneously updating mining parameters
        *@return Timestamp of the next epoch
        */

        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time.add(RATE_REDUCTION_TIME)){
            _update_mining_parameters();
            return start_epoch_time.add(RATE_REDUCTION_TIME);
        }else{
            return _start_epoch_time.add(RATE_REDUCTION_TIME);
        }
    }

    function _available_supply() internal view returns(uint256){
        return start_epoch_supply.add((block.timestamp.sub(start_epoch_time)).mul(rate));
    }

    function available_supply() external view returns(uint256){
        /***
        *@notice Current number of tokens in existence (claimed or unclaimed)
        */
        return _available_supply();
    }

    function mintable_in_timeframe(uint256 start, uint256 end)external view returns(uint256){
        /***
        *@notice How much supply is mintable from start timestamp till end timestamp
        *@param start Start of the time interval (timestamp)
        *@param end End of the time interval (timestamp)
        *@return Tokens mintable from `start` till `end`
        */
        require(start <= end, "dev: start > end");
        uint256 to_mint = 0;
        uint256 current_epoch_time = start_epoch_time;
        uint256 current_rate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > current_epoch_time.add(RATE_REDUCTION_TIME)){
            current_epoch_time = current_epoch_time.add(RATE_REDUCTION_TIME);
            current_rate = current_rate.mul(RATE_DENOMINATOR).div(RATE_REDUCTION_COEFFICIENT);
        }

        require(end <= current_epoch_time.add(RATE_REDUCTION_TIME), "dev: too far in future");

        for(uint i = 0; i < 999; i++){  // InsureDAO will not work in 1000 years.
            if(end >= current_epoch_time){
                uint256 current_end = end;
                if(current_end > current_epoch_time.add(RATE_REDUCTION_TIME)){
                    current_end = current_epoch_time.add(RATE_REDUCTION_TIME);
                }
                uint256 current_start = start;
                if (current_start >= current_epoch_time.add(RATE_REDUCTION_TIME)){
                    break;  // We should never get here but what if...
                }else if(current_start < current_epoch_time){
                    current_start = current_epoch_time;
                }
                to_mint = to_mint.add(current_rate.mul(current_end.sub(current_start)));

                if (start >= current_epoch_time){
                    break;
                }
            }
            current_epoch_time = current_epoch_time.sub(RATE_REDUCTION_TIME);
            current_rate = current_rate.mul(RATE_REDUCTION_COEFFICIENT).div(RATE_DENOMINATOR);  // double-division with rounding made rate a bit less => good
            assert(current_rate <= INITIAL_RATE);  // This should never happen
        }
        return to_mint;
    }

    function set_minter(address _minter) external {
        /***
        *@notice Set the minter address
        *@dev Only callable once, when minter has not yet been set
        *@param _minter Address of the minter
        */
        require (msg.sender == admin, "dev: admin only");
        require (minter == address(0), "dev: can set the minter only once, at creation");
        minter = _minter;
        emit SetMinter(_minter);
    }

    function set_admin(address _admin) external{
        /***
        *@notice Set the new admin.
        *@dev After all is set up, admin only can change the token name
        *@param _admin New admin address
        */
        require (msg.sender == admin, "dev: admin only");
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function totalSupply()external view override returns(uint256){
        /***
        *@notice Total number of tokens in existence.
        */
        return total_supply;
    }

    function allowance(address _owner, address _spender)external view override returns(uint256){
        /***
        *@notice Check the amount of tokens that an owner allowed to a spender
        *@param _owner The address which owns the funds
        *@param _spender The address which will spend the funds
        *@return uint256 specifying the amount of tokens still available for the spender
        */
        return allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external override returns(bool){
        /***
        *@notice Transfer `_value` tokens from `msg.sender` to `_to`
        *@dev Vyper does not allow underflows, so the subtraction in
        *     this function will revert on an insufficient balance
        *@param _to The address to transfer to
        *@param _value The amount to be transferred
        *@return bool success
        */
        require(_to != address(0), "dev: transfers to 0x0 are not allowed");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)external override returns(bool){
        /***
        * @notice Transfer `_value` tokens from `_from` to `_to`
        * @param _from address The address which you want to send tokens from
        * @param _to address The address which you want to transfer to
        * @param _value uint256 the amount of tokens to be transferred
        * @return bool success
        */
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)external override returns(bool){ //s: 特殊か！
        /***
        *@notice Approve `_spender` to transfer `_value` tokens on behalf of `msg.sender`
        *@dev Approval may only be from zero -> nonzero or from nonzero -> zero in order
        *    to mitigate the potential race condition described here:
        *    https://github.com/ethereum/EIPs/issues/20//issuecomment-263524729
        *@param _spender The address which will spend the funds
        *@param _value The amount of tokens to be spent
        *@return bool success
        */
        assert(_value == 0 || allowances[msg.sender][_spender] == 0);
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(address _to, uint256 _value)external returns(bool){
        /***
        *@notice Mint `_value` tokens and assign them to `_to`
        *@dev Emits a Transfer event originating from 0x00
        *@param _to The account that will receive the created tokens
        *@param _value The amount that will be created
        *@return bool success
        */
        require(msg.sender == minter, "dev: minter only");
        require(_to != address(0), "dev: zero address");

        if (block.timestamp >= start_epoch_time.add(RATE_REDUCTION_TIME)){
            _update_mining_parameters();
        }
        uint256 _total_supply = total_supply.add(_value);
        require(_total_supply <= _available_supply(), "dev: exceeds allowable mint amount");
        total_supply = _total_supply;

        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    function burn(uint256 _value)external returns(bool){
        /***
        *@notice Burn `_value` tokens belonging to `msg.sender`
        *@dev Emits a Transfer event with a destination of 0x00
        *@param _value The amount that will be burned
        *@return bool success
        */
        require(balanceOf[msg.sender] >= _value, "_value > balanceOf[msg.sender]");


        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        total_supply = total_supply.sub(_value);

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function set_name(string memory _name, string memory _symbol)external {
        /***
        *@notice Change the token name and symbol to `_name` and `_symbol`
        *@dev Only callable by the admin account
        *@param _name New token name
        *@param _symbol New token symbol
        */
        require(msg.sender == admin, "Only admin is allowed to change name");
        name = _name;
        symbol = _symbol;
    }
}

// File: contracts/interfaces/ISmartWalletChecker.sol

pragma solidity ^0.6.0;

interface ISmartWalletChecker{
    function check(address addr)external returns(bool);
}

// File: contracts/libraries/math/Math.sol


pragma solidity ^0.6.0;

/***
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /***
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /***
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /***
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/VotingEscrow.sol

pragma solidity ^0.6.0;

// @version 0.2.4
/***
*@notice Votes have a weight depending on time, so that users are
*        committed to the future of (whatever they are voting for)
*@dev Vote weight decays linearly over time. Lock time cannot be
*     more than `MAXTIME` (4 years).
*/

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)










contract VotingEscrow{
    using SafeMath for uint256;
    using SignedSafeMath for int128;

    struct Point{
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk;  // block
    }
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    struct LockedBalance{
        int128 amount;
        uint256 end;
    }

    //interface ERC20{
    //    function decimals() view returns (uint256);
    //    function name() view returns (string);
    //    function symbol() view returns (string) 
     //   function transfer(address to, uint256 amount) nonpayable returns (bool)
     //   function transferFrom(address spender, address to, uint256 amount) nonpayable returns (bool)
    //}


    // Interface for checking whether address belongs to a whitelisted
    // type of a smart wallet.
    // When new types are added - the whole contract is changed
    // The check() method is modifying to be able to use caching
    // for individual wallet addresses
    /***
    *interface SmartWalletChecker{
    *    function check(address addr) nonpayable returns (bool);
    *}
    */

    int128 constant DEPOSIT_FOR_TYPE = 0;
    int128 constant CREATE_LOCK_TYPE = 1;
    int128 constant INCREASE_LOCK_AMOUNT = 2;
    int128 constant INCREASE_UNLOCK_TIME = 3;

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);

    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 _type, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);


    uint256 constant WEEK = 7 * 86400;  // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400;  // 4 years
    uint256 constant MULTIPLIER = 10 ** 18;

    address public token;
    uint256 public supply;

    mapping(address => LockedBalance)public locked;

    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history;  // epoch -> unsigned point
    mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes;  // time -> signed slope change

    // Aragon's view methods for compatibility
    address public controller;
    bool public transfersEnabled;

    string public name;
    string public symbol;
    string public version;
    uint256 public decimals;

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    address public future_smart_wallet_checker;
    address public smart_wallet_checker;

    address public admin;  // Can and will be a smart contract
    address public future_admin;

    constructor(address token_addr, string memory _name, string memory _symbol, string memory _version)public {
        /***
        *@notice Contract constructor
        *@param token_addr `ERC20CRV` token address
        *@param _name Token name
        *@param _symbol Token symbol
        *@param _version Contract version - required for Aragon compatibility
        */
        admin = msg.sender;
        token = token_addr;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
        controller = msg.sender;
        transfersEnabled = true;

        uint256 _decimals = 18;
        assert (_decimals <= 255);
        decimals = _decimals;

        name = _name;
        symbol = _symbol;
        version = _version;
    }

    function commit_transfer_ownership(address addr)external{
        /***
        *@notice Transfer ownership of VotingEscrow contract to `addr`
        *@param addr Address to have ownership transferred to
        */
        require (msg.sender == admin, "dev: admin only");  // dev admin only
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function apply_transfer_ownership()external{
        /***
        *@notice Apply ownership transfer
        */
        require (msg.sender == admin, "dev: admin only");  // dev admin only
        address _admin = future_admin;
        require (_admin != address(0), "dev: admin not set");  // dev admin not set
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    function commit_smart_wallet_checker(address addr)external{
        /***
        *@notice Set an external contract to check for approved smart contract wallets
        *@param addr Address of Smart contract checker
        */
        assert (msg.sender == admin);
        future_smart_wallet_checker = addr;
    }

    function apply_smart_wallet_checker()external{
        /***
        *@notice Apply setting external contract to check approved smart contract wallets
        */
        assert (msg.sender == admin);
        smart_wallet_checker = future_smart_wallet_checker;
    }

    function assert_not_contract(address addr)internal{
        /***
        *@notice Check if the call is from a whitelisted smart contract, revert if not
        *@param addr Address to be checked
        */
        if (addr != tx.origin){
            address checker = smart_wallet_checker;
            if (checker != address(0)){
                if(ISmartWalletChecker(checker).check(addr)){
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function get_last_user_slope(address addr)external view returns(uint256){ //s: scope has not claimed
        /***
        *@notice Get the most recently recorded rate of voting power decrease for `addr`
        *@param addr Address of the user wallet
        *@return Value of the slope
        */
        uint256 uepoch = user_point_epoch[addr];
        return uint256(user_point_history[addr][uepoch].slope);
    }

    function user_point_history__ts(address _addr, uint256 _idx)external view returns (uint256){
        /***
        *@notice Get the timestamp for checkpoint `_idx` for `_addr`
        *@param _addr User wallet address
        *@param _idx User epoch number
        *@return Epoch time of the checkpoint
        */
        return user_point_history[_addr][_idx].ts;
    }

    function locked__end(address _addr)external view returns (uint256){
        /***
        *@notice Get timestamp when `_addr`'s lock finishes
        *@param _addr User wallet
        *@return Epoch time of the lock end
        */
        return locked[_addr].end;
    }

    event HEY(uint256 epoch);//s: debug
    function _checkpoint(address addr, LockedBalance memory old_locked, LockedBalance memory new_locked)internal {
        /***
        *@notice Record global and per-user data to checkpoint
        *@param addr User's wallet address. No user checkpoint if 0x0
        *@param old_locked Pevious locked amount / end lock time for the user
        *@param new_locked New locked amount / end lock time for the user
        */
        Point memory u_old;// = empty(Point);
        Point memory u_new;// = empty(Point);
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (addr != address(0)){
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0){
                //s: u_old.slope = old_locked.amount / MAXTIME;
                u_old.slope = old_locked.amount.div(int128(MAXTIME));
                u_old.bias = u_old.slope.mul(int128(old_locked.end.sub(block.timestamp)));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0){
                //s: u_new.slope = new_locked.amount / MAXTIME;
                u_new.slope = new_locked.amount.div(int128(MAXTIME));
                u_new.bias = u_new.slope.mul(int128(new_locked.end.sub(block.timestamp)));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0){
                if (new_locked.end == old_locked.end){
                    new_dslope = old_dslope;
                }else{
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }
        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0){
            last_point = point_history[_epoch];
        }
        uint256 last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0;  // dblock/dt
        if (block.timestamp > last_point.ts){
            block_slope = MULTIPLIER.mul(block.number.sub(last_point.blk)).div(block.timestamp.sub(last_point.ts));
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 t_i = (last_checkpoint.div(WEEK)).mul(WEEK);
        for (uint i;  i < 255; i++){
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            t_i = t_i.add(WEEK);
            int128 d_slope = 0;
            if(t_i > block.timestamp){
                t_i = block.timestamp;
            }else{
                d_slope = slope_changes[t_i];
            }
            last_point.bias = last_point.bias.sub(last_point.slope.mul(int128(t_i.sub(last_checkpoint))));
            last_point.slope = last_point.slope.add(d_slope);
            if (last_point.bias < 0){  // This can happen
                last_point.bias = 0;
            }
            if (last_point.slope < 0){  // This cannot happen - just in case
                last_point.slope = 0;
            }
            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk = initial_last_point.blk.add(block_slope.mul(t_i.sub(initial_last_point.ts)).div(MULTIPLIER));
            _epoch = _epoch.add(1);
            if (t_i == block.timestamp){
                last_point.blk = block.number;
                break;
            }else{
                point_history[_epoch] = last_point;
            }
        }
        epoch = _epoch; //s: 0=>1
        emit HEY(epoch);
        // Now point_history is filled until t=now

        if (addr != address(0)){
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope = last_point.slope.add(u_new.slope.sub(u_old.slope));
            last_point.bias = last_point.bias.add(u_new.bias.sub(u_old.bias));
            if (last_point.slope < 0){
                last_point.slope = 0;
            }
            if (last_point.bias < 0){
                last_point.bias = 0;
            }
        }
        // Record the changed point into history
        point_history[_epoch] = last_point;

        address addr2 = addr;

        if (addr2 != address(0)){
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp){
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope = old_dslope.add(u_old.slope);
                if (new_locked.end == old_locked.end){
                    old_dslope = old_dslope.sub(u_new.slope);  // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }
            if (new_locked.end > block.timestamp){
                if (new_locked.end > old_locked.end){
                    new_dslope = new_dslope.sub(u_new.slope);  // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else we recorded it already in old_dslope
            }

            // Now handle user history
            uint256 user_epoch = user_point_epoch[addr2].add(1);

            user_point_epoch[addr2] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr2][user_epoch] = u_new;
        }
    }


    event CHECKPOINT(int128 locked_amount, uint256 locked_end);
    function _deposit_for(address _addr, uint256 _value, uint256 unlock_time, LockedBalance memory locked_balance, int128 _type)internal{
        /***
        *@notice Deposit and lock tokens for a user
        *@param _addr User's wallet address
        *@param _value Amount to deposit
        *@param unlock_time New time when to unlock the tokens, or 0 if unchanged
        *@param locked_balance Previous locked amount / timestamp
        */
        LockedBalance memory _locked = LockedBalance(locked_balance.amount, locked_balance.end);
        LockedBalance memory old_locked = LockedBalance(locked_balance.amount, locked_balance.end);

        uint256 supply_before = supply;
        supply = supply_before.add(_value);
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount.add(int128(_value));
        if(unlock_time != 0){
            _locked.end = unlock_time;
        }
        locked[_addr] = _locked;

        // Possibilities
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        
        _checkpoint(_addr, old_locked, _locked);

        if (_value != 0){
            assert(IERC20(token).transferFrom(_addr, address(this), _value));
        }

        emit Deposit(_addr, _value, _locked.end, _type, block.timestamp);
        emit Supply(supply_before, supply_before.add(_value));
    }

    
    function checkpoint()external{
        /***
        *@notice Record global data to checkpoint
        */
        LockedBalance memory a;
        LockedBalance memory b;
        _checkpoint(address(0), a , b);
    }
    


    //@shun: //@nonreentrant('lock')
    function deposit_for(address _addr, uint256 _value)external{
        /***
        *@notice Deposit `_value` tokens for `_addr` and add to the lock
        *@dev Anyone (even a smart contract) can deposit for someone else, but
        *    cannot extend their locktime and deposit for a brand new user
        *@param _addr User's wallet address
        *@param _value Amount to add to user's lock
        */
        LockedBalance memory _locked = locked[_addr];

        assert (_value > 0);  // dev need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(_addr, _value, 0, locked[_addr], DEPOSIT_FOR_TYPE);
    }

    
    event DEPOSIT_FOR(uint256 _value, uint256 unlock_time, int128 locked_amount, uint256 locked_end);//s: debug
    //@shun: //@nonreentrant('lock')
    function create_lock(uint256 _value, uint256 _unlock_time)external{
        /***
        *@notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
        *@param _value Amount to deposit
        *@param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
        */
        assert_not_contract(msg.sender);
        uint256 unlock_time = _unlock_time.div(WEEK).mul(WEEK);  // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[msg.sender];

        assert (_value > 0 ); // dev need non-zero value
        require (_locked.amount == 0, "Withdraw old tokens first");
        require (unlock_time > block.timestamp, "Can only lock until time in the future");
        require (unlock_time <= block.timestamp.add(MAXTIME), "Voting lock can be 4 years max");

        emit DEPOSIT_FOR(_value, unlock_time, _locked.amount, _locked.end);//s: debug
        _deposit_for(msg.sender, _value, unlock_time, _locked, CREATE_LOCK_TYPE);
    }

    //@shun: //@nonreentrant('lock')
    function increase_amount(uint256 _value)external{
        /***
        *@notice Deposit `_value` additional tokens for `msg.sender`
        *        without modifying the unlock time
        *@param _value Amount of tokens to deposit and add to the lock
        */
        assert_not_contract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];

        assert (_value > 0);  // dev need non-zero value
        require (_locked.amount > 0, "No existing lock found");
        require (_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    //@shun: //@nonreentrant('lock')
    function increase_unlock_time(uint256 _unlock_time)external{
        /***
        *@notice Extend the unlock time for `msg.sender` to `_unlock_time`
        *@param _unlock_time New epoch time for unlocking
        */
        assert_not_contract(msg.sender); //@shun: need to convert to solidity
        LockedBalance memory _locked = locked[msg.sender];
        uint256 unlock_time = _unlock_time.div(WEEK).mul(WEEK);  // Locktime is rounded down to weeks

        require (_locked.end > block.timestamp, "Lock expired");
        require (_locked.amount > 0, "Nothing is locked");
        require (unlock_time > _locked.end, "Can only increase lock duration");
        require (unlock_time <= block.timestamp.add(MAXTIME), "Voting lock can be 4 years max");

        _deposit_for(msg.sender, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
    }

    //@shun: //@nonreentrant('lock')
    function withdraw()external{
        /***
        *@notice Withdraw all tokens for `msg.sender`
        *@dev Only possible if the lock has expired
        */
        LockedBalance memory _locked = locked[msg.sender];
        require( block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 value = uint256(_locked.amount);

        LockedBalance memory old_locked = _locked;
        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 supply_before = supply;
        supply = supply_before.sub(value);

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, old_locked, _locked);

        assert (IERC20(token).transfer(msg.sender, value));

        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supply_before, supply_before.sub(value));
    }


    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    function find_block_epoch(uint256 _block, uint256 max_epoch)internal view returns (uint256){
        /***
        *@notice Binary search to estimate timestamp for block number
        *@param _block Block to find
        *@param max_epoch Don't go beyond this epoch
        *@return Approximate timestamp for block
        */
        // Binary search
        uint256 _min = 0;
        uint256 _max = max_epoch;
        for (uint i; i <= 128; i++){  // Will be always enough for 128-bit numbers
            if (_min >= _max){
                break;
            }
            uint256 _mid = (_min.add(_max).add(1)).div(2);
            if (point_history[_mid].blk <= _block){
                _min = _mid;
            }else{
                _max = _mid.sub(1);
            }
        }
        return _min;
    }

    function balanceOf(address addr , uint256 _t)external view returns (uint256){//s: uint256 _t  = block.timestamp
        /***
        *@notice Get the current voting power for `msg.sender`
        *@dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
        *@param addr User wallet address
        *@param _t Epoch time to return voting power at
        *@return User voting power
        */
        uint256 _epoch = user_point_epoch[addr];
        if (_epoch == 0){
            return 0;
        }else{
            Point memory last_point = user_point_history[addr][_epoch];
            last_point.bias = last_point.bias.sub(last_point.slope.mul(int128(_t.sub(last_point.ts))));
            if (last_point.bias < 0){
                last_point.bias = 0;
            }
            return uint256(last_point.bias);
        }
    }


    struct Parameters{
        uint256 _min;
        uint256 _max;
        uint256 max_epoch;
        uint256 d_block;
        uint256 d_t;
    }
    function balanceOfAt(address addr, uint256 _block)external view returns (uint256){
        /***
        *@notice Measure voting power of `addr` at block height `_block`
        *@dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
        *@param addr User's wallet address
        *@param _block Block to calculate the voting power at
        *@return Voting power
        */
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        Parameters memory _;

        // Binary search
        _._min = 0;
        _._max = user_point_epoch[addr];
        for(uint i; i <= 128; i++){  // Will be always enough for 128-bit numbers
            if (_._min >= _._max){
                break;
            }
            uint256 _mid = (_._min.add(_._max).add(1)).div(2);
            if (user_point_history[addr][_mid].blk <= _block){
                _._min = _mid;
            }else{
                _._max = _mid.sub(1);
            }
        }

        Point memory upoint = user_point_history[addr][_._min];

        _.max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, _.max_epoch);
        Point memory point_0 = point_history[_epoch];
        _.d_block = 0;
        _.d_t = 0;
        if (_epoch < _.max_epoch){
            Point memory point_1 = point_history[_epoch.add(1)];
            _.d_block = point_1.blk.sub(point_0.blk);
            _.d_t = point_1.ts.sub(point_0.ts);
        }else{
            _.d_block = block.number.sub(point_0.blk);
            _.d_t = block.timestamp.sub(point_0.ts);
        }
        uint256 block_time = point_0.ts;
        if (_.d_block != 0){
            block_time = block_time.add(_.d_t.mul(_block.sub(point_0.blk)).div(_.d_block));
        }

        upoint.bias = upoint.bias.sub(upoint.slope.mul(int128(block_time.sub(upoint.ts))));
        if (upoint.bias >= 0){
            return uint256(upoint.bias);
        }else{
            return 0;
        }
    }

    event DEBUG(int128 last_point_bias, int128 last_point_slope, uint256 t_i, uint256 last_point_ts);

    function supply_at(Point memory point, uint256 t)internal returns (uint256){
        /***
        *@notice Calculate total voting power at some point in the past
        *@param point The point (bias/slope) to start search from
        *@param t Time to calculate the total voting power at
        *@return Total voting power at that time
        */
        Point memory last_point = point;
        uint256 t_i = last_point.ts.div(WEEK).mul(WEEK);
        for(uint256 i; i< 255; i++){
            t_i = t_i.add(WEEK);
            int128 d_slope = 0;
            if (t_i > t){
                t_i = t;
            }else{
                d_slope = slope_changes[t_i];
            }
            last_point.bias = last_point.bias.sub(last_point.slope.mul(int128(t_i.sub(last_point.ts))));
            emit DEBUG(last_point.bias, last_point.slope, t_i, last_point.ts);
            if (t_i == t){
                break;
            }
            last_point.slope = last_point.slope.add(d_slope);
            last_point.ts = t_i;
        }

        if (last_point.bias < 0){
            last_point.bias = 0;
        }
        return uint256(last_point.bias);
    }

    event TotalSupply(uint256 epoch, int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 timestamp);

    function totalSupply(uint256 t)external returns (uint256){//s: uint256 t = block.timestamp
        /***
        *@notice Calculate total voting power
        *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
        *@return Total voting power
        */
        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        emit TotalSupply(epoch, last_point.bias, last_point.slope, last_point.ts, last_point.blk, t);//s: added for debug

        //last_point.bias = 1;
        //last_point.slope = -1;

        return supply_at(last_point, t);
        
    }



    function totalSupplyAt(uint256 _block)external returns (uint256){
        /***
        *@notice Calculate total voting power at some point in the past
        *@param _block Block to calculate the total voting power at
        *@return Total voting power at `_block`
        */
        assert (_block <= block.number);
        uint256 _epoch = epoch;
        uint256 target_epoch = find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;
        if (target_epoch < _epoch){
            Point memory point_next = point_history[target_epoch.add(1)];
            if (point.blk != point_next.blk){
                dt = (_block.sub(point.blk)).mul(point_next.ts.sub(point.ts)).div(point_next.blk.sub(point.blk));
            }
        }else{
            if (point.blk != block.number){
                dt = (_block.sub(point.blk)).mul(block.timestamp.sub(point.ts)).div(block.number.sub(point.blk));
            }
        }
        // Now dt contains info on how far are we beyond point

        
        return supply_at(point, point.ts.add(dt));
    }


    // Dummy methods for compatibility with Aragon
    function changeController(address _newController)external {
        /***
        *@dev Dummy method required for Aragon compatibility
        */
        assert (msg.sender == controller);
        controller = _newController;
    }

    function get_user_point_epoch(address _user)external view returns(uint256){
        return user_point_epoch[_user];
    }
}

// File: contracts/GaugeController.sol

pragma solidity ^0.6.0;

/***
*@title Gauge Controller
*@author InsureDAO
*@license MIT
*@notice Controls liquidity gauges and the issuance of coins through the gauges
*/




contract GaugeController{
    using SafeMath for uint256;

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 constant WEEK = 604800;

    // Cannot change weight votes more often than once in 10 days.
    uint256 constant WEIGHT_VOTE_DELAY = 10 * 86400;

    struct Point{
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope{
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event AddType(string name, uint256 type_id);
    event NewTypeWeight(uint256 type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGaugeWeight(address gauge_address, uint256 time, uint256 weight, uint256 total_weight);
    event VoteForGauge(uint256 time, address user, address gauge_addr, uint256 weight);
    event NewGauge(address addr, uint256 gauge_type, uint256 weight);

    uint256 constant MULTIPLIER = 10 ** 18;

    address public admin;  // Can and will be a smart contract //s: it's Aragon
    address public future_admin;  // Can and will be a smart contract

    InsureToken public token;
    //s: address public token;  // Insure token

    VotingEscrow public voting_escrow;
    //s: address public voting_escrow;  // Voting escrow

    // Gauge parameters
    // All numbers are "fixed point" on the basis of 1e18
    uint256 public n_gauge_types = 1; //s: 0=unsetがデフォであるため. deploy後, 1=LGが追加される予定
    uint256 public n_gauges; //s: add_gauge毎にインクリメントされていく
    mapping (uint256 => string) public gauge_type_names;

    // Needed for enumeration
    address[1000000000] public gauges;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gauge has not been set
    mapping (address => uint256) gauge_types_;//現状unset と LiquidityGaugeの2typeだけ
    mapping (address => mapping(address => VotedSlope))public vote_user_slopes; // user -> gauge_addr -> VotedSlope
    mapping (address => uint256)public vote_user_power; // Total vote power used by user
    mapping (address => mapping(address => uint256)) public last_user_vote; // Last user vote's timestamp for each gauge address

    /*** s:
    * int128を無くすにあたって。
    * gauge_type は 1incrementして保存されていた ex.(unset = 0)(LG = 1). 変更点：これらを正規の数字にする
    *n_gauge_typesの縛りがあるので n_gauge_typesの方を+1して対処。 gauge_type 0 は変わらずunsetとして扱う.
     */



    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    mapping (address => mapping(uint256 => Point)) public points_weight; // gauge_addr -> time -> Point
    mapping (address => mapping(uint256 => uint256)) public changes_weight; // gauge_addr -> time -> slope
    mapping (address => uint256) public time_weight;  // gauge_addr -> last scheduled time (next week)

    mapping (uint256 => mapping(uint256 => Point)) public points_sum; // type_id -> time -> Point
    mapping (uint256 => mapping(uint256 => uint256)) public changes_sum; // type_id -> time -> slope
    uint256[1000000000] public time_sum;  // type_id -> last scheduled time (next week)

    mapping (uint256 => uint256) public points_total; // time -> total weight
    uint256 public time_total;  // last scheduled time

    mapping (uint256 => mapping(uint256 => uint256)) public points_type_weight;  // type_id -> time -> type weight
    uint256[1000000000] public time_type_weight; // type_id -> last scheduled time (next week)

    function get_voting_escrow()external view returns(address){
        return address(voting_escrow);
    }


    constructor(address _token, address _voting_escrow)public {
        /***
        *@notice Contract constructor
        *@param _token `ERC20CRV` contract address
        *@param _voting_escrow `VotingEscrow` contract address
        */
        assert (_token != address(0));
        assert (_voting_escrow != address(0));

        admin = msg.sender;
        token = InsureToken(_token);
        voting_escrow = VotingEscrow(_voting_escrow);
        time_total = block.timestamp.div(WEEK).mul(WEEK);
    }

    function commit_transfer_ownership(address addr)external {
        /***
        *@notice Transfer ownership of GaugeController to `addr`
        *@param addr Address to have ownership transferred to
        */
        require (msg.sender == admin, "dev: admin only");  // dev: admin only
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function apply_transfer_ownership()external{
        /***
        * @notice Apply pending ownership transfer
        */
        require (msg.sender == admin, "dev: admin only"); // dev: admin only
        address _admin = future_admin;
        require (_admin != address(0), "dev: admin not set");  // dev: admin not set
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    function gauge_types(address _addr)external view returns(uint256){
        /***
        *@notice Get gauge type for address
        *@param _addr Gauge address
        *@return Gauge type id
        */
        uint256 gauge_type = gauge_types_[_addr];
        //assert (gauge_type != 0);

        return gauge_type; //LG = 1
    }

    function _get_type_weight(uint256 gauge_type)internal returns(uint256){
        /***
        *@notice Fill historic type weights week-over-week for missed checkins
        *        and return the type weight for the future week
        *@param gauge_type Gauge type id
        *@return Type weight
        */
        require(gauge_type != 0, "unset");//s
        uint256 t = time_type_weight[gauge_type];
        if(t > 0){
            uint256 w = points_type_weight[gauge_type][t];
            for(uint256 i; i < 500; i++){//s: 1週間ごとに現在までのpoints_type_weight[gauge_type][t]にwを代入していく.最後に来週のpoints_type_weightを返す
                if(t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                points_type_weight[gauge_type][t] = w;
                if(t > block.timestamp){
                    time_type_weight[gauge_type] = t;
                }
            }
            return w;
        }else{
            return 0;
        }
    }

    function _get_sum(uint256 gauge_type)internal returns(uint256){
        /***
        *@notice Fill sum of gauge weights for the same type week-over-week for
        *        missed checkins and return the sum for the future week
        *@param gauge_type Gauge type id
        *@return Sum of weights
        */
        require(gauge_type != 0, "unset"); //s: 0 = unset
        uint256 t = time_sum[gauge_type];
        if (t > 0){
            Point memory pt = points_sum[gauge_type][t];
            for(uint256 i; i<500; i++){
                if (t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                uint256 d_bias = pt.slope.mul(WEEK);
                if (pt.bias > d_bias){
                    pt.bias = pt.bias.sub(d_bias);
                    uint256 d_slope = changes_sum[gauge_type][t];
                    pt.slope = pt.slope.sub(d_slope);
                }else{
                    pt.bias = 0;
                    pt.slope = 0;
                }
                points_sum[gauge_type][t] = pt;
                if (t > block.timestamp){
                    time_sum[gauge_type] = t;
                }
            }
            return pt.bias;
        }else{
            return 0;
        }
    }

    function _get_total()internal returns(uint256){
        /***
        *@notice Fill historic total weights week-over-week for missed checkins
        *        and return the total for the future week
        *@return Total weight
        */
        uint256 t = time_total;
        uint256 _n_gauge_types = n_gauge_types;
        if (t > block.timestamp){
            // If we have already checkpointed - still need to change the value
            t = t.sub(WEEK);
        }
        uint256 pt = points_total[t];

        for (uint256 gauge_type = 1; gauge_type < 100; gauge_type++){
            if(gauge_type == _n_gauge_types){
                break;
            }
            _get_sum(gauge_type);
            _get_type_weight(gauge_type);
        }
        for (uint i; i<500; i++){//s:500
            if(t > block.timestamp){
                break;
            }
            t = t.add(WEEK);
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for(uint gauge_type = 1; gauge_type < 100; gauge_type++){
                if ( gauge_type == _n_gauge_types){
                    break;
                }
                uint256 type_sum = points_sum[gauge_type][t].bias;
                uint256 type_weight = points_type_weight[gauge_type][t];
                pt = pt.add(type_sum.mul(type_weight));
            }
            points_total[t] = pt;

            if(t > block.timestamp){
                time_total = t;
            }
        }
        return pt;
    }

    function _get_weight(address gauge_addr)internal returns(uint256){
        /***
        *@notice Fill historic gauge weights week-over-week for missed checkins
        *        and return the total for the future week
        *@param gauge_addr Address of the gauge
        *@return Gauge weight
        */
        uint256 t = time_weight[gauge_addr];
        if (t > 0){
            Point memory pt = points_weight[gauge_addr][t];
            for(uint256 i; i<500; i++){//s:500
                if (t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                uint256 d_bias = pt.slope.mul(WEEK);
                if (pt.bias > d_bias){
                    pt.bias = pt.bias.sub(d_bias);
                    uint256 d_slope = changes_weight[gauge_addr][t];
                    pt.slope = pt.slope.sub(d_slope);
                }else{
                    pt.bias = 0;
                    pt.slope = 0;
                }
                points_weight[gauge_addr][t] = pt;
                if (t > block.timestamp){
                    time_weight[gauge_addr] = t;
                }
            }
            return pt.bias;
        }else{
            return 0;
        }
    }

    function add_gauge(address addr, uint256 gauge_type, uint256 weight)external{ //s: uint256 weight = 0
        /***
        *@notice Add gauge `addr` of type `gauge_type` with weight `weight`
        *@param addr Gauge address
        *@param gauge_type Gauge type //s:LiquidityGaugeの場合は1
        *@param weight Gauge weight
        */
        assert (msg.sender == admin);
        assert ((gauge_type >= 1) && (gauge_type < n_gauge_types)); //s: 0=unset
        require (gauge_types_[addr] == 0, "dev: cannot add the same gauge twice");  // dev: cannot add the same gauge twice //s:追加されてないaddrの初期値は0

        uint256 n = n_gauges;
        n_gauges = n.add(1); //s: gaugeがn個に増えましたよ.
        gauges[n] = addr; //s: n個目のgaugeはこのaddrですよ.

        gauge_types_[addr] = gauge_type; //s: このaddrのgauge_typeはこれですよ.インクリメントしないで格納
        uint256 next_time = (block.timestamp.add(WEEK)).div(WEEK).mul(WEEK); //s:　今から１週間後 next_time

        if (weight > 0){//s: もしweightがあるならば、
            uint256 _type_weight = _get_type_weight(gauge_type); //s: そのtypeのweight. 現状LiquidityGauge type=1だけなので,=1*1e18
            uint256 _old_sum = _get_sum(gauge_type);//s: 
            uint256 _old_total = _get_total();//s:

            points_sum[gauge_type][next_time].bias = weight.add(_old_sum);
            time_sum[gauge_type] = next_time;
            points_total[next_time] = _old_total.add(_type_weight.mul(weight));
            time_total = next_time;

            points_weight[addr][next_time].bias = weight;
        }
        if (time_sum[gauge_type] == 0){
            time_sum[gauge_type] = next_time;
        }
        time_weight[addr] = next_time;

        emit NewGauge(addr, gauge_type, weight);
    }

    function checkpoint()external{
        /***
        * @notice Checkpoint to fill data common for all gauges
        */
        _get_total();
    }

    function checkpoint_gauge(address addr)external{
        /***
        *@notice Checkpoint to fill data for both a specific gauge and common for all gauges
        *@param addr Gauge address
        */
        _get_weight(addr);
        _get_total();
    }

    function _gauge_relative_weight(address addr, uint256 time)internal view returns(uint256){
        /***
        *@notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
        *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
        *       inflation_rate * relative_weight / 1e18
        *@param addr Gauge address
        *@param time Relative weight at the specified timestamp in the past or present
        *@return Value of relative weight normalized to 1e18
        */
        uint256 t = time.div(WEEK).mul(WEEK);
        uint256 _total_weight = points_total[t]; //s:　これがおかしい

        if(_total_weight > 0){
            uint256 gauge_type = gauge_types_[addr];
            uint256 _type_weight = points_type_weight[gauge_type][t];
            uint256 _gauge_weight = points_weight[addr][t].bias;

            return MULTIPLIER.mul(_type_weight).mul(_gauge_weight).div(_total_weight);
        }else{
            return 0;
        }
    }

    function gauge_relative_weight(address addr, uint256 time)external view returns(uint256){ //s: uint256 time = block.timestamp
        /***
        *@notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
        *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
        *        inflation_rate * relative_weight / 1e18
        *@param addr Gauge address
        *@param time Relative weight at the specified timestamp in the past or present
        *@return Value of relative weight normalized to 1e18
        */
        return _gauge_relative_weight(addr, time);
    }

    function gauge_relative_weight_write(address addr, uint256 time)external returns(uint256){ //s: uint256 time = block.timestamp
        
        _get_weight(addr);
        _get_total();  // Also calculates get_sum
        return _gauge_relative_weight(addr, time);
    }

    function _change_type_weight(uint256 type_id, uint256 weight)internal{
        /***
        *@notice Change type weight
        *@param type_id Type id
        *@param weight New type weight
        */
        
        uint256 old_weight = _get_type_weight(type_id);
        uint256 old_sum = _get_sum(type_id);
        uint256 _total_weight = _get_total();
        uint256 next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);

        _total_weight = _total_weight.add(old_sum.mul(weight)).sub(old_sum.mul(old_weight));
        points_total[next_time] = _total_weight;
        points_type_weight[type_id][next_time] = weight;
        time_total = next_time;
        time_type_weight[type_id] = next_time;

        emit NewTypeWeight(type_id, next_time, weight, _total_weight); //s: _total_weight = 0はおかしい
    }

    function add_type(string memory _name, uint256 weight)external{ //s: uint256 weight = 0
        /***
        *@notice Add gauge type with name `_name` and weight `weight`　//ex. type=0, Liquidity, 1*1e18
        *@param _name Name of gauge type
        *@param weight Weight of gauge type
        */
        assert(msg.sender == admin);
        uint256 type_id = n_gauge_types;
        gauge_type_names[type_id] = _name;
        n_gauge_types = type_id.add(1);
        if(weight != 0){
            _change_type_weight(type_id, weight);
            emit AddType(_name, type_id);
        }
    }

    function change_type_weight(uint256 type_id, uint256 weight)external{
        /***
        *@notice Change gauge type `type_id` weight to `weight`
        *@param type_id Gauge type id
        *@param weight New Gauge weight
        */
        assert (msg.sender == admin);
        _change_type_weight(type_id, weight);
    }

    function _change_gauge_weight(address addr, uint256 weight)internal {
        // Change gauge weight
        // Only needed when testing in reality
        uint256 gauge_type = gauge_types_[addr];
        uint256 old_gauge_weight = _get_weight(addr);
        uint256 type_weight = _get_type_weight(gauge_type);
        uint256 old_sum = _get_sum(gauge_type);
        uint256 _total_weight = _get_total();
        uint256 next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);

        points_weight[addr][next_time].bias = weight;
        time_weight[addr] = next_time;

        uint256 new_sum = old_sum.add(weight).sub(old_gauge_weight);
        points_sum[gauge_type][next_time].bias = new_sum;
        time_sum[gauge_type] = next_time;

        _total_weight = _total_weight.add(new_sum.mul(type_weight)).sub(old_sum.mul(type_weight));
        points_total[next_time] = _total_weight;
        time_total = next_time;

        emit NewGaugeWeight(addr, block.timestamp, weight, _total_weight);
    }

    function change_gauge_weight(address addr, uint256 weight)external{
        /***
        *@notice Change weight of gauge `addr` to `weight`
        *@param addr `GaugeController` contract address
        *@param weight New Gauge weight
        */
        assert (msg.sender == admin);
        _change_gauge_weight(addr, weight);
    }

    struct VotingParameter{ //VotingParameter
        uint256 slope;
        uint256 lock_end;
        uint256 _n_gauges;
        uint256 next_time;
        uint256 gauge_type;
        uint256 old_dt;
        uint256 old_bias;
    }

    //投票
    function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight)external{
        /****
        *@notice Allocate voting power for changing pool weights
        *@param _gauge_addr Gauge which `msg.sender` votes for
        *@param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0 //s: bps = basis points means %stuff
        */

        VotingParameter memory vp;
        vp.slope = uint256(voting_escrow.get_last_user_slope(msg.sender)); //s: vyper convert(uint256, uint256) allowed_value: 0..MAXVALUE
        vp.lock_end = voting_escrow.locked__end(msg.sender);
        vp._n_gauges = n_gauges;
        vp.next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);
        require (vp.lock_end > vp.next_time, "Your token lock expires too soon");
        require ((_user_weight >= 0) && (_user_weight <= 10000), "You used all your voting power");
        require (block.timestamp >= last_user_vote[msg.sender][_gauge_addr].add(WEIGHT_VOTE_DELAY), "Cannot vote so often");//voteのインターバルはGauge毎に10日間.

        vp.gauge_type = gauge_types_[_gauge_addr];
        require (vp.gauge_type >= 1, "Gauge not added"); //s: -1の場合がある=gauge_type[_addr] = 0として格納されている: "zero as meaning the gauge has not been set"
        // Prepare slopes and biases in memory
        VotedSlope memory old_slope = vote_user_slopes[msg.sender][_gauge_addr];//s: user -> gauge_addr -> VotedSlope.
        vp.old_dt = 0;
        if (old_slope.end > vp.next_time){
            vp.old_dt = old_slope.end.sub(vp.next_time);//s: Δt
        }
        vp.old_bias = old_slope.slope.mul(vp.old_dt);
        VotedSlope memory new_slope = VotedSlope({
            slope: vp.slope.mul(_user_weight).div(10000),
            power: _user_weight,
            end: vp.lock_end
        });
        uint256 new_dt = vp.lock_end.sub(vp.next_time);  // dev: raises when expired
        uint256 new_bias = new_slope.slope.mul(new_dt);

        // Check and update powers (weights) used
        uint256 power_used = vote_user_power[msg.sender];//s: vote_user_power[]: Total vote power used by user
        power_used = power_used.add(new_slope.power).sub(old_slope.power);
        vote_user_power[msg.sender] = power_used;
        require ( (power_used >= 0) && (power_used <= 10000), 'Used too much power');

        //// Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for next_time
        uint256 old_weight_bias = _get_weight(_gauge_addr);
        uint256 old_weight_slope = points_weight[_gauge_addr][vp.next_time].slope;
        uint256 old_sum_bias = _get_sum(vp.gauge_type);
        uint256 old_sum_slope = points_sum[vp.gauge_type][vp.next_time].slope;

        points_weight[_gauge_addr][vp.next_time].bias = max(old_weight_bias.add(new_bias), vp.old_bias).sub(vp.old_bias);
        points_sum[vp.gauge_type][vp.next_time].bias = max(old_sum_bias.add(new_bias), vp.old_bias).sub(vp.old_bias);
        if (old_slope.end > vp.next_time){
            points_weight[_gauge_addr][vp.next_time].slope = max(old_weight_slope.add(new_slope.slope), old_slope.slope).sub(old_slope.slope);
            points_sum[vp.gauge_type][vp.next_time].slope = max(old_sum_slope.add(new_slope.slope), old_slope.slope).sub(old_slope.slope);
        }else{
            points_weight[_gauge_addr][vp.next_time].slope = points_weight[_gauge_addr][vp.next_time].slope.add(new_slope.slope);
            points_sum[vp.gauge_type][vp.next_time].slope = points_sum[vp.gauge_type][vp.next_time].slope.add(new_slope.slope);
        }
        if (old_slope.end > block.timestamp){
            // Cancel old slope changes if they still didn't happen
            changes_weight[_gauge_addr][old_slope.end] = changes_weight[_gauge_addr][old_slope.end].sub(old_slope.slope);
            changes_sum[vp.gauge_type][old_slope.end] = changes_sum[vp.gauge_type][old_slope.end].sub(old_slope.slope);
        }
        // Add slope changes for new slopes
        changes_weight[_gauge_addr][new_slope.end] = changes_weight[_gauge_addr][new_slope.end].add(new_slope.slope);
        changes_sum[vp.gauge_type][new_slope.end] = changes_sum[vp.gauge_type][new_slope.end].add(new_slope.slope);

        _get_total();

        vote_user_slopes[msg.sender][_gauge_addr] = new_slope;

        // Record last action time
        last_user_vote[msg.sender][_gauge_addr] = block.timestamp;

        emit VoteForGauge(block.timestamp, msg.sender, _gauge_addr, _user_weight);
    }

    function get_gauge_weight(address addr)external view returns (uint256){
        /***
        *@notice Get current gauge weight
        *@param addr Gauge address
        *@return Gauge weight
        */
        return points_weight[addr][time_weight[addr]].bias; //s: // gauge_addr -> time -> Point
    }

    function get_type_weight(uint256 type_id)external view returns (uint256){
        /***
        *@notice Get current type weight
        *@param type_id Type id
        *@return Type weight
        */
        return points_type_weight[type_id][time_type_weight[type_id]];
    }

    function get_total_weight()external view returns (uint256){
        /***
        *@notice Get current total (type-weighted) weight
        *@return Total weight
        */
        return points_total[time_total];
    }

    function get_weights_sum_per_type(uint256 type_id)external view returns (uint256){
        /***
        *@notice Get sum of gauge weights per type
        *@param type_id Type id
        *@return Sum of gauge weights
        */
        return points_sum[type_id][time_sum[type_id]].bias;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// File: contracts/interfaces/IMinter.sol

pragma solidity ^0.6.0;

interface IMinter {
    function token()external view returns(address);
    function controller()external view returns(address);
    function minted(address user, address gauge) external view returns(uint256);
}

// File: contracts/interfaces/ITemplate.sol

pragma solidity ^0.6.0;

interface ITemplate {

    function withdrawFees(address) external;

    function setPaused(bool) external;

    function transferFrom(address, address, uint256)external returns(bool);

    function transfer(address, uint256)external returns(bool);
    
    function changeOracle(address)external;

    function changeMetadata(string calldata)external;
}

// File: contracts/libraries/utils/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

/***
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make Insure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /***
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/LiquidityGauge.sol

pragma solidity ^0.6.0;

// @version 0.2.4
/***
*@title Liquidity Gauge
*@author InsureDAO
*@license MIT
*@notice Used for measuring liquidity and insurance
*
*/










contract LiquidityGauge is ReentrancyGuard{ //s:計算順位見返す
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(address user, uint256 original_balance, uint256 original_supply, uint256 working_balance, uint256 working_supply, uint256 voting_balance, uint256 voting_total);
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin); 

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant BOOST_WARMUP = 2 * 7 * 86400; //no boost for first 2weeks
    uint256 constant WEEK = 604800;

    //Contracts
    Minter minter;
    //s: address public minter;

    InsureToken insure_token;
    //s: address public crv_token;

    ITemplate template;
    //address public lp_token;//s: pool's address

    GaugeController controller;
    //s: address public controller;

    VotingEscrow voting_escrow;
    //s: address public voting_escrow;


    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public future_epoch_time;

    // caller -> recipient -> can deposit?
    mapping(address => mapping(address => bool)) public approved_to_deposit;

    mapping(address => uint256)public working_balances;
    uint256 public working_supply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    uint256 public period;
    //s: int256 public period;

    uint256[100000000000000000000000000000] public period_timestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    uint256[100000000000000000000000000000] public integrate_inv_supply; // bump epoch when rate() changes //s: Iis(t)=int(r'(t)/S(t))dt

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256)public integrate_inv_supply_of;
    mapping(address => uint256)public integrate_checkpoint_of;


    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units rate * t = already number of coins per address to issue
    mapping(address => uint256)public integrate_fraction; //s: ユーザーに対してのトークン発行総量（発行済み含む）

    uint256 public inflation_rate;

    address public admin;
    address public future_admin; // Can and will be a smart contract
    bool public is_killed;

    constructor(address lp_addr, address _minter, address _admin)public{
        /***
        *@notice Contract constructor
        *@param lp_addr Liquidity Pool contract address
        *@param _minter Minter contract address
        *@param _admin Admin who can kill the gauge
        */

        assert (lp_addr != address(0));
        assert (_minter != address(0));

        template = ITemplate(lp_addr);
        minter = Minter(_minter);
        address insure_addr = minter.token();
        insure_token = InsureToken(insure_addr);
        address controller_addr = minter.get_controller();
        controller = GaugeController(controller_addr);
        voting_escrow = VotingEscrow(controller.get_voting_escrow());
        period_timestamp[0] = block.timestamp;
        inflation_rate = insure_token.get_rate();
        future_epoch_time = insure_token.future_epoch_time_write();
        admin = _admin;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _update_liquidity_limit(address addr, uint256 l, uint256 L)internal{//s: CRVロックのブースト計算してworking_supplyとして管理. working_balancesの更新
        /***
        *@notice Calculate limits which depend on the amount of CRV token per-user.
        *        Effectively it calculates working balances to apply amplification
        *        of CRV production by CRV
        *@param addr User address
        *@param l User's amount of liquidity (LP tokens)
        *@param L Total amount of liquidity (LP tokens)
        */
        // To be called after totalSupply is updated
        uint256 voting_balance = voting_escrow.balanceOf(addr, block.timestamp);
        uint256 voting_total = voting_escrow.totalSupply(block.timestamp);

        uint256 lim = l.mul(TOKENLESS_PRODUCTION).div(100);
        if ((voting_total > 0) && (block.timestamp > period_timestamp[0].add(BOOST_WARMUP))){
            lim = lim.add(L.mul(voting_balance).div(voting_total).mul(100 - TOKENLESS_PRODUCTION).div(100));
        }

        lim = min(l, lim);
        uint256 old_bal = working_balances[addr];
        working_balances[addr] = lim;
        uint256 _working_supply = working_supply.add(lim).sub(old_bal);
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _working_supply, voting_balance, voting_total);
    }

    struct CheckPointParameters{
        uint256 _period;
        uint256 _period_time;
        uint256 _integrate_inv_supply;
        uint256 rate;
        uint256 new_rate;
        uint256 prev_future_epoch;
        uint256 _working_balance;
        uint256 _working_supply;
    }

    function _checkpoint(address addr)internal{//s: 全体としてIis計算 & addrのIu計算. Iis, Iuについてはwhitepaper参照.
        /***
        *@notice Checkpoint for a user
        *@param addr User address
        *s: 全体としてIis計算: 1週間ごとにIisを計算して加算していく。Iisは時系列で増えていくもの
        *s: addrのIu計算: (addrが前回アプデした時のIisと現在のIisの差)*addrのLPデポジット量(CRVブースト含む)でその期間のシェアを計算する
        *s: working_supply, working_balanceがCRVブースト考慮した場合のデポジット量。 ↑の_update_liquidity_limit()が更新を担っているため、
        *   _checkpoint()=>_update_liquidity_limit()といった形でよく呼ばれている。
        */
        CheckPointParameters memory _;
        
        _._period = period;
        _._period_time = period_timestamp[_._period];
        _._integrate_inv_supply = integrate_inv_supply[_._period];
        _.rate = inflation_rate;
        _.new_rate = _.rate;
        _.prev_future_epoch = future_epoch_time;
        if (_.prev_future_epoch >= _._period_time){//s: future_epoch_time と inflation_rate の更新
            future_epoch_time = insure_token.future_epoch_time_write();
            _.new_rate = insure_token.get_rate();
            inflation_rate = _.new_rate;
        }
        controller.checkpoint_gauge(address(this)); //s: checkpoint_gauge(address(this) = external

        uint256 _working_balance = working_balances[addr];
        uint256 _working_supply = working_supply;

        if (is_killed){
            _.rate = 0;  // Stop distributing inflation as soon as killed
        }

        // Update integral of 1/supply //s:前回のアプデから１週間ごとに現在まで_integrate_inv_supplyを加算していき、 period+=1; integrate_inv_supply[period]に記録;
        if (block.timestamp > _._period_time){
            uint256 prev_week_time = _._period_time;
            uint256 week_time = min((_._period_time.add(WEEK)).div(WEEK).mul(WEEK), block.timestamp);

            for(uint i; i < 500; i++){
                uint256 dt = week_time.sub(prev_week_time);
                uint256 w = controller.gauge_relative_weight(address(this), prev_week_time.div(WEEK).mul(WEEK));

                if (_working_supply > 0){
                    if (_.prev_future_epoch >= prev_week_time && _.prev_future_epoch < week_time){
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _._integrate_inv_supply = _._integrate_inv_supply.add(_.rate.mul(w).mul(_.prev_future_epoch.sub(prev_week_time)).div(_working_supply));
                        _.rate = _.new_rate;
                        _._integrate_inv_supply = _._integrate_inv_supply.add(_.rate.mul(w).mul(week_time.sub(_.prev_future_epoch)).div(_working_supply));
                    }else{
                        _._integrate_inv_supply = _._integrate_inv_supply.add(_.rate.mul(w).mul(dt).div(_working_supply));
                    }
                    // On precisions of the calculation
                    // rate ~= 10e18
                    // last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // The largest loss is at dt = 1
                    // Loss is 1e-9 - acceptable
                }
                if (week_time == block.timestamp){//
                    break;
                }
                prev_week_time = week_time;
                week_time = min(week_time.add(WEEK), block.timestamp);//１週間or数日
            }
        }

        _._period = _._period.add(1);
        period = _._period;
        period_timestamp[_._period] = block.timestamp;
        integrate_inv_supply[_._period] = _._integrate_inv_supply;

        // Update user-specific integrals
        //s: 個人のΔIu計算してIuに加算
        integrate_fraction[addr] = integrate_fraction[addr].add(_working_balance.mul(_._integrate_inv_supply.sub(integrate_inv_supply_of[addr])).div(10 ** 18));//s: InsureDAO whitepaper 4ページ目上から３個目の式
        integrate_inv_supply_of[addr] = _._integrate_inv_supply;
        integrate_checkpoint_of[addr] = block.timestamp;
    }

    function user_checkpoint(address addr)external returns (bool){
        /***
        *@notice Record a checkpoint for `addr`
        *@param addr User address
        *@return bool success
        */
        require ((msg.sender == addr) || (msg.sender == address(minter)), "dev: unauthorized");  // dev unauthorized
        _checkpoint(addr);
        _update_liquidity_limit(addr, balanceOf[addr], totalSupply);
        return true;
    }

    function claimable_tokens(address addr)external returns (uint256){
        /***
        *@notice Get the number of claimable tokens per user
        *@dev This function should be manually changed to "view" in the ABI
        *@return uint256 number of claimable tokens per user
        */
        _checkpoint(addr);
        return (integrate_fraction[addr].sub(minter.get_minted(addr, address(this))));
    }


    function kick(address addr)external{
        /***
        *@notice Kick `addr` for abusing their boost
        *@dev Only if either they had another voting event, or their voting escrow lock expired
        *@param addr Address to kick
        */
        uint256 t_last = integrate_checkpoint_of[addr];
        uint256 t_ve = voting_escrow.user_point_history__ts(
            addr, voting_escrow.get_user_point_epoch(addr)
        );
        uint256 _balance = balanceOf[addr];

        require(voting_escrow.balanceOf(addr, block.timestamp) == 0 || t_ve > t_last, "dev: kick not allowed"); // dev kick not allowed
        require(working_balances[addr] > _balance.mul(TOKENLESS_PRODUCTION).div(100), "dev: kick not needed");  // dev kick not needed

        _checkpoint(addr);
        _update_liquidity_limit(addr, balanceOf[addr], totalSupply);
    }

    function set_approve_deposit(address addr, bool can_deposit)external{
        /***
        *@notice Set whether `addr` can deposit tokens for `msg.sender`
        *@param addr Address to set approval on
        *@param can_deposit bool - can this account deposit for `msg.sender`?
        */
        approved_to_deposit[addr][msg.sender] = can_deposit;
    }

    //@shun //@nonreentrant('lock')
    function deposit(uint256 _value, address addr)external nonReentrant{ //s: address addr = msg.sender
        /***
        *@notice Deposit `_value` LP tokens
        *@param _value Number of tokens to deposit
        *@param addr Address to deposit for
        */
        if (addr != msg.sender){
            require(approved_to_deposit[msg.sender][addr], "Not approved");
        }

        _checkpoint(addr);

        if (_value != 0){
            uint256 _balance = balanceOf[addr].add(_value);
            uint256 _supply = totalSupply.add(_value);
            balanceOf[addr] = _balance;
            totalSupply = _supply;

            _update_liquidity_limit(addr, _balance, _supply);

            assert(template.transferFrom(msg.sender, address(this), _value));
        }
        emit Deposit(addr, _value);
    }

    //@shun //@nonreentrant('lock')
    function withdraw(uint256 _value)external nonReentrant{
        /***
        *@notice Withdraw `_value` LP tokens
        *@param _value Number of tokens to withdraw
        */
        _checkpoint(msg.sender);

        uint256 _balance = balanceOf[msg.sender].sub(_value);
        uint256 _supply = totalSupply.sub(_value);
        balanceOf[msg.sender] = _balance;
        totalSupply = _supply;

        _update_liquidity_limit(msg.sender, _balance, _supply);

        require(template.transfer(msg.sender, _value));

        emit Withdraw(msg.sender, _value);
    }

    function integrate_checkpoint()external view returns (uint256){
        return period_timestamp[period];
    }

    function kill_me()external{
        assert (msg.sender == admin);
        is_killed = !is_killed;
    }


    function commit_transfer_ownership(address addr)external{
        /***
        *@notice Transfer ownership of GaugeController to `addr`
        *@param addr Address to have ownership transferred to
        */
        assert (msg.sender == admin);  // dev admin only
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function apply_transfer_ownership()external{
        /***
        *@notice Apply pending ownership transfer
        */
        assert (msg.sender == admin);  // dev admin only
        address _admin = future_admin;
        assert (_admin != address(0));  // dev admin not set
        admin = _admin;
        emit ApplyOwnership(_admin);
    }
}

// File: contracts/Minter.sol

pragma solidity ^0.6.0;
// @version 0.2.4
/***
*@title Token Minter
*@author InsureDAO
*@license MIT
*/

/***
*interface LiquidityGauge{
*    // Presumably, other gauges will provide the same interfaces
*    function integrate_fraction(address addr ) view returns(uint256);
*    function user_checkpoint(address addr)nonpayable returns(bool); 
*}
*
*interface MERC20{
*    function mint(address _to, uint256 _value)nonpayable returns(bool);
*}
*
*interface GaugeController{
*    function gauge_types(address addr)view returns (int256);
*}
*/







contract Minter{
    using SafeMath for uint256;
    //using SignedSafeMath for int256;

    event Minted(address indexed recipient, address gauge, uint256 minted);

    InsureToken public insure_token;
    function token()external view returns(address){
        return(address(insure_token));
    }
    //address public token; //InsureTokenのアドレス. ERC20(token).functionといった形で使われている

    GaugeController public gauge_controller;
    //address public controller;

    // user -> gauge -> value
    mapping(address => mapping(address => uint256))public minted;

    // minter -> user -> can mint?
    mapping(address => mapping(address => bool))public allowed_to_mint_for;


    constructor(address _token, address _controller)public{
        insure_token = InsureToken(_token);//s: Insure token
        gauge_controller = GaugeController(_controller);//s: GaugeController
    }

    function get_controller()external view returns(address){
        return address(gauge_controller);
    }

    function _mint_for(address gauge_addr, address _for)internal{
        require(gauge_controller.gauge_types(gauge_addr) > 0, "dev: gauge is not added");  // dev gauge is not added

        LiquidityGauge(gauge_addr).user_checkpoint(_for);
        uint256 total_mint = LiquidityGauge(gauge_addr).integrate_fraction(_for);//s: ユーザーに対してのトークン発行総量（発行済み含む）
        uint256 to_mint = total_mint.sub(minted[_for][gauge_addr]);//s: 今回の発行量

        if (to_mint != 0){
            insure_token.mint(_for, to_mint);
            minted[_for][gauge_addr] = total_mint;

            emit Minted(_for, gauge_addr, total_mint);
        }
    }

    //@shun: //@nonreentrant('lock')
    function mint(address gauge_addr)external{
        /***
        *@notice Mint everything which belongs to `msg.sender` and send to them
        *@param gauge_addr `LiquidityGauge` address to get mintable amount from
        */
        _mint_for(gauge_addr, msg.sender);
    }

    //@shun: //@nonreentrant('lock')
    function mint_many(address[8] memory gauge_addrs)external{
        /***
        *@notice Mint everything which belongs to `msg.sender` across multiple gauges
        *@param gauge_addrs List of `LiquidityGauge` addresses
        */
        for(uint i; i< 8; i++){
            if (gauge_addrs[i] == address(0)){
                break;
            }
            _mint_for(gauge_addrs[i], msg.sender);
        }
    }

    //@shun: //@nonreentrant('lock')
    function mint_for(address gauge_addr, address _for)external{
        /***
        *@notice Mint tokens for `_for`
        *@dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
        *@param gauge_addr `LiquidityGauge` address to get mintable amount from
        *@param _for Address to mint to
        */
        if (allowed_to_mint_for[msg.sender][_for]){
            _mint_for(gauge_addr, _for);
        }
    }

    function toggle_approve_mint(address minting_user)external{
        /***
        *@notice allow `minting_user` to mint for `msg.sender`
        *@param minting_user Address to toggle permission for
        */
        
        allowed_to_mint_for[minting_user][msg.sender] = !allowed_to_mint_for[minting_user][msg.sender]; //@shun: //allowed_to_mint_for[minting_user][msg.sender] = not allowed_to_mint_for[minting_user][msg.sender];
    }

    function get_minted(address _user, address _gauge)external view returns(uint256){
        return minted[_user][_gauge];
    }
}
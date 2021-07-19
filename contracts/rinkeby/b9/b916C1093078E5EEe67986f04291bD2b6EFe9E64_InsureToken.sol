/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/libraries/token/ERC20/IERC20.sol

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


// File contracts/libraries/math/SafeMath.sol

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


// File contracts/libraries/math/SignedSafeMath.sol

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


// File contracts/InsureToken.sol

pragma solidity 0.6.12;
/***
*@title InsureToken
*@author InsureDAO
*SPDX-License-Identifier: MIT
*@notice InsureDAO's governance token
*
*/



//The variables will be changed to fit to insureDAO token schedule.
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

    // Allocation within 5years:
    // =========
    // * Team & Development: 24%
    // * Liquidity Mining: 40%
    // * Investors: 10%
    // * Foundation Treasury: 14%
    // * Community Treasury: 10%
    // =========
    //
    // After 5years:
    // =========
    // * Liquidity Mining: 40%< (Mint Fixed amount every year)
    //
    // Mint 2_800_000 INSURE every year.
    // 6th year: 1.32% inflation rate
    // 7th year: 1.30% inflation rate
    // 8th year: 1.28% infration rate
    // so on
    // =========

    // Supply parameters
    uint256 constant INITIAL_SUPPLY = 126_000_000; //will be vested
    uint256 constant RATE_REDUCTION_TIME = YEAR;
    uint256[6] public RATES = 
        [
            28_000_000 * 10 ** 18 / YEAR, //INITIAL_RATE
            22_400_000 * 10 ** 18 / YEAR,
            16_800_000 * 10 ** 18 / YEAR,
            11_200_000 * 10 ** 18 / YEAR,
            5_600_000 * 10 ** 18 / YEAR,
            2_800_000 * 10 ** 18 / YEAR
        ];

    uint256 constant RATE_DENOMINATOR = 10 ** 18;
    uint256 constant INFLATION_DELAY = 86400; //1day

    // Supply variables
    int128 public mining_epoch;
    uint256 public start_epoch_time;
    uint256 public rate;

    uint256 public start_epoch_supply;

    uint256 public emergency_minted;

    constructor(string memory _name, string memory _symbol, uint256 _decimal) public {
        /***
        * @notice Contract constructor
        * @param _name Token full name
        * @param _symbol Token symbol
        * @param _decimal will be 18 in the migration script.
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

        if (mining_epoch == 0){
            _rate = RATES[uint256(mining_epoch)];
        }else if(mining_epoch < int128(6)){
            _start_epoch_supply = _start_epoch_supply.add(RATES[uint256(mining_epoch) - 1].mul(YEAR));
            start_epoch_supply = _start_epoch_supply;
            _rate = RATES[uint256(mining_epoch)];
        }else{
            _start_epoch_supply = _start_epoch_supply.add(RATES[5].mul(YEAR));
            start_epoch_supply = _start_epoch_supply;
            _rate = RATES[5];
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
        return start_epoch_supply.add((block.timestamp.sub(start_epoch_time)).mul(rate)).add(emergency_minted);
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
        int128 current_epoch = mining_epoch;

        // Special case if end is in future (not yet minted) epoch
        if (end > current_epoch_time.add(RATE_REDUCTION_TIME)){
            current_epoch_time = current_epoch_time.add(RATE_REDUCTION_TIME);
            if(current_epoch < 5){
                current_rate = RATES[uint256(mining_epoch) + 1];
            }else{
                current_rate = RATES[5];
            }
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
            if(current_epoch < 5){
                current_rate = RATES[uint256(current_epoch) + 1];
                current_epoch = current_epoch.add(1);
            }else{
                current_rate = RATES[5];
                current_epoch = current_epoch.add(1);
            }
            assert(current_rate <= RATES[0]);  // This should never happen
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


    //question: should we keep like this? I have not modify anything from the original yet.
    function approve(address _spender, uint256 _value)external override returns(bool){
        /**
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

        _mint(_to, _value);

        return true;
    }

    function _mint(address _to, uint256 _value)internal{
        if (block.timestamp >= start_epoch_time.add(RATE_REDUCTION_TIME)){
            _update_mining_parameters();
        }
        uint256 _total_supply = total_supply.add(_value);
        
        require(_total_supply <= _available_supply(), "dev: exceeds allowable mint amount");
        total_supply = _total_supply;

        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(address(0), _to, _value);
    }

    function burn(uint256 _value)external returns(bool){
        /**
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

    function emergency_mint(uint256 _amount, address _to)external {
        /***
        * @notice Emergency minting only when CDS couldn't afford the insolvency.
        * @dev 
        * @param _amountOut token amount needed. token is defiend whithin converter.
        * @param _to CDS address
        */
        require(msg.sender == minter, "dev: minter only");
        //mint
        emergency_minted = emergency_minted.add(_amount);
        _mint(_to, _amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-07-01
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


// File contracts/interfaces/ISmartWalletChecker.sol

pragma solidity ^0.6.0;

interface ISmartWalletChecker{
    function check(address addr)external returns(bool);
}


// File contracts/libraries/math/Math.sol



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


// File contracts/libraries/utils/ReentrancyGuard.sol



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


// File contracts/VotingEscrow.sol

pragma solidity 0.6.12;

/***
*@notice Votes have a weight depending on time, so that users are
*        committed to the future of (whatever they are voting for)
*@dev Vote weight decays linearly over time. Lock time cannot be
*     more than `MAXTIME` (4 years).
*SPDX-License-Identifier: MIT
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

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses




contract VotingEscrow is ReentrancyGuard{
    using SafeMath for uint256;
    using SignedSafeMath for int128;

    struct Point{
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts; //timestamp
        uint256 blk;  // block
    }
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    struct LockedBalance{
        int128 amount;
        uint256 end;
    }


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


    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history;  // epoch -> unsigned point. 
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
        *@param token_addr `InsureToken` token address
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
        require (msg.sender == admin, "dev: admin only");
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function apply_transfer_ownership()external{
        /***
        *@notice Apply ownership transfer
        */
        require (msg.sender == admin, "dev: admin only");
        address _admin = future_admin;
        require (_admin != address(0), "dev: admin not set");
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
            address checker = smart_wallet_checker; //not going to be deployed at the moment of launch.
            if (checker != address(0)){
                if(ISmartWalletChecker(checker).check(addr)){
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function get_last_user_slope(address addr)external view returns(uint256){
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

    function _checkpoint(address addr, LockedBalance memory old_locked, LockedBalance memory new_locked)internal {
        /***
        *@notice Record global and per-user data to checkpoint
        *@param addr User's wallet address. No user checkpoint if 0x0
        *@param old_locked Pevious locked amount / end lock time for the user
        *@param new_locked New locked amount / end lock time for the user
        */
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (addr != address(0)){
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0){
                u_old.slope = old_locked.amount.div(int128(MAXTIME));
                u_old.bias = u_old.slope.mul(int128(old_locked.end.sub(block.timestamp)));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0){
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
        epoch = _epoch;
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

        address addr2 = addr; //To avoid being "Stack Too Deep"

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

    function deposit_for(address _addr, uint256 _value)external nonReentrant{
        /***
        *@notice Deposit `_value` tokens for `_addr` and add to the lock
        *@dev Anyone (even a smart contract) can deposit for someone else, but
        *    cannot extend their locktime and deposit for a brand new user
        *@param _addr User's wallet address
        *@param _value Amount to add to user's lock
        */
        LockedBalance memory _locked = locked[_addr];

        require (_value > 0, "dev: need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(_addr, _value, 0, locked[_addr], DEPOSIT_FOR_TYPE);
    }

    function create_lock(uint256 _value, uint256 _unlock_time)external nonReentrant{
        /***
        *@notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
        *@param _value Amount to deposit
        *@param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
        */

        assert_not_contract(msg.sender);
        uint256 unlock_time = _unlock_time.div(WEEK).mul(WEEK);  // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[msg.sender];

        require (_value > 0, "dev: need non-zero value");
        require (_locked.amount == 0, "Withdraw old tokens first");
        require (unlock_time > block.timestamp, "Can only lock until time in the future");
        require (unlock_time <= block.timestamp.add(MAXTIME), "Voting lock can be 4 years max");

        _deposit_for(msg.sender, _value, unlock_time, _locked, CREATE_LOCK_TYPE);
    }

    function increase_amount(uint256 _value)external nonReentrant{
        /***
        *@notice Deposit `_value` additional tokens for `msg.sender`
        *        without modifying the unlock time
        *@param _value Amount of tokens to deposit and add to the lock
        */
        assert_not_contract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];

        assert (_value > 0);
        require (_locked.amount > 0, "No existing lock found");
        require (_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    function increase_unlock_time(uint256 _unlock_time)external nonReentrant{
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

    function withdraw()external nonReentrant{
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
    
    function balanceOf(address addr , uint256 _t)external view returns (uint256){
        /***
        *@notice Get the current voting power for `msg.sender`
        *@dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
        *@param addr User wallet address
        *@param _t Epoch time to return voting power at
        *@return User voting power
        */

        if(_t == 0){
            _t = block.timestamp;
        }

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


    //Struct to avoid "Stack Too Deep"
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

    function supply_at(Point memory point, uint256 t)internal view returns (uint256){
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

    function totalSupply(uint256 t)external view returns (uint256){
        /***
        *@notice Calculate total voting power
        *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
        *@return Total voting power
        */
        if(t == 0){
            t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];

        return supply_at(last_point, t);
        
    }

    function totalSupplyAt(uint256 _block)external view returns (uint256){
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
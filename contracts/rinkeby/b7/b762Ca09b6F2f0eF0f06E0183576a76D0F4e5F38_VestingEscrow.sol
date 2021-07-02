/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

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


// File contracts/VestingEscrow.sol

pragma solidity 0.6.12;

/***
*@title Vesting Escrow
*@author InsureDAO
*SPDX-License-Identifier: MIT
*@notice Vests `InsureToken` tokens for multiple addresses over multiple vesting periods
*/




contract VestingEscrow is ReentrancyGuard{
    using SafeMath for uint256;
    
    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 claimed);
    event ToggleDisable(address recipient, bool disabled);
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);


    address public token; //address of $Insure
    uint256 public start_time;
    uint256 public end_time;
    mapping(address => uint256)public initial_locked;
    mapping(address => uint256)public total_claimed;

    uint256 public initial_locked_supply;
    uint256 public unallocated_supply;

    bool public can_disable;
    mapping(address => uint256) public disabled_at;

    address public admin;
    address public future_admin;

    bool public fund_admins_enabled;
    mapping(address => bool) public fund_admins;


    
    constructor(
        address _token,
        uint256 _start_time,
        uint256 _end_time,
        bool _can_disable, 
        address[4] memory _fund_admins
    )public {
        /***
        *@param _token Address of the ERC20 token being distributed
        *@param _start_time Timestamp at which the distribution starts. Should be in
        *    the future, so that we have enough time to VoteLock everyone
        *@param _end_time Time until everything should be vested
        *@param _can_disable Whether admin can disable accounts in this deployment.
        *@param _fund_admins Temporary admin accounts used only for funding
        */
        assert (_start_time >= block.timestamp);
        assert (_end_time > _start_time);

        token = _token;
        admin = msg.sender;
        start_time = _start_time;
        end_time = _end_time;
        can_disable = _can_disable;

        bool _fund_admins_enabled = false;
        for (uint256 i; i < _fund_admins.length; i++){
            address addr = _fund_admins[i];
            if (addr != address(0)){
                fund_admins[addr] = true;
                if (!_fund_admins_enabled){
                    _fund_admins_enabled = true;
                    fund_admins_enabled = true;
                }
            }
        }

    }

    
    function add_tokens(uint256 _amount)external{
        /***
        *@notice Transfer vestable tokens into the contract
        *@dev Handled separate from `fund` to reduce transaction count when using funding admins
        *@param _amount Number of tokens to transfer
        */
        require (msg.sender == admin, "dev admin only"); // dev admin only
        require (IERC20(token).transferFrom(msg.sender, address(this), _amount), "dev transfer failed");
        unallocated_supply = unallocated_supply.add(_amount);
    }

    function fund(address[100] memory _recipients, uint256[100] memory _amounts)external nonReentrant{
        /***
        *@notice Vest tokens for multiple recipients.
        *@param _recipients List of addresses to fund
        *@param _amounts Amount of vested tokens for each address
        */
        if (msg.sender != admin){
            require (fund_admins[msg.sender], "dev admin only");
            require (fund_admins_enabled, "dev fund admins disabled");
        }

        uint256 _total_amount = 0;
        for(uint256 i;  i< 100; i++){
            uint256 amount = _amounts[i];
            address recipient = _recipients[i];
            if (recipient == address(0)){
                break;
            }
            _total_amount = _total_amount.add(amount);
            initial_locked[recipient] = initial_locked[recipient].add(amount);
            emit Fund(recipient, amount);
        }

        initial_locked_supply = initial_locked_supply.add(_total_amount);
        unallocated_supply = unallocated_supply.sub(_total_amount);
    }


    
    function toggle_disable(address _recipient)external{
        /***
        *@notice Disable or re-enable a vested address's ability to claim tokens
        *@dev When disabled, the address is only unable to claim tokens which are still
        *    locked at the time of this call. It is not possible to block the claim
        *    of tokens which have already vested.
        *@param _recipient Address to disable or enable
        */
        require (msg.sender == admin, "dev: admin only");
        require (can_disable, "Cannot disable");

        bool is_disabled = disabled_at[_recipient] == 0;
        if (is_disabled){
            disabled_at[_recipient] = block.timestamp;
        }else{
            disabled_at[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, is_disabled);
    }

    
    function disable_can_disable()external{
        /***
        *@notice Disable the ability to call `toggle_disable`
        */
        require (msg.sender == admin, "dev admin only");
        can_disable = false;
    }


    
    function disable_fund_admins()external{
        /***
        *@notice Disable the funding admin accounts
        */
        require (msg.sender == admin, "dev admin only");
        fund_admins_enabled = false;
    }
    
    function _total_vested_of(address _recipient, uint256 _time)internal view returns (uint256){
        /***
        * @notice Amount of unlocked token amount of _recipient at _time. (include claimed)
        */
        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked[_recipient];
        if (_time < start){
            return 0;
        }
        return min(locked.mul(_time.sub(start)).div(end.sub(start)), locked);
    }

    function _total_vested()internal view returns (uint256){
        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked_supply;

        if(block.timestamp < start){
            return 0;
        }else{
            return min(locked.mul(block.timestamp.sub(start)).div(end.sub(start)), locked); // when block.timestamp > end, return locked
        }
    }

    function vestedSupply()external view returns (uint256){
        /***
        *@notice Get the total number of tokens which have vested, that are held
        *        by this contract
        */
        return _total_vested();
    }
    
    function lockedSupply()external view returns (uint256){
        /***
        *@notice Get the total number of tokens which are still locked
        *        (have not yet vested)
        */
        return initial_locked_supply.sub(_total_vested());
    }

    function vestedOf(address _recipient)external view returns (uint256){
        /***
        *@notice Get the number of tokens which have vested for a given address
        *@param _recipient address to check
        */
        return _total_vested_of(_recipient, block.timestamp);
    }

    function balanceOf(address _recipient)external view returns (uint256){
        /***
        *@notice Get the number of unclaimed, vested tokens for a given address
        *@param _recipient address to check
        */
        return _total_vested_of(_recipient, block.timestamp).sub(total_claimed[_recipient]);
    }

    function lockedOf(address _recipient)external view returns (uint256){
        /***
        *@notice Get the number of locked tokens for a given address
        *@param _recipient address to check
        */
        return initial_locked[_recipient].sub(_total_vested_of(_recipient, block.timestamp));
    }

    function claim(address addr)external nonReentrant{
        /***
        *@notice Claim tokens which have vested
        *@param addr Address to claim tokens for
        */
        uint256 t = disabled_at[addr];
        if (t == 0){
            t = block.timestamp;
        }
        uint256 claimable = _total_vested_of(addr, t).sub(total_claimed[addr]);

        total_claimed[addr] = total_claimed[addr].add(claimable);
        assert (IERC20(token).transfer(addr, claimable));

        emit Claim(addr, claimable);
    }


    
    function commit_transfer_ownership(address addr)external returns (bool){
        /***
        *@notice Transfer ownership of GaugeController to `addr`
        *@param addr Address to have ownership transferred to
        */
        require (msg.sender == admin, "dev: admin only");
        future_admin = addr;
        emit CommitOwnership(addr);

        return true;
    }


    
    function apply_transfer_ownership()external returns (bool){
        /***
        *@notice Apply pending ownership transfer
        */
        require (msg.sender == admin, "dev: admin only");
        address _admin = future_admin;
        require (_admin != address(0), "dev: admin not set");
        admin = _admin;
        emit ApplyOwnership(_admin);

        return true;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interface/IEmiERC20.sol";
import "./interface/IEmiRouter.sol";
import "./interface/IEmiswap.sol";

contract EmiStaking02 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //-----------------------------------------------------------------------------------
    // Data Structures
    //-----------------------------------------------------------------------------------
    struct LockRecord {
        uint256 amountLocked; // Amount of locked tokens in total
        uint64 lockDate; // when lock is made
        uint64 unlockDate; // when lock is made
        uint128 isWithdrawn; // whether or not it is withdrawn already
        uint256 id;
    }

    event StartStaking(
        address wallet,
        uint256 startDate,
        uint256 stopDate,
        uint256 stakeID,
        address token,
        uint256 amount
    );

    event StakesClaimed(address indexed beneficiary, uint256 stakeId, uint256 amount);
    event LockPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);

    //-----------------------------------------------------------------------------------
    // Variables, Instances, Mappings
    //-----------------------------------------------------------------------------------
    /* Real beneficiary address is a param to this mapping */
    mapping(address => LockRecord[]) private locksTable;

    address public lockToken;
    uint256 public lockPeriod;
    uint256 public stakingEndDate;
    uint256 public stakingLastUnlock;
    uint256 public maxUSDStakes;

    address public emiRouter;
    address[] public pathToStables;
    uint8 public tokenMode; // 0 = simple ERC20 token, 1 = Emiswap LP-token

    /**
     * @dev Constructor for the smartcontract
     * @param _token Token to stake
     * @param _lockPeriod Amount of days to stake (30 days, 60 days etc.)
     * @param _maxUSDValue Maximum stakes value in USD per single staker (value in $)
     * @param _router EmiRouter address
     * @param _path Path to stable coins from stake token
     */
    constructor(
        address _token,
        uint256 _lockPeriod,
        uint256 _maxUSDValue,
        address _router,
        address [] memory _path
    ) public {
        require(_token != address(0), "Token address cannot be empty");
        require(_router != address(0), "Router address cannot be empty");
        require(_path.length > 0, "Path to stable coins must exist");
        require(_lockPeriod > 0, "Lock period cannot be 0");
        lockToken = _token;
        stakingEndDate = block.timestamp + _lockPeriod;
        lockPeriod = _lockPeriod;
//        lockPeriod = 5 minutes;
        emiRouter = _router;
        stakingLastUnlock = stakingEndDate + _lockPeriod;
        pathToStables = _path;
        maxUSDStakes = _maxUSDValue; // 100000 by default
        tokenMode = 0; // simple ERC20 token by default
    }

    /**
     * @dev Stake tokens to contract
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external {
        require(block.timestamp < stakingEndDate, "Staking is over");
        require(_checkMaxUSDCondition(msg.sender, amount) == true, "Max stakes values in USD reached");
        IERC20(lockToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 stakeId = uint256(
            keccak256(abi.encodePacked("Emiswap", block.timestamp, block.difficulty, block.gaslimit))
        );
        locksTable[msg.sender].push(
            LockRecord({
                amountLocked: amount,
                lockDate: uint64(block.timestamp),
                unlockDate: uint64(block.timestamp + lockPeriod),
                id: stakeId,
                isWithdrawn: 0
            })
        );
        emit StartStaking(msg.sender, block.timestamp, block.timestamp + lockPeriod, stakeId, lockToken, amount);
    }

    /**
     * @dev Withdraw all unlocked tokens not withdrawn already
     */
    function withdraw() external {
        LockRecord[] memory t = locksTable[msg.sender];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate || block.timestamp >= stakingLastUnlock)) {
                _bal = _bal.add(t[i].amountLocked);
                locksTable[msg.sender][i].isWithdrawn = 1;
                emit StakesClaimed(msg.sender, t[i].id, t[i].amountLocked);
            }
        }

        require(_bal > 0, "No stakes to withdraw");

        IERC20(lockToken).safeTransfer(msg.sender, _bal);
    }

    /**
     * @dev Return length of stakers' stake array. Admin only
     * @param staker Address of staker to pull data for
     */
    function getStakesLen(address staker) external view onlyOwner returns (uint256) {
        return locksTable[staker].length;
    }

    /**
     * @dev Return stake record for the specified staker. Admin only
     * @param staker Address of staker to pull data for
     * @param idx Index of stake record in array
     */
    function getStake(address staker, uint256 idx) external view onlyOwner returns (LockRecord memory) {
        require(idx < locksTable[staker].length, "Idx is wrong");

        return locksTable[staker][idx];
    }

    /**
     * @dev Return length of callee stake array.
     */
    function getMyStakesLen() external view returns (uint256) {
        return locksTable[msg.sender].length;
    }

    /**
     * @dev Return stake record for the callee.
     * @param idx Index of stake record in array
     */
    function getMyStake(uint256 idx) external view returns (LockRecord memory) {
        require(idx < locksTable[msg.sender].length, "Idx is wrong");

        return locksTable[msg.sender][idx];
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed for the specified staker. Admin only
     * @param staker Address of staker to pull data for
     */
    function unlockedBalanceOf(address staker) external view onlyOwner returns (uint256, uint256) {
        uint256 _bal = _getBalance(staker, true);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of all staked tokens for the callee staker.
     */
    function balanceOf() external view returns (uint256, uint256) {
        uint256 _bal = _getBalance(msg.sender, false);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed by the callee
     */
    function myUnlockedBalance() external view returns (uint256, uint256) {
        uint256 _bal = _getBalance(msg.sender, true);
        return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Return amount of unlocked tokens ready to be claimed for the specified staker
     * @param staker Address of staker to pull data for
     * @param unlockedOnly Only count unlocked balance ready to be withdrawn
     */
    function _getBalance(address staker, bool unlockedOnly) internal view returns (uint256) {
        LockRecord[] memory t = locksTable[staker];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0) {
                if (!unlockedOnly || (unlockedOnly && (block.timestamp >= t[i].unlockDate || block.timestamp >= stakingLastUnlock))) {
                  _bal = _bal.add(t[i].amountLocked);
                }
            }
        }
        return _bal;
    }

    /**
     * @dev Checks whether USD value of all staker stakes exceed MaxUSD condition
     * @param staker Address of staker to pull data for
     * @param amount Amount of tokens to make a new stake
     */
    function _checkMaxUSDCondition(address staker, uint256 amount) internal view returns (bool) {
       // calc total token balance for staker
        LockRecord[] memory t = locksTable[staker];
        uint256 _bal;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0) { // count only existing tokens -- both locked and unlocked
                _bal = _bal.add(t[i].amountLocked);
            }
        }

        return (_getUSDValue(_bal.add(amount)) <= maxUSDStakes);
    }

    
    function getTotals() external view returns (uint256, uint256)
    {
      uint256 _bal = IERC20(lockToken).balanceOf(address(this));
      return (_bal, _getUSDValue(_bal));
    }

    /**
     * @dev Checks whether USD value of all staker stakes exceed MaxUSD condition
     * @param amount Amount of tokens to make a new stake
     */
    function _getUSDValue(uint256 amount) internal view returns (uint256 stakesTotal) {
        if (tokenMode==0) { // straight token
          uint256 tokenDec = IEmiERC20(pathToStables[pathToStables.length-1]).decimals();
          uint256 [] memory tokenAmounts = IEmiRouter(emiRouter).getAmountsOut(amount, pathToStables);
          stakesTotal = tokenAmounts[tokenAmounts.length-1].div(10**tokenDec);
        } else if (tokenMode==1) {
          stakesTotal = _getStakesForLPToken(amount);
        } else {
          return 0;
        }
    }

    /**
     * @dev Return price of all stakes calculated by LP token scheme: price(token0)*2
     * @param amount Amount of tokens to stake
     */
    function _getStakesForLPToken(uint256 amount) internal view returns(uint256)
    {
       uint256 lpFraction = amount.mul(10**18).div(IERC20(lockToken).totalSupply());
       uint256 tokenIdx = 0;

       if (pathToStables[0]!=address(IEmiswap(lockToken).tokens(0))) {
         tokenIdx = 1;
       }

       uint256 rsv = IEmiswap(lockToken).getBalanceForAddition(
            IEmiswap(lockToken).tokens(tokenIdx)
       );

       uint256 tokenDstDec = IEmiERC20(pathToStables[pathToStables.length-1]).decimals();
       uint256 tokenSrcDec = IEmiERC20(pathToStables[0]).decimals();

       uint256 [] memory tokenAmounts = IEmiRouter(emiRouter).getAmountsOut(10**tokenSrcDec, pathToStables);
       return tokenAmounts[tokenAmounts.length-1].mul(rsv).div(10**tokenSrcDec).mul(2).mul(lpFraction).div(10**(18 + tokenDstDec));
    }

    /**
     * @dev Return lock records ready to be unlocked
     * @param staker Address of staker to pull data for
     */
    function getUnlockedRecords(address staker) external view onlyOwner returns (LockRecord[] memory) {
        LockRecord[] memory t = locksTable[staker];
        uint256 l;

        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate  || block.timestamp >= stakingLastUnlock)) {
                l++;
            }
        }
        if (l==0) {
          return new LockRecord[](0);
        }
        LockRecord[] memory r = new LockRecord[](l);
        uint256 j = 0;
        for (uint256 i = 0; i < t.length; i++) {
            if (t[i].isWithdrawn == 0 && (block.timestamp >= t[i].unlockDate  || block.timestamp >= stakingLastUnlock)) {
                r[j++] = t[i];
            }
        }

        return r;
    }

    /**
     * @dev Update lock period
     * @param _lockPeriod Lock period to set (is seconds)
     */
    function updateLockPeriod(uint256 _lockPeriod) external onlyOwner {
        emit LockPeriodUpdated(lockPeriod, _lockPeriod);
        lockPeriod = _lockPeriod;
    }

    /**
     * @dev Update last unlock date
     * @param _unlockTime Last unlock time (unix timestamp)
     */
    function updateLastUnlock(uint256 _unlockTime) external onlyOwner {
        stakingLastUnlock = _unlockTime;
    }

    /**
     * @dev Update path to stables
     * @param _path Path to stable coins
     */
    function updatePathToStables(address [] calldata _path) external onlyOwner {
        pathToStables = _path;
    }

    /**
     * @dev Update maxUSD value
     * @param _value Max USD value in USD (ex. 40000 for $40000)
     */
    function updateMaxUSD(uint256 _value) external onlyOwner {
        maxUSDStakes = _value;
    }

    /**
     * @dev Update tokenMode
     * @param _mode Token mode to set (0 for ERC20 token, 1 for Emiswap LP-token)
     */
    function updateTokenMode(uint8 _mode) external onlyOwner {
        require(_mode < 2, "Wrong token mode");
        tokenMode = _mode;
    }

    // ------------------------------------------------------------------------
    //
    // ------------------------------------------------------------------------
    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     * @param tokenAddress Address of ERC-20 token to transfer
     * @param beneficiary Address to transfer to
     * @param tokens Amount of tokens to transfer
     */
    function transferAnyERC20Token(
        address tokenAddress,
        address beneficiary,
        uint256 tokens
    ) external onlyOwner returns (bool success) {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(tokenAddress != lockToken, "Token cannot be ours");

        return IERC20(tokenAddress).transfer(beneficiary, tokens);
    }
}

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

interface IEmiERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmiRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getReserves(IERC20 token0, IERC20 token1)
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            address poolAddresss
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address ref
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address ref
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address[] calldata pathDAI
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata pathDAI
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address[] calldata pathDAI
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata pathDAI
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address[] calldata pathDAI
    ) external payable returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata pathDAI
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata pathDAI
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata pathDAI
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmiswapRegistry {
    function pools(IERC20 token1, IERC20 token2)
        external
        view
        returns (IEmiswap);

    function isPool(address addr) external view returns (bool);

    function deploy(IERC20 tokenA, IERC20 tokenB) external returns (IEmiswap);
    function getAllPools() external view returns (IEmiswap[] memory);
}

interface IEmiswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        address referral
    ) external payable returns (uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token)
        external
        view
        returns (uint256);

    function getBalanceForRemoval(IERC20 token) external view returns (uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns (uint256, uint256);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address to,
        address referral
    ) external payable returns (uint256 returnAmount);

    function initialize(IERC20[] calldata assets) external;
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


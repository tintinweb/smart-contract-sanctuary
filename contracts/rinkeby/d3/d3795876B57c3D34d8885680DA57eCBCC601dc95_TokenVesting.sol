// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/FixedPoint.sol";

contract TokenVesting is Context,Ownable{
    using SafeMath for uint256;
    address public token;
    
    /// @notice total lock of history
    uint256 public historyTotalLock;

    /// @notice total lock of current
    uint256 public currentTotalLock;

    /// @notice Have withdrawal
    uint256 public totalWithdrawal;

    /// @notice cycle of release 1 Days
    uint256 public releaseCycle = 1;
    
    // @notice rate of release 0.5%/1Days
    uint256 public releaseRate = 0.005e18;

    uint256 public awardLowRate = 0.2e18;
    uint256 public awardMiddleRate = 0.3e18;
    uint256 public awardHighRate = 0.5e18;

    uint256 public awardLowAmount = 50e4;
    uint256 public awardMiddleAmount = 100e4;
    uint256 public awardHighAmount = 200e4;

    /// @notice cycle of award 200 Days
    uint256 public awardCycle = 200;

    struct TokenVestUser {
      uint256 _lastReleaseTimestamp;
      uint256 _awardCreateTimestamp;
      uint256 _lockAmount;
      uint256 _releaseAmount;
      uint256 _waitingWithdrawalAmount;
      uint256 _awardAmount;
      
      uint256 _noReleaseLockAmount;
    } 
    
    /// @notice Lock up the user
    mapping(address => TokenVestUser) public tokenVestUsers;
    
    /// @notice withdrawal record of the user
    mapping(address => uint256) public tokenVestUsersWithdrawal;

    constructor(address _token)public{
      token = _token;
    }
    
    /// @notice event of Lock
    event Lock(
      uint256 _amountIn
    ); 
    
    /// @notice event of withdrawal
    event Withdrawal(
      uint256 _amountOut
    ); 
    
    /// @notice event of UpDataRelease
    event UpDataRelease(
      uint256 indexReleaseDeltaunlockReleaseAmount,
      uint256 indexReleaseDeltaunlockAwardAmount
    );
    
    /// @notice lockUp token 
    /// @param _amountIn amount of token
    function lock(uint256 _amountIn) public returns (bool){
      upDataRelease(true);
      //transfer token to this
      require(IERC20(token).transferFrom(msg.sender, address(this), _amountIn),"TokenVesting-lockUp/transfer-failed");
      //add lockAmount
      tokenVestUsers[msg.sender]._lockAmount = tokenVestUsers[msg.sender]._lockAmount.add(_amountIn);
      tokenVestUsers[msg.sender]._noReleaseLockAmount = tokenVestUsers[msg.sender]._noReleaseLockAmount.add(_amountIn);
      currentTotalLock = currentTotalLock.add(_amountIn);
      historyTotalLock = historyTotalLock.add(_amountIn);
      emit Lock(_amountIn);
      return true;
    }

    /// @notice withdrawal token 
    function withdrawal() public returns(uint256){
      require(tokenVestUsers[msg.sender]._lockAmount > 0,"TokenVesting-unlock/lockUpAmount-error");
      upDataRelease(false);
      uint256 amountOut = tokenVestUsers[msg.sender]._waitingWithdrawalAmount;

      if(IERC20(token).balanceOf(address(this)) >= currentTotalLock && IERC20(token).balanceOf(address(this)).sub(currentTotalLock) >= tokenVestUsers[msg.sender]._awardAmount){
         amountOut = tokenVestUsers[msg.sender]._waitingWithdrawalAmount.add(tokenVestUsers[msg.sender]._awardAmount);
      }
      require(amountOut > 0,"TokenVesting-unlock/unlockAmount-error");
      //transfer token to msg sender
      require(IERC20(token).transfer(msg.sender,amountOut),"TokenVesting-unlock/transfer-failed");   

      currentTotalLock = currentTotalLock.sub(tokenVestUsers[msg.sender]._waitingWithdrawalAmount);
      totalWithdrawal = totalWithdrawal.add(amountOut);
      tokenVestUsersWithdrawal[msg.sender] = tokenVestUsersWithdrawal[msg.sender].add(amountOut);

      emit Withdrawal(amountOut);
      if(!clearLockParams()){
        tokenVestUsers[msg.sender]._waitingWithdrawalAmount = 0;
        if(tokenVestUsers[msg.sender]._awardAmount != 0){
          tokenVestUsers[msg.sender]._awardAmount = 0;
        }
      }
   
      return amountOut;
    }
    
    /// @notice clear params of lock
    function clearLockParams() private returns(bool){
       if(tokenVestUsers[msg.sender]._releaseAmount >= tokenVestUsers[msg.sender]._lockAmount){
          delete tokenVestUsers[msg.sender];
          return true;
       }
       return false;
       
    }
    /// @notice upData params of release 
    function upDataRelease(bool isUpDataCreateTimestamp) private returns(uint256,uint256) {

      uint256 currentTimestamp = _currentTime();
      if(tokenVestUsers[msg.sender]._lastReleaseTimestamp == currentTimestamp){
          return (0,0);
      }

      if(tokenVestUsers[msg.sender]._awardCreateTimestamp == 0){
        tokenVestUsers[msg.sender]._awardCreateTimestamp = currentTimestamp;
        tokenVestUsers[msg.sender]._lastReleaseTimestamp = currentTimestamp;
      }
      
      uint256 indexReleaseDeltaunlockReleaseAmount;
      uint256 indexReleaseDeltaunlockAwardAmount;

      //calculate release 
      uint256 newReleaseSeconds = currentTimestamp.sub(tokenVestUsers[msg.sender]._lastReleaseTimestamp);
      uint256 releaseDay = newReleaseSeconds.div(releaseCycle);
    
      if(releaseDay >= 1 && tokenVestUsers[msg.sender]._noReleaseLockAmount != 0){
        indexReleaseDeltaunlockReleaseAmount = FixedPoint.multiplyUintByMantissa(tokenVestUsers[msg.sender]._noReleaseLockAmount,releaseDay.mul(releaseRate));

        if(indexReleaseDeltaunlockReleaseAmount > tokenVestUsers[msg.sender]._lockAmount.sub(tokenVestUsers[msg.sender]._releaseAmount)){
           indexReleaseDeltaunlockReleaseAmount = tokenVestUsers[msg.sender]._lockAmount.sub(tokenVestUsers[msg.sender]._releaseAmount);
        }

        if(tokenVestUsers[msg.sender]._releaseAmount < tokenVestUsers[msg.sender]._lockAmount){
           
          tokenVestUsers[msg.sender]._releaseAmount = tokenVestUsers[msg.sender]._releaseAmount.add(indexReleaseDeltaunlockReleaseAmount);
          tokenVestUsers[msg.sender]._waitingWithdrawalAmount = tokenVestUsers[msg.sender]._waitingWithdrawalAmount.add(indexReleaseDeltaunlockReleaseAmount);

          if(tokenVestUsers[msg.sender]._releaseAmount > tokenVestUsers[msg.sender]._lockAmount){
            tokenVestUsers[msg.sender]._releaseAmount = tokenVestUsers[msg.sender]._lockAmount;
          }
        }
        tokenVestUsers[msg.sender]._lastReleaseTimestamp = tokenVestUsers[msg.sender]._lastReleaseTimestamp.add(releaseDay.mul(releaseCycle));
      }
  
      //calculate award
      uint256 newAwardSeconds = currentTimestamp.sub(tokenVestUsers[msg.sender]._awardCreateTimestamp);
      if(newAwardSeconds >= awardCycle && tokenVestUsers[msg.sender]._noReleaseLockAmount != 0){
        if(tokenVestUsers[msg.sender]._noReleaseLockAmount >= awardHighAmount){
          indexReleaseDeltaunlockAwardAmount =  FixedPoint.multiplyUintByMantissa(tokenVestUsers[msg.sender]._noReleaseLockAmount,awardHighRate);
        }else if(tokenVestUsers[msg.sender]._noReleaseLockAmount >= awardMiddleAmount){
          indexReleaseDeltaunlockAwardAmount =  FixedPoint.multiplyUintByMantissa(tokenVestUsers[msg.sender]._noReleaseLockAmount,awardMiddleRate);
        }else if(tokenVestUsers[msg.sender]._noReleaseLockAmount >= awardLowAmount){
          indexReleaseDeltaunlockAwardAmount =  FixedPoint.multiplyUintByMantissa(tokenVestUsers[msg.sender]._noReleaseLockAmount,awardLowRate);
        }
        
        if(indexReleaseDeltaunlockAwardAmount > 0){
          tokenVestUsers[msg.sender]._awardAmount = tokenVestUsers[msg.sender]._awardAmount.add(indexReleaseDeltaunlockAwardAmount);
        }
      
        tokenVestUsers[msg.sender]._awardCreateTimestamp = tokenVestUsers[msg.sender]._awardCreateTimestamp.add(newAwardSeconds);
        tokenVestUsers[msg.sender]._noReleaseLockAmount = 0;
      }
            
      if(isUpDataCreateTimestamp){
          tokenVestUsers[msg.sender]._awardCreateTimestamp = currentTimestamp;
      }
      
      emit UpDataRelease(indexReleaseDeltaunlockReleaseAmount,indexReleaseDeltaunlockAwardAmount);
      return (indexReleaseDeltaunlockReleaseAmount,indexReleaseDeltaunlockAwardAmount);
    }

    /// @notice returns the current time.  Allows for override in testing.
    /// @return The current time (block.timestamp)
    function _currentTime() internal virtual view returns (uint256) {
      return block.timestamp;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

library FixedPoint {
    using SafeMath for uint256;

    // The scale to use for fixed point numbers.  Same as Ether for simplicity.
    uint256 internal constant SCALE = 1e18;

    /**
        * Calculates a Fixed18 mantissa given the numerator and denominator
        *
        * The mantissa = (numerator * 1e18) / denominator
        *
        * @param numerator The mantissa numerator
        * @param denominator The mantissa denominator
        * @return The mantissa of the fraction
        */
    function calculateMantissa(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        uint256 mantissa = numerator.mul(SCALE);
        mantissa = mantissa.div(denominator);
        return mantissa;
    }

    /**
        * Multiplies a Fixed18 number by an integer.
        *
        * @param b The whole integer to multiply
        * @param mantissa The Fixed18 number
        * @return An integer that is the result of multiplying the params.
        */
    function multiplyUintByMantissa(uint256 b, uint256 mantissa) internal pure returns (uint256) {
        uint256 result = mantissa.mul(b);
        result = result.div(SCALE);
        return result;
    }

    /**
    * Divides an integer by a fixed point 18 mantissa
    *
    * @param dividend The integer to divide
    * @param mantissa The fixed point 18 number to serve as the divisor
    * @return An integer that is the result of dividing an integer by a fixed point 18 mantissa
    */
    function divideUintByMantissa(uint256 dividend, uint256 mantissa) internal pure returns (uint256) {
        uint256 result = SCALE.mul(dividend);
        result = result.div(mantissa);
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @title FixidityLib
 * @author Gadi Guy, Alberto Cuesta Canada
 * @notice This library provides fixed point arithmetic with protection against
 * overflow. 
 * All operations are done with int256 and the operands must have been created 
 * with any of the newFrom* functions, which shift the comma digits() to the 
 * right and check for limits.
 * When using this library be sure of using maxNewFixed() as the upper limit for
 * creation of fixed point numbers. Use maxFixedMul(), maxFixedDiv() and
 * maxFixedAdd() if you want to be certain that those operations don't 
 * overflow.
 */
library FixidityLib {

    /**
     * @notice Number of positions that the comma is shifted to the right.
     */
    function digits() internal pure returns(uint8) {
        return 24;
    }
    
    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 10^digits()
     * Hardcoded to 24 digits.
     */
    function fixed1() internal pure returns(int256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() internal pure returns(int256) {
        return 1000000000000;
    }

    /**
     * @notice Maximum value that can be represented in an int256
     * @dev Test maxInt256() equals 2^255 -1
     */
    function maxInt256() internal pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * @notice Minimum value that can be represented in an int256
     * @dev Test minInt256 equals (2^255) * (-1)
     */
    function minInt256() internal pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * @dev deployment. 
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() internal pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * deployment. 
     * @dev Test minNewFixed() equals -(maxInt256()) / fixed1()
     * Hardcoded to 24 digits.
     */
    function minNewFixed() internal pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as an addition operator.
     * @dev Test maxFixedAdd() equals maxInt256()-1 / 2
     * Test add(maxFixedAdd(),maxFixedAdd()) equals maxFixedAdd() + maxFixedAdd()
     * Test add(maxFixedAdd()+1,maxFixedAdd()) throws 
     * Test add(-maxFixedAdd(),-maxFixedAdd()) equals -maxFixedAdd() - maxFixedAdd()
     * Test add(-maxFixedAdd(),-maxFixedAdd()-1) throws 
     */
    function maxFixedAdd() internal pure returns(int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * @notice Maximum negative value that can be safely in a subtraction.
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() internal pure returns(int256) {
        return -28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }

    /**
     * @notice Maximum value that can be safely used as a multiplication operator.
     * @dev Calculated as sqrt(maxInt256()*fixed1()). 
     * Be careful with your sqrt() implementation. I couldn't find a calculator
     * that would give the exact square root of maxInt256*fixed1 so this number
     * is below the real number by no more than 3*10**28. It is safe to use as
     * a limit for your multiplications, although powers of two of numbers over
     * this value might still work.
     * Test multiply(maxFixedMul(),maxFixedMul()) equals maxFixedMul() * maxFixedMul()
     * Test multiply(maxFixedMul(),maxFixedMul()+1) throws 
     * Test multiply(-maxFixedMul(),maxFixedMul()) equals -maxFixedMul() * maxFixedMul()
     * Test multiply(-maxFixedMul(),maxFixedMul()+1) throws 
     * Hardcoded to 24 digits.
     */
    function maxFixedMul() internal pure returns(int256) {
        return 240615969168004498257251713877715648331380787511296;
    }

    /**
     * @notice Maximum value that can be safely used as a dividend.
     * @dev divide(maxFixedDiv,newFixedFraction(1,fixed1())) = maxInt256().
     * Test maxFixedDiv() equals maxInt256()/fixed1()
     * Test divide(maxFixedDiv(),multiply(mulPrecision(),mulPrecision())) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,multiply(mulPrecision(),mulPrecision())) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDiv() internal pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as a divisor.
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() internal pure returns(int256) {
        return 1000000000000000000000000000000000000000000000000;
    }

    /**
     * @notice Converts an int256 to fixed point units, equivalent to multiplying
     * by 10^digits().
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(int256 x)
        internal
        pure
        returns (int256)
    {
        assert(x <= maxNewFixed());
        assert(x >= minNewFixed());
        return x * fixed1();
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(int256 x)
        internal
        pure
        returns (int256)
    {
        return x / fixed1();
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to a different fixed precision representation.
     * Both the origin and destination precisions must be 38 or less digits.
     * Origin values with a precision higher than the destination precision
     * will be truncated accordingly.
     * @dev 
     * Test convertFixed(1,0,0) returns 1;
     * Test convertFixed(1,1,1) returns 1;
     * Test convertFixed(1,1,0) returns 0;
     * Test convertFixed(1,0,1) returns 10;
     * Test convertFixed(10,1,0) returns 1;
     * Test convertFixed(10,0,1) returns 100;
     * Test convertFixed(100,1,0) returns 10;
     * Test convertFixed(100,0,1) returns 1000;
     * Test convertFixed(1000,2,0) returns 10;
     * Test convertFixed(1000,0,2) returns 100000;
     * Test convertFixed(1000,2,1) returns 100;
     * Test convertFixed(1000,1,2) returns 10000;
     * Test convertFixed(maxInt256,1,0) returns maxInt256/10;
     * Test convertFixed(maxInt256,0,1) throws
     * Test convertFixed(maxInt256,38,0) returns maxInt256/(10**38);
     * Test convertFixed(1,0,38) returns 10**38;
     * Test convertFixed(maxInt256,39,0) throws
     * Test convertFixed(1,0,39) throws
     */
    function convertFixed(int256 x, uint8 _originDigits, uint8 _destinationDigits)
        internal
        pure
        returns (int256)
    {
        assert(_originDigits <= 38 && _destinationDigits <= 38);
        
        uint8 decimalDifference;
        if ( _originDigits > _destinationDigits ){
            decimalDifference = _originDigits - _destinationDigits;
            return x/int256((uint128(10)**uint128(decimalDifference)));
        }
        else if ( _originDigits < _destinationDigits ){
            decimalDifference = _destinationDigits - _originDigits;
            // Cast uint8 -> uint128 is safe
            // Exponentiation is safe:
            //     _originDigits and _destinationDigits limited to 38 or less
            //     decimalDifference = abs(_destinationDigits - _originDigits)
            //     decimalDifference < 38
            //     10**38 < 2**128-1
            assert(x <= maxInt256()/int256(uint128(10)**uint128(decimalDifference)));
            assert(x >= minInt256()/int256(uint128(10)**uint128(decimalDifference)));
            return x*(int256(uint128(10)**uint128(decimalDifference)));
        }
        // _originDigits == digits()) 
        return x;
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to that of this library. The _originDigits parameter is the
     * precision of x. Values with a precision higher than FixidityLib.digits()
     * will be truncated accordingly.
     */
    function newFixed(int256 x, uint8 _originDigits)
        internal
        pure
        returns (int256)
    {
        return convertFixed(x, _originDigits, digits());
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a different representation. The _destinationDigits parameter is the
     * precision of the output x. Values with a precision below than 
     * FixidityLib.digits() will be truncated accordingly.
     */
    function fromFixed(int256 x, uint8 _destinationDigits)
        internal
        pure
        returns (int256)
    {
        return convertFixed(x, digits(), _destinationDigits);
    }

    /**
     * @notice Converts two int256 representing a fraction to fixed point units,
     * equivalent to multiplying dividend and divisor by 10^digits().
     * @dev 
     * Test newFixedFraction(maxFixedDiv()+1,1) fails
     * Test newFixedFraction(1,maxFixedDiv()+1) fails
     * Test newFixedFraction(1,0) fails     
     * Test newFixedFraction(0,1) returns 0
     * Test newFixedFraction(1,1) returns fixed1()
     * Test newFixedFraction(maxFixedDiv(),1) returns maxFixedDiv()*fixed1()
     * Test newFixedFraction(1,fixed1()) returns 1
     * Test newFixedFraction(1,fixed1()-1) returns 0
     */
    function newFixedFraction(
        int256 numerator, 
        int256 denominator
        )
        internal
        pure
        returns (int256)
    {
        assert(numerator <= maxNewFixed());
        assert(denominator <= maxNewFixed());
        assert(denominator != 0);
        int256 convertedNumerator = newFixed(numerator);
        int256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }

    /**
     * @notice Returns the integer part of a fixed point number.
     * @dev 
     * Test integer(0) returns 0
     * Test integer(fixed1()) returns fixed1()
     * Test integer(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test integer(-fixed1()) returns -fixed1()
     * Test integer(newFixed(-maxNewFixed())) returns -maxNewFixed()*fixed1()
     */
    function integer(int256 x) internal pure returns (int256) {
        return (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Returns the fractional part of a fixed point number. 
     * In the case of a negative number the fractional is also negative.
     * @dev 
     * Test fractional(0) returns 0
     * Test fractional(fixed1()) returns 0
     * Test fractional(fixed1()-1) returns 10^24-1
     * Test fractional(-fixed1()) returns 0
     * Test fractional(-fixed1()+1) returns -10^24-1
     */
    function fractional(int256 x) internal pure returns (int256) {
        return x - (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Converts to positive if negative.
     * Due to int256 having one more negative number than positive numbers 
     * abs(minInt256) reverts.
     * @dev 
     * Test abs(0) returns 0
     * Test abs(fixed1()) returns -fixed1()
     * Test abs(-fixed1()) returns fixed1()
     * Test abs(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test abs(newFixed(minNewFixed())) returns -minNewFixed()*fixed1()
     */
    function abs(int256 x) internal pure returns (int256) {
        if (x >= 0) {
            return x;
        } else {
            int256 result = -x;
            assert (result > 0);
            return result;
        }
    }

    /**
     * @notice x+y. If any operator is higher than maxFixedAdd() it 
     * might overflow.
     * In solidity maxInt256 + 1 = minInt256 and viceversa.
     * @dev 
     * Test add(maxFixedAdd(),maxFixedAdd()) returns maxInt256()-1
     * Test add(maxFixedAdd()+1,maxFixedAdd()+1) fails
     * Test add(-maxFixedSub(),-maxFixedSub()) returns minInt256()
     * Test add(-maxFixedSub()-1,-maxFixedSub()-1) fails
     * Test add(maxInt256(),maxInt256()) fails
     * Test add(minInt256(),minInt256()) fails
     */
    function add(int256 x, int256 y) internal pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(int256 x, int256 y) internal pure returns (int256) {
        return add(x,-y);
    }

    /**
     * @notice x*y. If any of the operators is higher than maxFixedMul() it 
     * might overflow.
     * @dev 
     * Test multiply(0,0) returns 0
     * Test multiply(maxFixedMul(),0) returns 0
     * Test multiply(0,maxFixedMul()) returns 0
     * Test multiply(maxFixedMul(),fixed1()) returns maxFixedMul()
     * Test multiply(fixed1(),maxFixedMul()) returns maxFixedMul()
     * Test all combinations of (2,-2), (2, 2.5), (2, -2.5) and (0.5, -0.5)
     * Test multiply(fixed1()/mulPrecision(),fixed1()*mulPrecision())
     * Test multiply(maxFixedMul()-1,maxFixedMul()) equals multiply(maxFixedMul(),maxFixedMul()-1)
     * Test multiply(maxFixedMul(),maxFixedMul()) returns maxInt256() // Probably not to the last digits
     * Test multiply(maxFixedMul()+1,maxFixedMul()) fails
     * Test multiply(maxFixedMul(),maxFixedMul()+1) fails
     */
    function multiply(int256 x, int256 y) internal pure returns (int256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        int256 x1 = integer(x) / fixed1();
        int256 x2 = fractional(x);
        int256 y1 = integer(y) / fixed1();
        int256 y2 = fractional(y);
        
        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        int256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1); // Overflow x1y1
        
        // x1y1 needs to be multiplied back by fixed1
        // solium-disable-next-line mixedcase
        int256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1()); // Overflow x1y1 * fixed1
        x1y1 = fixed_x1y1;

        int256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1); // Overflow x2y1

        int256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2); // Overflow x1y2

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        int256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2); // Overflow x2y2

        // result = fixed1() * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixed1();
        int256 result = x1y1;
        result = add(result, x2y1); // Add checks for overflow
        result = add(result, x1y2); // Add checks for overflow
        result = add(result, x2y2); // Add checks for overflow
        return result;
    }
    
    /**
     * @notice 1/x
     * @dev 
     * Test reciprocal(0) fails
     * Test reciprocal(fixed1()) returns fixed1()
     * Test reciprocal(fixed1()*fixed1()) returns 1 // Testing how the fractional is truncated
     * Test reciprocal(2*fixed1()*fixed1()) returns 0 // Testing how the fractional is truncated
     */
    function reciprocal(int256 x) internal pure returns (int256) {
        assert(x != 0);
        return (fixed1()*fixed1()) / x; // Can't overflow
    }

    /**
     * @notice x/y. If the dividend is higher than maxFixedDiv() it 
     * might overflow. You can use multiply(x,reciprocal(y)) instead.
     * There is a loss of precision on division for the lower mulPrecision() decimals.
     * @dev 
     * Test divide(fixed1(),0) fails
     * Test divide(maxFixedDiv(),1) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,1) throws
     * Test divide(maxFixedDiv(),maxFixedDiv()) returns fixed1()
     */
    function divide(int256 x, int256 y) internal pure returns (int256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

interface IFuelTank {
  function openNozzle() external;
  function addTokens(address user, uint amount) external;
}

contract MeowDAO is IERC20, Context {
  using FixidityLib for int256;

  uint256 _totalSupply = 0;
  string private _name;
  string private _symbol;

  uint8 private _decimals = 13;
  uint private _contractStart;

  address public grumpyAddress;
  address public grumpyFuelTankAddress;
  uint public swapEndTime;

  bool public launched = false;

  uint256 public totalStartingSupply = 10**10 * 10**13; //10_000_000_000.0_000_000_000_000 10 billion MEOWS. 10^23

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => uint) public periodStart;
  mapping (address => bool) public currentlyStaked;
  mapping (address => uint) public unlockStartTime;
  mapping (address => address) public currentVotes;
  mapping (address => uint256) public voteWeights;

  mapping (address => uint256) public stakingCoordinatesTime;
  mapping (address => uint256) public stakingCoordinatesAmount;

  mapping(address => uint256) public voteCounts;
  address[] public voteIterator;
  mapping(address => bool) public walletWasVotedFor;
  address public currentCharityWallet;

  constructor(address _grumpyAddress, address _grumpyFuelTankAddress, string memory __name, string memory __symbol) {
    _name = __name;
    _symbol = __symbol;

    _contractStart = block.timestamp;

    grumpyAddress = _grumpyAddress;
    grumpyFuelTankAddress = _grumpyFuelTankAddress;

    swapEndTime = block.timestamp + (86400 * 5);
  }

  function _swapGrumpyInternal(address user, uint256 amount) private {
    require(block.timestamp < swapEndTime);
    require(!isStaked(user), "cannot swap into staked wallet");
    
    IERC20(grumpyAddress).transferFrom(user, grumpyFuelTankAddress, amount);
    IFuelTank(grumpyFuelTankAddress).addTokens(user, amount);

    _balances[user] += amount;

    _totalSupply += amount;

    emit Transfer(address(0), user, amount);
  }

  function swapGrumpy(uint256 amount) public {
    _swapGrumpyInternal(_msgSender(), amount);
  }

  function initializeCoinThruster() external {
    require(block.timestamp >= swapEndTime, "NotReady");
    require(launched == false, "AlreadyLaunched");

    IFuelTank(grumpyFuelTankAddress).openNozzle();

    if (totalStartingSupply > _totalSupply) {
      uint256 remainingTokens = totalStartingSupply - _totalSupply;

      _balances[grumpyFuelTankAddress] = _balances[grumpyFuelTankAddress] + remainingTokens;
      _totalSupply += remainingTokens;

      emit Transfer(address(0), grumpyFuelTankAddress, remainingTokens);
    }

    launched = true;
  }

  function getBlockTime() public view returns (uint) {
    return block.timestamp;
  }

  function isStaked(address wallet) public view returns (bool) {
    return currentlyStaked[wallet];
  }

  function isUnlocked(address wallet) private returns (bool) {
    uint unlockStarted = unlockStartTime[wallet];

    if (unlockStarted == 0) return true;

    uint unlockedAt = unlockStarted + (86400 * 5);

    if (block.timestamp > unlockedAt) {
      unlockStartTime[wallet] = 0;
      return true;
    }
    else return false;
  }

  function _stakeWalletFor(address sender) private returns (bool) {
    require(!isStaked(sender));
    require(enoughFundsToStake(sender), "InsfcntFnds");
    require(isUnlocked(sender), "WalletIsLocked");

    currentlyStaked[sender] = true;
    unlockStartTime[sender] = 0;
    currentVotes[sender] = address(0);
    periodStart[sender] = block.timestamp;

    stakingCoordinatesTime[sender] = block.timestamp;
    stakingCoordinatesAmount[sender] = _balances[sender];

    return true;
  }

  function stakeWallet() public returns (bool) {
    return _stakeWalletFor(_msgSender());
  }

  function _unstakeWalletFor(address sender, bool shouldReify) private {
    require(isStaked(sender));

    if (shouldReify) reifyYield(sender);

    if (voteWeights[sender] != 0) {
      removeVoteWeight(sender);
      updateCharityWallet();
    }

    currentlyStaked[sender] = false;
    currentVotes[sender] = address(0);
    voteWeights[sender] = 0;
    periodStart[sender] = 0;

    stakingCoordinatesTime[sender] = 0;
    stakingCoordinatesAmount[sender] = 0;

    unlockStartTime[sender] = block.timestamp;
  } 

  function unstakeWallet() public {
    _unstakeWalletFor(_msgSender(), true);
  }

  function unstakeWalletSansReify() public {
    _unstakeWalletFor(_msgSender(), false);
  }

  function voteIteratorLength() external view returns (uint) {
    return voteIterator.length;
  }

  function voteWithRebuildIfNecessary(address charityWalletVote) public {
    if (voteIterator.length == 12 && !walletWasVotedFor[charityWalletVote]) {
      rebuildVotingIterator();
    }
    _voteForAddressBy(charityWalletVote, _msgSender());
  }

  function rebuildVotingIterator() public {
    require(voteIterator.length == 12, "Voting Iterator not full");

    address[12] memory voteCopy;
    for (uint i = 0; i < 12; i++) {
      voteCopy[i] = voteIterator[i];
    }

    //insertion sort copy
    for (uint i = 1; i < 12; i++)
    {
      address keyAddress = voteCopy[i];
      uint key = voteCounts[keyAddress];

      uint j = i - 1;

      bool broke = false;
      while (j >= 0 && voteCounts[voteCopy[j]] < key) {
        voteCopy[j + 1] = voteCopy[j];

        if (j == 0) {
          broke = true;
          break;
        }
        else j--;
      }

      if (broke) voteCopy[0] = keyAddress;
      else voteCopy[j + 1] = keyAddress;
    }

    for (uint i = 11; i >= 6; i--) {
      address vote = voteCopy[i];
      walletWasVotedFor[vote] = false;
    }

    delete voteIterator;
    for (uint i = 0; i < 6; i++) {
      voteIterator.push(voteCopy[i]);
    }

  }

  function _voteForAddressBy(address charityWalletVote, address sender) private {
    require(isStaked(sender));

    trackCandidate(charityWalletVote);

    removeVoteWeight(sender);
    setVoteWeight(sender);
    addVoteWeight(sender, charityWalletVote);
    updateCharityWallet();
  }

  function trackCandidate(address charityWalletCandidate) private {
    // If wallet was never voted for before add it to voteIterator
    if (!walletWasVotedFor[charityWalletCandidate]) {
      require(voteIterator.length < 12, "Vote Iterator must be rebuilt");

      voteIterator.push(charityWalletCandidate);
      walletWasVotedFor[charityWalletCandidate] = true;
    }
  }

  function removeVoteWeight(address sender) private {
    address vote = currentVotes[sender];
    voteCounts[vote] = voteCounts[vote] - voteWeights[sender];
  }

  function setVoteWeight(address sender) private {
    uint256 newVoteWeight = _balances[sender];
    voteWeights[sender] = newVoteWeight;
  }

  function addVoteWeight(address sender, address charityWalletVote) private {
    voteCounts[charityWalletVote] = voteCounts[charityWalletVote] + voteWeights[sender];
    currentVotes[sender] = charityWalletVote;
  }

  function voteForAddress(address charityWalletVote) public {
    _voteForAddressBy(charityWalletVote, _msgSender());
  }

  event NewCharityWallet(address oldW, address newW);

  function updateCharityWallet() private {
    uint256 maxVoteValue = 0; 
    address winner = address(0);

    for (uint i = 0; i < voteIterator.length; i++) {
      address currentWallet = voteIterator[i];
      uint256 voteValue = voteCounts[currentWallet];

      if (voteValue > maxVoteValue) {
        maxVoteValue = voteValue;
        winner = currentWallet;
      }
    }

    if (currentCharityWallet == winner) return;

    emit NewCharityWallet(currentCharityWallet, winner);

    currentCharityWallet = winner;
  }

  function validCharityWallet() internal view returns (bool) {
    return currentCharityWallet != address(0) && !isStaked(currentCharityWallet);
  }

  function getCompoundingFactor(address wallet) private view returns (uint) {
    return block.timestamp - periodStart[wallet];
  }

  function calculateYield(uint256 principal, uint n) public pure returns (uint256) {
    int256 fixedPrincipal = int256(principal).newFixed();

    int256 rate = int256(2144017221509).newFixedFraction(1000000000000000000000);
    int256 fixed2 = int256(2).newFixed();

    while (n > 0) {
      if (n % 2 == 1) {
        fixedPrincipal = fixedPrincipal.add(fixedPrincipal.multiply(rate));
        n -= 1;
      }
      else {
        rate = (fixed2.multiply(rate))
          .add(rate.multiply(rate));
        n /= 2;
      }
    }
    return uint256(fixedPrincipal.fromFixed()) - principal;
  }

  function getTransactionFee(uint256 txAmt) private view returns (uint256){
    uint period = block.timestamp - _contractStart;

    if (period > 31536000) return 0;
    else if (period > 23652000) return txAmt / 400;
    else if (period > 15768000) return txAmt / 200;
    else if (period > 7884000) return (txAmt / 400) * 3;
    else return txAmt / 100;
  } 

  function reifyYield(address wallet) public {
    require(isStaked(wallet), 'MstBeStkd');

    uint compoundingFactor = getCompoundingFactor(wallet);

    if (compoundingFactor < 60) return;

    uint256 yield = calculateYield(_balances[wallet], compoundingFactor);

    _balances[wallet] += yield;

    if (validCharityWallet()) {
      uint256 charityYield = (yield / 7) * 3;
      _balances[currentCharityWallet] += charityYield;
      _totalSupply += (yield + charityYield);
    } else {
      _totalSupply += yield;
    }

    periodStart[wallet] = block.timestamp;
  }

  function enoughFundsToStake(address wallet) private view returns (bool) {
    return _balances[wallet] >= 10000000000000000;
  }

  function name() external view returns (string memory) {
    return _name;
  } 

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function contractStart() external view returns (uint) {
    return _contractStart;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    uint b = _balances[account];

    if (isStaked(account) && currentCharityWallet != account) {
      return b + calculateYield(b, getCompoundingFactor(account));
    }
    return b;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(!isStaked(sender), "StkdWlltCnntTrnsf");
    require(isUnlocked(sender), "LockedWlltCnntTrnsfr");
    require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

    if (isStaked(recipient)) {
      reifyYield(recipient);
    }

    uint sentAmount = amount; 

    if (validCharityWallet()) {
      uint256 txFee = getTransactionFee(amount);

      if (txFee != 0) {
        sentAmount -= txFee;
        _balances[currentCharityWallet] += txFee;
      }
    }

    _balances[sender] -= amount;
    _balances[recipient] += sentAmount;

    emit Transfer(sender, recipient, amount);
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    return true;
  }
}
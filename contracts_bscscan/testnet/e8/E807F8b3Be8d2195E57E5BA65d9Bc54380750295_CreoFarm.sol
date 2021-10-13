pragma solidity 0.6.5;

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
    function digits() public pure returns(uint8) {
        return 24;
    }
    
    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 10^digits()
     * Hardcoded to 24 digits.
     */
    function fixed1() public pure returns(int256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() public pure returns(int256) {
        return 1000000000000;
    }

    /**
     * @notice Maximum value that can be represented in an int256
     * @dev Test maxInt256() equals 2^255 -1
     */
    function maxInt256() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * @notice Minimum value that can be represented in an int256
     * @dev Test minInt256 equals (2^255) * (-1)
     */
    function minInt256() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * @dev deployment. 
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * deployment. 
     * @dev Test minNewFixed() equals -(maxInt256()) / fixed1()
     * Hardcoded to 24 digits.
     */
    function minNewFixed() public pure returns(int256) {
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
    function maxFixedAdd() public pure returns(int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * @notice Maximum negative value that can be safely in a subtraction.
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() public pure returns(int256) {
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
    function maxFixedMul() public pure returns(int256) {
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
    function maxFixedDiv() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as a divisor.
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() public pure returns(int256) {
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
        public
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
        public
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
        public
        pure
        returns (int256)
    {
        assert(_originDigits <= 38 && _destinationDigits <= 38);
        
        uint8 decimalDifference;
        if ( _originDigits > _destinationDigits ){
            decimalDifference = _originDigits - _destinationDigits;
            return x/(uint128(10)**uint128(decimalDifference));
        }
        else if ( _originDigits < _destinationDigits ){
            decimalDifference = _destinationDigits - _originDigits;
            // Cast uint8 -> uint128 is safe
            // Exponentiation is safe:
            //     _originDigits and _destinationDigits limited to 38 or less
            //     decimalDifference = abs(_destinationDigits - _originDigits)
            //     decimalDifference < 38
            //     10**38 < 2**128-1
            assert(x <= maxInt256()/uint128(10)**uint128(decimalDifference));
            assert(x >= minInt256()/uint128(10)**uint128(decimalDifference));
            return x*(uint128(10)**uint128(decimalDifference));
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
        public
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
        public
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
        public
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
    function integer(int256 x) public pure returns (int256) {
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
    function fractional(int256 x) public pure returns (int256) {
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
    function abs(int256 x) public pure returns (int256) {
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
    function add(int256 x, int256 y) public pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(int256 x, int256 y) public pure returns (int256) {
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
    function multiply(int256 x, int256 y) public pure returns (int256) {
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
    function reciprocal(int256 x) public pure returns (int256) {
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
    function divide(int256 x, int256 y) public pure returns (int256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        _transferOwnership(newOwner);
        }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}
/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
contract CreoFarm is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public rewardBalance;

    string public name = "CREO_FARM: CREO-LP";
    bool public farmActive;
    uint256 public totalLocked;
    uint256 public APR;
    uint256 public unclaimedRewards;
    uint256 public claimedRewards;

    IBEP20 public creoToken;
    // IBEP20 public creoLpToken;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    constructor(
        IBEP20 _creoToken
        // IBEP20 _creoLpToken
        ) public {
            creoToken = _creoToken;
            // creoLpToken = _creoLpToken;
        }

    function farmBalance() public view returns(uint256) {
        uint256 deduct = totalLocked.add(unclaimedRewards);
        uint256 bal = creoToken.balanceOf(address(this)).sub(deduct);
        return bal;
    }


    function setActiveStatus(bool active) onlyOwner public virtual returns (bool) {
        farmActive = active;
        return true;
    }

    function stake(uint256 amount) public {
        require(farmActive == true, 'CreoFarm: Pool not active');
        require(
            amount > 0 &&
            creoToken.balanceOf(_msgSender()) >= amount, 
            "CreoFarm: You cannot stake zero tokens");

        if(isStaking[_msgSender()] == true){
            uint256 toTransfer = _calculateYieldTotal(_msgSender());
            rewardBalance[_msgSender()] = rewardBalance[_msgSender()].add(toTransfer);
            unclaimedRewards  = unclaimedRewards.add(toTransfer);   
        }
        creoToken.safeTransferFrom(_msgSender(), address(this), amount);
        totalLocked = totalLocked.add(amount);
        stakingBalance[_msgSender()] = stakingBalance[_msgSender()].add(amount);
        startTime[_msgSender()] = now;
        isStaking[_msgSender()] = true;
        APR = _calculateApr();
        emit Stake(_msgSender(), amount);
    }

    function unstake(uint256 amount) public {
        require(
            isStaking[_msgSender()] = true &&
            stakingBalance[_msgSender()] >= amount, 
            "Nothing to unstake"
        );
        uint256 yieldTransfer = _calculateYieldTotal(_msgSender());
        startTime[_msgSender()] = now;
        uint256 balTransfer = amount;
        // re-entrancy gaurd
        amount = 0;
        stakingBalance[_msgSender()] = stakingBalance[_msgSender()].sub(balTransfer);
        creoToken.safeTransfer(_msgSender(), balTransfer);
        totalLocked = totalLocked.sub(balTransfer);
        rewardBalance[_msgSender()] = rewardBalance[_msgSender()].add(yieldTransfer);
        unclaimedRewards  = unclaimedRewards.add(yieldTransfer);  
        if(stakingBalance[_msgSender()] == 0){
            isStaking[_msgSender()] = false;
        }
        emit Unstake(_msgSender(), balTransfer);
    }

    function _calculateApr() private view returns(uint256){
        uint256 bal = farmBalance();
        uint locked = totalLocked;
        uint256 _apr = bal.mul(10**18).div(locked).mul(2600);
        return _apr;
    }

    function _calculateYieldTime(address user) private view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end.sub(startTime[user]);
        return totalTime;
    }

    function _calculateYieldTotal(address user) private view returns(uint256) {
        uint256 time = 604800;
        // reward is calculated daily!
        uint256 rate = 86400;
        uint256 daysStaked = time.div(rate);
        uint256 apr = _calculateApr();    
        uint256 dailyInterest = apr.div(364).div(100); 
        uint256 yield = stakingBalance[user].mul(dailyInterest).mul(daysStaked).div(10**18);
        return yield;
    } 
   
    

    function withdrawYield() public {
        uint256 toTransfer = rewardBalance[_msgSender()];
        rewardBalance[_msgSender()] = 0;
        require(
            toTransfer > 0 ||
            stakingBalance[_msgSender()] > 0,
            "CreoFarm: No rewards to withdraw"
            );
            
        if(stakingBalance[_msgSender()] != 0){
            uint256 currYield = _calculateYieldTotal(_msgSender());
            toTransfer = toTransfer.add(currYield);
            startTime[_msgSender()] = now;
        }
        creoToken.safeTransfer(_msgSender(), toTransfer);
        claimedRewards = claimedRewards.add(toTransfer);
        emit YieldWithdraw(_msgSender(), toTransfer);
    } 
}
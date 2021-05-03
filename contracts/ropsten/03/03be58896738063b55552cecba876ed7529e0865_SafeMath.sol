/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

library SafeMath {
// Returns the addition of two unsigned integers, revert if overflow.
//  Requirements: Addition cannot overflow.
	function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
// Returns the subtraction of two unsigned integers, revert if overflow (when the result is negative).
// Requirements: Subtraction cannot overflow.
	function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
// Returns the multiplication of two unsigned integers, reverting on overflow.
// Requirements: Multiplication cannot overflow.
	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
// Returns the integer division of two unsigned integers, reverts if diving by zero. The result is rounded towards zero.
// Requirements: The divisor cannot be zero.
/* this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}
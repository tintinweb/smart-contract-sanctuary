/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
   

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
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
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Sale is Owned{
    using SafeMath for uint256;
    uint256 saleStart;
    address OCTO = 0x8caDe0C5Bb68c1c1F56aF9A2EFAD10EabF2e3B59;
    address BUSDADD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    struct userInfo{
        uint256 perMonth;
        uint256 lastClaim;
        uint256 totalPurchased;
    }
    mapping(address => userInfo) public users;
    
    uint256 public rate = 285714285714286000000; // tokens per BUSD
    uint256 salePeriod = 72 hours;
   
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        saleStart = block.timestamp;
        owner = payable(0x83FE4961A1C263C2325e9235A156d5e36cB1CE2E);
    }
   
    function buyOCTO(uint256 BUSD) external returns(uint256){
        require(block.timestamp < saleStart.add(salePeriod), "Sale ended");
        require( (BUSD <= 2500 ether) && (BUSD >= 50 ether), "Investment should be greater than eq to 50 and less than eq to 2500BUSD");
        
        uint256 purchasedTokens = cal_coin(BUSD);
        users[msg.sender].totalPurchased = users[msg.sender].totalPurchased.add(onePercent(purchasedTokens).mul(75));
        users[msg.sender].perMonth = users[msg.sender].perMonth.add(purchasedTokens.div(4));
        
        require(IERC20(BUSDADD).transferFrom(msg.sender, owner, BUSD));
        require(IERC20(OCTO).transfer(msg.sender, purchasedTokens.div(4)));
        return purchasedTokens;
    }  
   
    function claimOCTO() external returns(uint256){
        require(users[msg.sender].lastClaim <= users[msg.sender].totalPurchased, "No claimable tokens available");
        require(block.timestamp > saleStart.add(salePeriod), "Wait for sale to end");
        uint256 timePassed = (block.timestamp.sub(saleStart.add(salePeriod))).div(30 days);
        uint256 calAmount = users[msg.sender].perMonth.mul(timePassed);
        require(timePassed >= 1, "first release will be after a month");
        if ( timePassed <= 3 ){
            calAmount = users[msg.sender].perMonth.mul(timePassed);
        }
        else{
            calAmount = users[msg.sender].perMonth.mul(3);
        }
        
        calAmount = calAmount.sub(users[msg.sender].lastClaim);
        
        require(calAmount > 0, "No claimable tokens available");
        
        require(IERC20(OCTO).transfer(msg.sender, calAmount));
        users[msg.sender].lastClaim = users[msg.sender].lastClaim.add(calAmount);
        return calAmount;
    }
       
    function cal_coin(uint256 BUSD) public view returns(uint256){
        return (BUSD.mul(rate)).div(10**9);
    }
    
    function getUnSoldTokens(uint256 amount) external onlyOwner{
        require(block.timestamp > saleStart.add(salePeriod), "Wait for sale to end");
        require(IERC20(OCTO).transfer(msg.sender, amount), "Error sending tokens");
    }
   
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) public pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}
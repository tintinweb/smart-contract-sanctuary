/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity >=0.7.0 <0.9.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IBnbminer {
    function hatchEggs(address ref) external;
    function sellEggs() external;
    function buyEggs(address ref) external payable;
    function getMyEggs() external view returns(uint256);
    function calculateEggBuy(uint256 bnb, uint256 contractBalance) external view returns (uint256);
}

contract Autominer {
    using SafeMath for uint256;
    
    address constant feeCollector = address(0x0000002E7aF4ddA4eFFFc7229400C578A9f34d00);
    
    IBnbminer constant bnbMiner = IBnbminer(0xce93F9827813761665CE348e33768Cb1875a9704);
    
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 eggsAtLastUserAction; // keeps track of cake deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }
    
    mapping(address => UserInfo) public userInfo;
    
    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    uint256 public investedBNB;
    uint256 public totalTimesDeposited = 0;
    uint256 public totalTimesWithdrawn = 0;
    
    uint256 public constant withdrawalFee = 100; // 1%
    
    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Compound(address indexed sender);
    
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }
    
    function deposit() external payable notContract {
        require(msg.value > 0, "Nothing to deposit");
        
        investedBNB = investedBNB.add(msg.value);
        
        uint256 eggsBought = bnbMiner.calculateEggBuy(msg.value, address(bnbMiner).balance);
        uint256 currentShares = 0;
        uint256 pool = bnbMiner.getMyEggs();
        
        if (totalShares == 0) {
            currentShares = eggsBought;
        } else {
            currentShares = eggsBought.mul(totalShares).div(pool);
        }
        
        UserInfo storage user = userInfo[msg.sender];
        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;
        
        totalShares = totalShares.add(currentShares);
        
        user.eggsAtLastUserAction = user.shares.mul(pool).div(totalShares);
        user.lastUserActionTime = block.timestamp;
        
        bnbMiner.buyEggs{value:msg.value}(feeCollector);
        
        _earn();
        
        emit Deposit(msg.sender, msg.value, currentShares, block.timestamp);
        totalTimesDeposited = totalTimesDeposited.add(1);
    }
    
    function getShares(address user) external view returns (uint256) {
        return userInfo[user].shares;
    }
    
    function withdraw(uint256 _shares) external notContract {
        require(_shares > 0, "Nothing to withdraw");
        UserInfo storage user = userInfo[msg.sender];
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        
        bnbMiner.sellEggs();
        uint256 balance = address(this).balance;
        
        uint256 userBNB = (balance.mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);
        
        if (balance.sub(userBNB) < investedBNB.sub(userBNB) && userBNB < balance) { // if this withdrawal causes the vault to lose value, apply a 1% fee to the withdrawal
            userBNB = userBNB.sub(userBNB.mul(withdrawalFee).div(10000));
        }
        
        if (user.shares > 0) {
            user.eggsAtLastUserAction = user.shares.mul(bnbMiner.getMyEggs()).div(totalShares);
        } else {
            user.eggsAtLastUserAction = 0;
        }
        
        user.lastUserActionTime = block.timestamp;
        
        investedBNB = investedBNB.sub(userBNB);
        
        payable(msg.sender).transfer(userBNB);
        
        emit Withdraw(msg.sender, userBNB, _shares);
        totalTimesWithdrawn = totalTimesWithdrawn.add(1);
        
        balance = address(this).balance;
        if (balance > 0) {
            bnbMiner.buyEggs{value:address(this).balance}(feeCollector);
        }
    }
    
    function _earn() internal {
        if (totalTimesDeposited > 0) {
            bnbMiner.hatchEggs(feeCollector);
        }
    }
    
    function compound() external {
        _earn();
        emit Compound(msg.sender);
    }
}
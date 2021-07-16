//SourceUnit: wowhelp.sol

pragma solidity 0.5.10;

contract WOWHELP {
	using SafeMath for uint256;

	uint256 constant public REFER_BONUS = 250;
    uint256 constant public MATCHING_BONUS = 500;
    uint256 constant public LEVEL1_BONUS = 80;
    uint256 constant public LEVEL2_BONUS = 60;
    uint256 constant public LEVEL3_BONUS = 50;
    uint256 constant public LEVEL4_BONUS = 40;
    uint256 constant public LEVEL5_BONUS = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalDeposits;
	
	struct Deposit {
		uint256 amount;
	}

	struct User {
		Deposit[] deposits;
		address referrer;
		uint256 bonus;
	}

	mapping (address => User) internal users;

	event NewDeposit(address indexed user, uint256 amount);

	function invest(address payable referrer, address payable matching, address payable level1, address payable level2, address payable level3, address payable level4, address payable level5) public payable {

		User storage user = users[msg.sender];

		referrer.transfer(msg.value.mul(REFER_BONUS).div(PERCENTS_DIVIDER));
        matching.transfer(msg.value.mul(MATCHING_BONUS).div(PERCENTS_DIVIDER));
        level1.transfer(msg.value.mul(LEVEL1_BONUS).div(PERCENTS_DIVIDER));
        level2.transfer(msg.value.mul(LEVEL2_BONUS).div(PERCENTS_DIVIDER));
        level3.transfer(msg.value.mul(LEVEL3_BONUS).div(PERCENTS_DIVIDER));
        level4.transfer(msg.value.mul(LEVEL4_BONUS).div(PERCENTS_DIVIDER));
        level5.transfer(msg.value.mul(LEVEL5_BONUS).div(PERCENTS_DIVIDER));
		
		emit NewDeposit(msg.sender, msg.value);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

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
}
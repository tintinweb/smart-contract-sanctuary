//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



import "./IERC20.sol";
import "./SafeMath.sol";

contract FactoryMigrationHelper {

	uint256 public normalMigrationFee = 0;
	address public owner;

	modifier onlyOwner(){
		require(msg.sender == owner, "You are not the owner");
		_;
	}

	event RescueBNB(address indexed account, uint256 amount);

	event NewMigration(address indexed address_);

	event TokenDeposited(address indexed address_, uint256 amount);

	address[] public migrations;

	constructor()  {
		owner = msg.sender;
	}

	function setMigrationFee(uint256 _normalMigrationFee) public onlyOwner {
		normalMigrationFee = _normalMigrationFee;
	}

	// Claim BNB from the contract
	function rescueBNB() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(address(this).balance);
		emit RescueBNB(msg.sender, balance);
	}


	function createNewMigration(string memory title, IERC20 oldTokenAddress, IERC20 newTokenAddress, 
		uint256 decimalsOldToken, uint256 decimalsNewToken, uint256 divider) public payable {
		require(msg.value > normalMigrationFee, "You need to pay the fee to start the migration!");
		address newMigration = address(new MigrationHelper(address(this), title, oldTokenAddress, newTokenAddress,
		decimalsOldToken, decimalsNewToken, divider));
		migrations.push(newMigration);

		emit NewMigration(newMigration);
	}

	function getMigrations() public view returns (address[] memory) {
		return migrations;
	}

	function sendTokenToContract(uint256 amount, uint256 migrationId) public onlyOwner{
    require(migrations.length > migrationId, "Migration id is out of index!");
		MigrationHelper hc = MigrationHelper(migrations[migrationId]);
		hc.sendNewTokensToContract(amount);
		emit TokenDeposited(msg.sender, amount);
	}

	function claimToken(uint256 migrationId) public {
    require(migrations.length > migrationId, "Migration id is out of index!");
		MigrationHelper hc = MigrationHelper(migrations[migrationId]);
		hc.claim();
	}
}

contract MigrationHelper {

	using SafeMath for uint256;

	address owner;
	string title;
	IERC20 oldTokenAddress;
	IERC20 newTokenAddress;

	uint256 decimalsOldToken;
	uint256 decimalsNewToken;

	uint256 operationalDecimals = 18;

	uint256 divider;
	// uint256 tokensForDistribution;

	uint256 newAmountToReceive;
	uint256 oldAmount;

	mapping(address => uint256) received;

	event Claim(address indexed address_, uint256 amount);

	constructor(
    address _owner,
    string memory  _title,
    IERC20 _oldTokenAddress,
    IERC20 _newTokenAddress,
	  uint256 _decimalsOldToken,
    uint256 _decimalsNewToken,
    uint256 _divider
    // uint256 _tokensForDistribution
  ) {
		owner = _owner;
		title = _title;
		oldTokenAddress = _oldTokenAddress;
		newTokenAddress = _newTokenAddress;
		decimalsOldToken = _decimalsOldToken;
		decimalsNewToken = _decimalsNewToken;
		divider = _divider;
		// tokensForDistribution = _tokensForDistribution.div(10**decimalsNewToken).mul(10**operationalDecimals);
	}

	modifier onlyOwner(){
		require(msg.sender == owner, "You are not the owner");
		_;
	}
	
	function sendNewTokensToContract(uint256 _amount) public onlyOwner(){
		// Allow the contract
		newTokenAddress.approve(address(this), _amount.div(10**decimalsNewToken).mul(10**operationalDecimals));

		// Transfer the tokens from msg.sender to the contract
		newTokenAddress.transferFrom(msg.sender, address(this), _amount.div(10**decimalsNewToken).mul(10**operationalDecimals));
	}

	function claim() public {
		require(received[msg.sender] == 0, "You already received your tokens");
    require(oldTokenAddress.balanceOf(msg.sender) > 0, "You don't have old token");
    uint256 amountToReceive = newAmountToReceive.div(10**decimalsNewToken).mul(10**operationalDecimals);

    setNewAmountToReceive(msg.sender);
    newTokenAddress.approve(address(this), amountToReceive);
    newTokenAddress.transferFrom(address(this), msg.sender, newAmountToReceive);

    received[msg.sender] = amountToReceive;

    emit Claim(msg.sender, amountToReceive);
	}

	function setNewAmountToReceive(address _receiver) private {
		newAmountToReceive = oldTokenAddress.balanceOf(_receiver).div(10**decimalsOldToken).mul(10**decimalsNewToken).div(divider);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
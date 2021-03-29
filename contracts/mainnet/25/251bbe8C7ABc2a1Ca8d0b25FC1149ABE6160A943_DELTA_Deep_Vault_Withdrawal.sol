// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
import "../../../../interfaces/IDeltaToken.sol";
import "../../../../interfaces/IDeltaDistributor.sol";
import "../../../libs/SafeMath.sol";

contract DELTA_Deep_Vault_Withdrawal {
    // masterCopy always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;
    uint256 private ______gap;
    using SafeMath for uint256;

    /// @notice The person who owns this withdrawal and can withdraw at any moment
    address public OWNER;
    /// @notice Seconds it takes to mature anything above the principle
    uint256 public MATURATION_TIME_SECONDS;
    /// @notice Principle DELTA which is the withdrawable amount without maturation
    /// Because we just mature stuff thats above claim
    uint256 public PRINCIPLE_DELTA;
    uint256 public VESTING_DELTA;
    bool public everythingWithdrawed;
    bool public principleWithdrawed;
    bool public emergency;

    // Those variables are private and only gotten with getters, to not shit up the etherscan page
    /// @dev address of the delta token
    IDeltaToken private DELTA_TOKEN;
    /// @dev address of the rlp token
    /// @dev the block timestamp at the moment of calling the constructor
    uint256 private CONSTRUCTION_TIME;

    constructor () {
        // Renders the master copy unusable
        // Proxy does not call the constructor
        OWNER = address(0x1);
    }

    function intitialize (
        address _owner,
        uint256 _matuartionTimeSeconds,
        uint256 _principledDelta, // Principle means the base amount that doesnt mature.
        IDeltaToken delta
    ) public {
        require(OWNER == address(0), "Already initialized");
        require(_owner != address(0), "Owner cannot be 0");
        require(_matuartionTimeSeconds > 0, "Maturation period is nessesary");

        DELTA_TOKEN = delta;
        OWNER = _owner;

        uint256 deltaBalance = delta.balanceOf(address(this));
        require(deltaBalance >= _principledDelta, "Did not get enough DELTA");
        VESTING_DELTA = deltaBalance - _principledDelta;
        MATURATION_TIME_SECONDS = _matuartionTimeSeconds; 

        PRINCIPLE_DELTA = _principledDelta;
        CONSTRUCTION_TIME = block.timestamp;
    } 

    function deltaDistributor() public view returns(IDeltaDistributor distributor) {
        distributor = IDeltaDistributor(DELTA_TOKEN.distributor());
        require(address(distributor) != address(0), "Distributor is not set");
    }

    function secondsLeftToMature() public view returns (uint256) {
        uint256 targetTime = CONSTRUCTION_TIME + MATURATION_TIME_SECONDS;
        if(block.timestamp > targetTime) { return 0; }
        return targetTime - block.timestamp;
    }

    function secondsLeftUntilPrincipleUnlocked() public view returns (uint256) {
        uint256 targetTime = CONSTRUCTION_TIME + 14 days;
        if(block.timestamp > targetTime) { return 0; }
        return targetTime - block.timestamp;
    }

    function onlyOwner() internal view {
        require(msg.sender == OWNER, "You are not the owner of this withdrawal contract");
    }

    // Allows the owner of this contract to grant permission to delta governance to withdraw 
    function toggleEmergency(bool isInEmergency) public {
        onlyOwner();
        emergency = isInEmergency;
    }

    function withdrawTokensWithPermissionFromOwner(address token, address recipent, uint256 amount) public {
        require(msg.sender == DELTA_TOKEN.governance()); // Only delta governance can call this
        require(emergency); // Checks the owner activated emergency
        IERC20(token).transfer(recipent, amount);
    }

    function withdrawPrinciple() public {
        onlyOwner();
        require(!principleWithdrawed, "Principle was already withdrawed");
        require(block.timestamp > CONSTRUCTION_TIME + 14 days, "You need to wait 14 days to withdraw principle");
        // Send the principle
        DELTA_TOKEN.transfer(msg.sender, PRINCIPLE_DELTA);

        principleWithdrawed = true;
    }

    /// @notice this will check the matured tokens and remove the balance that isnt matured back to the deep farming vault to pickup spread across all farmers
    function withdrawEverythingWithdrawable() public {
        onlyOwner();
        require(!everythingWithdrawed, "Already withdrawed");
        uint256 deltaDue = withdrawableTokens();
        // deltaDue has to be above becase it checks if principle was withdrawed. 
        // This fixes a bug where principle tokens were potentially burned
        if(!principleWithdrawed && PRINCIPLE_DELTA > 0) {
            require(block.timestamp > CONSTRUCTION_TIME + 14 days, "You need to wait 14 days to withdraw principle");
            principleWithdrawed = true;
        }

        DELTA_TOKEN.transfer(msg.sender, deltaDue);
        uint256 leftOver = DELTA_TOKEN.balanceOf(address(this));

        IDeltaDistributor distributor = deltaDistributor();//Reverts if its not set.

        if(leftOver > 0) { 
            DELTA_TOKEN.approve(address(distributor), leftOver);
            distributor.addDevested(msg.sender, leftOver);
        }
        everythingWithdrawed = true;
    }

    function withdrawableTokens() public view returns (uint256) {
        if(!principleWithdrawed) { // Principle was not extracted
            return maturedVestingTokens().add(PRINCIPLE_DELTA);
        } else {
            return maturedVestingTokens();
        }
    }

    function maturedVestingTokens() public view returns (uint256) {
        return VESTING_DELTA.mul(percentMatured()) / 100;
    }

    function percentMatured() public view returns (uint256) {
        // This function can happen only once and is irreversible
        // So we get the maturation here
        uint256 secondsToMaturity = secondsLeftToMature();
        uint256 percentMaturation =  100 - (((secondsToMaturity * 1e8) / MATURATION_TIME_SECONDS) / 1e6);
        /// 1000 seconds left to mature 
        /// Maturing time 10,000
        /// 1000 * 1e8 = 100000000000
        /// 100000000000/10,000 = 10000000
        /// we are left with float 0.1 percentage, which we would have to *100, so we divide by 1e6 to multiply by 100
        /// With 0 its 100 - 0

        /// @dev we mature 5% immidietly 
        if(percentMaturation < 5) {
            percentMaturation = 5;
        }

        return percentMaturation;
    }

    receive() external payable {
        revert("ETH not allowed");
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "../common/OVLTokenTypes.sol";

interface IDeltaToken is IERC20 {
    function vestingTransactions(address, uint256) external view returns (VestingTransaction memory);
    function getUserInfo(address) external view returns (UserInformationLite memory);
    function getMatureBalance(address, uint256) external view returns (uint256);
    function liquidityRebasingPermitted() external view returns (bool);
    function lpTokensInPair() external view returns (uint256);
    function governance() external view returns (address);
    function performLiquidityRebasing() external;
    function distributor() external view returns (address);
    function totalsForWallet(address ) external view returns (WalletTotals memory totals);
    function adjustBalanceOfNoVestingAccount(address, uint256,bool) external;
    function userInformation(address user) external view returns (UserInformation memory);

}

pragma solidity ^0.7.6;

interface IDeltaDistributor {
    function creditUser(address,uint256) external;
    function addDevested(address, uint256) external;
    function distribute() external;
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

// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY

pragma solidity ^0.7.6;

struct VestingTransaction {
    uint256 amount;
    uint256 fullVestingTimestamp;
}

struct WalletTotals {
    uint256 mature;
    uint256 immature;
    uint256 total;
}

struct UserInformation {
    // This is going to be read from only [0]
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
    uint256 maturedBalance;
    uint256 maxBalance;
    bool fullSenderWhitelisted;
    // Note that recieving immature balances doesnt mean they recieve them fully vested just that senders can do it
    bool immatureReceiverWhitelisted;
    bool noVestingWhitelisted;
}

struct UserInformationLite {
    uint256 maturedBalance;
    uint256 maxBalance;
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
}

struct VestingTransactionDetailed {
    uint256 amount;
    uint256 fullVestingTimestamp;
    // uint256 percentVestedE4;
    uint256 mature;
    uint256 immature;
}


uint256 constant QTY_EPOCHS = 7;

uint256 constant SECONDS_PER_EPOCH = 172800; // About 2days

uint256 constant FULL_EPOCH_TIME = SECONDS_PER_EPOCH * QTY_EPOCHS;

// Precision Multiplier -- this many zeros (23) seems to get all the precision needed for all 18 decimals to be only off by a max of 1 unit
uint256 constant PM = 1e23;

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
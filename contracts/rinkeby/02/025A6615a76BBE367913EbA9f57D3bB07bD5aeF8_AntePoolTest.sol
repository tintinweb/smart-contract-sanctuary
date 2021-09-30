// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IAntePool.sol";
import "../AnteTest.sol";

/// @title Ante Pool contract states matches their ETH balance
/// @notice Connects to already deployed Ante Pools to check them
contract AntePoolTest is AnteTest("Ante Pool contract state matches eth balance") {
    using SafeMath for uint256;

    /// @param antePoolContracts array of Ante Pools to check against
    constructor(address[] memory antePoolContracts) {
        testedContracts = antePoolContracts;
        protocolName = "Ante";
    }

    /// @notice test checks if any Ante Pool's balance is less than supposed store values
    /// @return true if contract balance is greater than or equal to stored Ante Pool values
    function checkTestPasses() public view override returns (bool) {
        for (uint256 i = 0; i < testedContracts.length; i++) {
            IAntePool antePool = IAntePool(testedContracts[i]);
            // totalPaidOut should be 0 before test fails
            if (
                testedContracts[i].balance <
                (
                    antePool
                        .getTotalChallengerStaked()
                        .add(antePool.getTotalStaked())
                        .add(antePool.getTotalPendingWithdraw())
                        .sub(antePool.totalPaidOut())
                )
            ) {
                return false;
            }
        }
        return true;
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

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "./IAnteTest.sol";

/// @title The interface for Ante V0.5 Ante Pool
/// @notice The Ante Pool handles interactions with connected Ante Test
interface IAntePool {
    /// @notice Emitted when a user adds to the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being added in wei
    /// @param isChallenger Whether or not this is added to the challenger pool
    event Stake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when a user removes from the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being removed in wei
    /// @param isChallenger Whether or not this is removed from the challenger pool
    event Unstake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when the connected Ante Test's invariant gets verified
    /// @param checker The address of challenger who called the verification
    event TestChecked(address indexed checker);

    /// @notice Emitted when the connected Ante Test has failed test verification
    /// @param checker The address of challenger who called the verification
    event FailureOccurred(address indexed checker);

    /// @notice Emitted when a challenger claims their payout for a failed test
    /// @param claimer The address of challenger claiming their payout
    /// @param amount Amount being claimed in wei
    event ClaimPaid(address indexed claimer, uint256 amount);

    /// @notice Emitted when a staker has withdrawn their stake after the 24 hour wait period
    /// @param staker The address of the staker removing their stake
    /// @param amount Amount withdrawn in wei
    event WithdrawStake(address indexed staker, uint256 amount);

    /// @notice Emitted when a staker cancels their withdraw action before the 24 hour wait period
    /// @param staker The address of the staker cancelling their withdraw
    /// @param amount Amount cancelled in wei
    event CancelWithdraw(address indexed staker, uint256 amount);

    /// @notice Initializes Ante Pool with the connected Ante Test
    /// @param _anteTest The Ante Test that will be connected to the Ante Pool
    /// @dev This function requires that the Ante Test address is valid and that
    /// the invariant validation currently passes
    function initialize(IAnteTest _anteTest) external;

    /// @notice Cancels a withdraw action of a staker before the 24 hour wait period expires
    /// @dev This is called when a staker has initiated a withdraw stake action but
    /// then decides to cancel that withdraw before the 24 hour wait period is over
    function cancelPendingWithdraw() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTest() external;

    /// @notice Claims the payout of a failed Ante Test
    /// @dev To prevent double claiming, the challenger balance is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claim() external;

    /// @notice Adds a users's stake or challenge to the staker or challenger pool
    /// @param isChallenger Flag for if this is a challenger
    function stake(bool isChallenger) external payable;

    /// @notice Removes a user's stake or challenge from the staker or challenger pool
    /// @param amount Amount being removed in wei
    /// @param isChallenger Flag for if this is a challenger
    function unstake(uint256 amount, bool isChallenger) external;

    /// @notice Removes all of a user's stake or challenge from the respective pool
    /// @param isChallenger Flag for if this is a challenger
    function unstakeAll(bool isChallenger) external;

    /// @notice Updates the decay multipliers and amounts for the total staked and challenged pools
    /// @dev This function is called in most other functions as well to keep the
    /// decay amounts and pools accurate
    function updateDecay() external;

    /// @notice Initiates the withdraw process for a staker, starting the 24 hour waiting period
    /// @dev During the 24 hour waiting period, the value is locked to prevent
    /// users from removing their stake when a challenger is going to verify test
    function withdrawStake() external;

    /// @notice Returns the Ante Test connected to this Ante Pool
    /// @return IAnteTest The Ante Test interface
    function anteTest() external view returns (IAnteTest);

    /// @notice Get the info for the challenger pool
    /// @return numUsers The total number of challengers in the challenger pool
    ///         totalAmount The total value locked in the challenger pool in wei
    ///         decayMultiplier The current multiplier for decay
    function challengerInfo()
        external
        view
        returns (
            uint256 numUsers,
            uint256 totalAmount,
            uint256 decayMultiplier
        );

    /// @notice Get the info for the staker pool
    /// @return numUsers The total number of stakers in the staker pool
    ///         totalAmount The total value locked in the staker pool in wei
    ///         decayMultiplier The current multiplier for decay
    function stakingInfo()
        external
        view
        returns (
            uint256 numUsers,
            uint256 totalAmount,
            uint256 decayMultiplier
        );

    /// @notice Get the total value eligible for payout
    /// @dev This is used so that challengers must have challenged for at least
    /// 12 blocks to receive payout, this is to mitigate other challengers
    /// from trying to stick in a challenge right before the verification
    /// @return eligibleAmount Total value eligible for payout in wei
    function eligibilityInfo() external view returns (uint256 eligibleAmount);

    /// @notice Returns the Ante Pool factory address that created this Ante Pool
    /// @return Address of Ante Pool factory
    function factory() external view returns (address);

    /// @notice Returns the block at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Block number where Ante Test failed
    function failedBlock() external view returns (uint256);

    /// @notice Returns the payout amount for a specific challenger
    /// @param challenger Address of challenger
    /// @dev If this is called before an Ante Test has failed, then it's return
    /// value is an estimate
    /// @return Amount that could be claimed by challenger in wei
    function getChallengerPayout(address challenger) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's 24 hour wait period is over
    /// @param _user Address of withdrawing staker
    /// @dev This is timestamp is 24 hours after the time when the staker initaited the
    /// withdraw process
    /// @return Timestamp for when the value is no longer locked and can be removed
    function getPendingWithdrawAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the amount a staker is attempting to withdraw
    /// @param _user Address of withdrawing staker
    /// @return Amount which is being withdrawn in wei
    function getPendingWithdrawAmount(address _user) external view returns (uint256);

    /// @notice Returns the stored balance of a user in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This function calculates decay and returns the stored value after the
    /// decay has been either added (staker) or subtracted (challenger)
    /// @return Balance that the user has currently in wei
    function getStoredBalance(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns total value of eligible payout for challengers
    /// @return Amount eligible for payout in wei
    function getTotalChallengerEligibleBalance() external view returns (uint256);

    /// @notice Returns total value locked of all challengers
    /// @return Total amount challenged in wei
    function getTotalChallengerStaked() external view returns (uint256);

    /// @notice Returns total value of all stakers who are withdrawing their stake
    /// @return Total amount waiting for withdraw in wei
    function getTotalPendingWithdraw() external view returns (uint256);

    /// @notice Returns total value locked of all stakers
    /// @return Total amount staked in wei
    function getTotalStaked() external view returns (uint256);

    /// @notice Returns a user's starting amount added in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is caluclated or additional value
    /// added to respective side
    /// @return User's starting amount in wei
    function getUserStartAmount(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns the verifier bounty amount
    /// @dev Currently this is 5% of the total staked amount
    /// @return Bounty amount rewarded to challenger who verifies test in wei
    function getVerifierBounty() external view returns (uint256);

    /// @notice Returns the cutoff block when challenger can call verify test
    /// @dev This is currently 12 blocks after a challenger has challenged the test
    /// @return Block number of when verify test can be called by challenger
    function getCheckTestAllowedBlock(address _user) external view returns (uint256);

    /// @notice Returns the most recent block number where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Block number of when contract was last updated
    function lastUpdateBlock() external view returns (uint256);

    /// @notice Returns the most recent block number where a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Block number of last verification attempt
    function lastVerifiedBlock() external view returns (uint256);

    /// @notice Returns the number of challengers that have claimed their payout
    /// @return Number of challengers
    function numPaidOut() external view returns (uint256);

    /// @notice Returns the number of times that the Ante Test has been verified
    /// @return Number of verifications
    function numTimesVerified() external view returns (uint256);

    /// @notice Returns if the connected Ante Test has failed
    /// @return True if the connected Ante Test has failed, False if not
    function pendingFailure() external view returns (bool);

    /// @notice Returns the total value of payout to challengers that have been claimed
    /// @return Value of claimed payouts in wei
    function totalPaidOut() external view returns (uint256);

    /// @notice Returns the address of verifier who successfully activated verify test
    /// @dev This is the user who will receive the verifier bounty
    /// @return Address of verifier challenger
    function verifier() external view returns (address);

    /// @notice Returns the total value of stakers who are withdrawing
    /// @return totalAmount total amount pending to be withdrawn in wei
    function withdrawInfo() external view returns (uint256 totalAmount);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "./interfaces/IAnteTest.sol";

/// @title Ante V0.5 Ante Test smart contract
/// @notice Abstract inheritable contract that supplies syntactic sugar for writing Ante Tests
/// @dev Usage: contract YourAnteTest is AnteTest("String descriptor of test") { ... }
abstract contract AnteTest is IAnteTest {
    /// @inheritdoc IAnteTest
    address public override testAuthor;
    /// @inheritdoc IAnteTest
    string public override testName;
    /// @inheritdoc IAnteTest
    string public override protocolName;
    /// @inheritdoc IAnteTest
    address[] public override testedContracts;

    /// @dev testedContracts and protocolName are optional parameters which should
    /// be set in the constructor of your AnteTest
    /// @param _testName The name of the Ante Test
    constructor(string memory _testName) {
        testAuthor = msg.sender;
        testName = _testName;
    }

    /// @notice Returns the testedContracts array of addresses
    /// @return The list of tested contracts as an array of addresses
    function getTestedContracts() external view returns (address[] memory) {
        return testedContracts;
    }

    /// @inheritdoc IAnteTest
    function checkTestPasses() external virtual override returns (bool) {}
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

/// @title The interface for the Ante V0.5 Ante Test
/// @notice The Ante V0.5 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
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
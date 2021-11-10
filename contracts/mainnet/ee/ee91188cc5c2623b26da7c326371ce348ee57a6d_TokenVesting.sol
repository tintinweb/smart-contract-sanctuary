/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: gist-314004e0d4de055bd488390866f8ac4a/TokenVesting.sol



pragma solidity 0.8.0;




/**
 * @title Select Token Vesting smart contract
 * @author Michal Wojcik
 * @notice Contract for distribute bought SELECT tokens
 * @dev WARNING!
 *      Released Tokens - all tokens allowed to CLAIM.
 *      Claimed tokens - all tokens already transferred to address account from vesting contract.
*/
contract TokenVesting is Ownable {
    using SafeMath for uint256;

    uint256 private constant RELEASE_TIMEFRAME = 604_800; // 1 week
    uint256 private constant SINGLE_RELEASE_PERCENTAGE = 3;
    uint256 private constant INITIAL_PERCENTAGE = 10;
    uint256 private _vestingStartTime;
    IERC20  private _erc20Token;

    event TokensClaimed(address recipient, uint256 claimedAmount, bool isInitialClaim);

    /**
     * @notice Struct defining vesting user input data
     * @param userAddress - vesting user address
     * @param salesStagesBalance - all bought and earned user tokens during pre listing period (WEI)
     */
    struct VestingUserInput {
        address userAddress;
        uint256 salesStagesBalance;
    }

    /**
     * @notice Struct defining vesting user state
     * @param userAddress - vesting user address
     * @param salesStagesBalance - all bought and earned user tokens during pre listing period (WEI)
     * @param claimedTokens - already claimed tokens (WEI)
     */
    struct VestingUser {
        address userAddress;
        uint256 salesStagesBalance;
        uint256 claimedTokens;
    }

    mapping(address => VestingUser) private _vestingUsers;

    /**
     * @notice Initialization of contract
     * @param erc20TokenAddress - address of ERC-20 token contract
     * @param vestingStartTime - timestamp first day of vesting
     * @param vestingUsers - list of users who bought the tokens
     */
    constructor(address erc20TokenAddress, uint256 vestingStartTime, VestingUserInput[] memory vestingUsers) {
        _erc20Token = IERC20(erc20TokenAddress);
        _vestingStartTime = vestingStartTime;


        for (uint256 i = 0; i < vestingUsers.length; i++) {
            VestingUserInput memory vestingUser = vestingUsers[i];
            _vestingUsers[vestingUser.userAddress] = VestingUser(vestingUser.userAddress, vestingUser.salesStagesBalance, 0);
        }
    }

    /**
     * @notice Update vesting users - for fixing porpoises
     * @param vestingUsers - list of users who bought the tokens
     * @dev Warning! If you pass existing user his values can be reset.
     */
    function updateVestingUsers(VestingUserInput[] memory vestingUsers) external onlyOwner() {
        for (uint256 i = 0; i < vestingUsers.length; i++) {
            VestingUserInput memory vestingUser = vestingUsers[i];
            _vestingUsers[vestingUser.userAddress] = VestingUser(vestingUser.userAddress, vestingUser.salesStagesBalance, 0);
        }
    }

    /**
     * @notice Transfer released ERC-20 tokens to caller's address.
     * @dev Emits {TokensClaimed} event on success
     */
    function claimTokens() external {
        VestingUser memory vestingUserSummary = _vestingUsers[msg.sender];
        uint256 timeNow = block.timestamp;
        uint256 vestingStartTime = _vestingStartTime;
        bool isInitialClaim = _getTimeframesCount(timeNow, vestingStartTime) == 0;

        require(timeNow > vestingStartTime, "Vesting not started yet.");

        require(vestingUserSummary.salesStagesBalance > 0, "You don't have any tokens.");

        uint256 tokensToClaim = _getReleasedTokensAmount(timeNow, vestingStartTime, vestingUserSummary.salesStagesBalance)
        .sub(vestingUserSummary.claimedTokens);

        require(tokensToClaim > 0, "You don't have tokens to claim.");

        _vestingUsers[msg.sender].claimedTokens += tokensToClaim;

        require(_erc20Token.transfer(msg.sender, tokensToClaim), "ERC20Token: Transfer failed");

        emit TokensClaimed(msg.sender, tokensToClaim, isInitialClaim);
    }

    /**
     * @notice Returns information about current account vesting state
     * @return releasedTokens - sum of all tokens allowed to be released (already claimed founds included)
     * @return salesStageBalance - all bought and earned tokens during sale stages
     * @return claimedTokensAmount - already withdrawn amount of tokens
     * @dev To get actual tokensToClaim you need to do operation: {tokensToRelease} - {withdrawnTokensAmount}
     */
    function getAddressVestingInfo() external view returns (uint256 releasedTokens, uint256 salesStageBalance, uint256 claimedTokensAmount, uint256 filledTimeframesCount) {
        VestingUser memory vestingUserSummary = _vestingUsers[msg.sender];
        uint256 timeNow = block.timestamp;
        uint256 vestingStartTime = _vestingStartTime;

        filledTimeframesCount = _getTimeframesCount(timeNow, vestingStartTime);
        releasedTokens = _getReleasedTokensAmount(block.timestamp, _vestingStartTime, vestingUserSummary.salesStagesBalance);
        salesStageBalance = vestingUserSummary.salesStagesBalance;
        claimedTokensAmount = vestingUserSummary.claimedTokens;
    }

    /**
     * @notice Returns amount of released tokens for given account address
     * @param timeNow - actual timestamp
     * @param vestingStartTime - timestamp when vesting program starts
     * @param accountBalance - sum of all bought and earned tokens during sale stages
     */
    function _getReleasedTokensAmount(uint256 timeNow, uint256 vestingStartTime, uint256 accountBalance) private pure returns (uint256) {

        if (timeNow < vestingStartTime) {
            return 0;
        }

        uint256 timeframesCount = _getTimeframesCount(timeNow, vestingStartTime);
        uint256 numberOfPercentToRelease = timeframesCount.mul(SINGLE_RELEASE_PERCENTAGE).add(INITIAL_PERCENTAGE);

        return (accountBalance * numberOfPercentToRelease) / 100;
    }

    /**
     * @notice Returns amount of timeframes from vesting program start till now
     * @param timeNow - actual timestamp
     * @param vestingStartTime - timestamp when vesting program starts
     */
    function _getTimeframesCount(uint256 timeNow, uint256 vestingStartTime) private pure returns (uint256) {

        if (timeNow < vestingStartTime) {
            return 0;
        }

        uint256 maxTimeframes = (100 - INITIAL_PERCENTAGE) / SINGLE_RELEASE_PERCENTAGE;

        uint256 timeframesCount = (timeNow.sub(vestingStartTime)) / RELEASE_TIMEFRAME;

        return (timeframesCount <= maxTimeframes) ? timeframesCount : maxTimeframes;
    }
}
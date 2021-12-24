pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Votes is Ownable {
  using SafeMath for uint;

  struct Survey {
    address creator;
    string nftUrl;
    uint start;
    uint end;
    uint minVotes;
    uint maxVotes;
    uint rewardAmount;
  }

  // constans
  uint minRewardAmount = 100e18;
  uint minLockAmount = 2e18;
  uint feePercent = 3;
  // for bsc
  // address lockAsset = 0xEd8c8Aa8299C10f067496BB66f8cC7Fb338A3405;
  // for kovan
  address lockAsset = 0xEf08fB4a21AF65840e6Db6B369CeE2cbCE7585a0;
  // for tests
  // address lockAsset;

  Survey[] public surveys;
  uint private fees = 0;
  mapping (uint => mapping (address => string)) private userVotesInEvent;
  mapping (uint => uint) public surveyVotesAmount;
  // mb save data if user locked only true/false
  mapping (address => uint) public userTokensLockedAmount;
  mapping (address => mapping(uint => uint)) public userRewardAmountInEvent;
  mapping (address => uint) public userVoteDeadline;

  event NewSurvey(uint eventId, uint creationTimestamp, address sender, string nftUrl, uint start, uint end, uint minVotes, uint maxVotes, uint rewardAmount);
  event NewVote(uint eventId, address sender, string answer);
  event Claim(uint eventId, address sender, uint amount);
  event LockedTokens(address sender, uint amount);
  event UnlockedTokens(address sender, uint amount);
  event RewardsAreSet(uint eventId);
  event MaxVotesReached(uint eventId);

  modifier canCreate(uint _rewardAmount) {
    require (_rewardAmount >= minRewardAmount, "Too low reward amount");
    _;
  }

  modifier correctInputs(uint _start, uint _end) {
    require(block.timestamp < _start && _end > _start, "Your inputs are incorrect");
    _;
  }

  modifier canVote(address _user, uint _eventId) {
    require (userTokensLockedAmount[_user] >= minLockAmount && bytes(userVotesInEvent[_eventId][_user]).length == 0,
    // && keccak256(usersVotes[_eventId][_user]) == keccak256(""),
    "You have no tokens locked or you have already voted to this event");
    _;
  }

  modifier canClaim(address _user, uint _eventId) {
    require (userRewardAmountInEvent[_user][_eventId] > 0, "You did not vote");
    _;
  }

  modifier canUnlockVoterTokens(address _user) {
    require (userTokensLockedAmount[_user] > 0, "You have no tokens locked");
    _;
  }

  modifier surveysAreClosed(address _user) {
    require (userVoteDeadline[_user] < block.timestamp, "Not all surveys are closed");
    _;
  }

  modifier surveyIsNotClosed(uint _eventId) {
    require(block.timestamp < surveys[_eventId].end || surveyVotesAmount[_eventId] < surveys[_eventId].maxVotes, "Survey is closed");
    _;
  }

  modifier surveyIsOpened(uint _eventId) {
    require(block.timestamp > surveys[_eventId].start, "Survey is not started yet");
    _;
  }

  modifier feesAreNotZero() {
    require(fees > 0, "Fees are 0");
    _;
  }

  function transfer(address _from, address _to, uint _amount) internal {
    if (_from == address(this)) {
      IERC20(lockAsset).transfer(_to, _amount);
    } else {
      IERC20(lockAsset).transferFrom(_from, _to, _amount);
    }
  }

  function lockTokensVoter () public {
    transfer(msg.sender, address(this), minLockAmount);
    userTokensLockedAmount[msg.sender] = minLockAmount;
    emit LockedTokens(msg.sender, minLockAmount);
  }

  function unlockVoterTokens () public canUnlockVoterTokens(msg.sender) surveysAreClosed(msg.sender) {
    uint amount = userTokensLockedAmount[msg.sender];
    delete userTokensLockedAmount[msg.sender];
    transfer(address(this), msg.sender, amount);
    emit UnlockedTokens(msg.sender, amount);
  }

  function createSurvey (string memory nftUrl, uint startTimestamp, uint endTimestamp, uint minVotes, uint maxVotes, uint rewardAmount)
    public canCreate(rewardAmount) correctInputs(startTimestamp, endTimestamp) {
    transfer(msg.sender, address(this), rewardAmount);
    uint fee = rewardAmount.mul(feePercent).div(100);
    uint rewardWithoutFee = rewardAmount.sub(fee);
    fees = fees.add(fee);
    {
      Survey memory newSurvey = Survey(msg.sender, nftUrl, startTimestamp, endTimestamp, minVotes, maxVotes, rewardWithoutFee);
      surveys.push(newSurvey);
    }
    {
      emit NewSurvey(surveys.length - 1, block.timestamp, msg.sender, nftUrl, startTimestamp, endTimestamp, minVotes, maxVotes, rewardWithoutFee);
    }
  }

  function vote (string memory answer, uint eventId) public canVote(msg.sender, eventId) surveyIsNotClosed(eventId) surveyIsOpened(eventId) {
    userVotesInEvent[eventId][msg.sender] = answer;
    surveyVotesAmount[eventId]++;
    if (surveyVotesAmount[eventId] >= surveys[eventId].maxVotes) {
      emit MaxVotesReached(eventId);
    }
    //setting new deadline for user to unlock tokens
    if (userVoteDeadline[msg.sender] < surveys[eventId].end) {
      userVoteDeadline[msg.sender] = surveys[eventId].end;
    }
    emit NewVote(eventId, msg.sender, answer);
  }

  function setRewards (uint eventId, bool succeed, address[] memory addresses) public onlyOwner {
    uint totalRewards = surveys[eventId].rewardAmount;
    if (succeed) {
      uint rewardAmount = totalRewards.div(addresses.length);
      for (uint i = 0; i < addresses.length; i++) {
        userRewardAmountInEvent[addresses[i]][eventId] = rewardAmount;
      }
    } else {
      address creator = surveys[eventId].creator;
      userRewardAmountInEvent[creator][eventId] = totalRewards;
    }
    emit RewardsAreSet(eventId);
  }

  function claimRewards (uint eventId) public canClaim(msg.sender, eventId) {
    uint amount = userRewardAmountInEvent[msg.sender][eventId];
    delete userRewardAmountInEvent[msg.sender][eventId];
    transfer(address(this), msg.sender, amount);
    emit Claim(eventId, msg.sender, amount);
  }

  function collectFees () public onlyOwner feesAreNotZero() {
    transfer(address(this), msg.sender, fees);
    fees = 0;
  }

  // function setLockTokenAddress(address _newAddress) public onlyOwner {
  //   lockAsset = _newAddress;
  // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
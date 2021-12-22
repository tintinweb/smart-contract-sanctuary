pragma solidity 0.6.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./IERC20.sol";

contract Votes is Ownable, Initializable {
  using SafeMath for uint;

  struct NftEvent {
    address creator;
    string nftUrl;
    uint start;
    uint end;
    uint minParticipants;
    uint maxParticipants;
    uint rewardAmount;
  }

  // constans
  uint minRewardAmount = 100;
  uint minLockAmount = 2;
  uint feePercent = 3;
  // address lockAsset = 0xEd8c8Aa8299C10f067496BB66f8cC7Fb338A3405;
  address lockAsset = 0xEf08fB4a21AF65840e6Db6B369CeE2cbCE7585a0;

  NftEvent[] public nftEvents;
  uint fees = 0;
  mapping (uint => mapping (address => string)) public usersVotes;
  mapping (uint => uint) public nftEventsParticipants;
  // mb save data if user locked only true/false
  mapping (address => uint) public lockedAmount;
  mapping (address => uint) public lockedCreatorAmount;
  mapping (address => mapping(uint => uint)) public rewardAmountInEvent;
  mapping (address => uint) public userVoteDeadline;

  event NewSurvey(uint eventId, address sender, string nftUrl, uint creationBlock, uint startBlock, uint endBlock, uint minVotes, uint maxVotes, uint rewardAmount);
  event NewVote(uint eventId, address sender, string answer);
  event Claim(uint eventId, address sender, uint amount);
  event LockedTokens(address sender, uint amount);
  event UnlockedTokens(address sender, uint amount);
  event RewardsAreSet(uint eventId);
  event MaxVotesReached(uint eventId);

  modifier canCreate(address _user, uint _rewardAmount) {
    require (_rewardAmount >= minRewardAmount, "Too low reward amount");
    _;
  }

  modifier canVote(address _user, uint _eventId) {
    require (lockedAmount[_user] >= minLockAmount && bytes(usersVotes[_eventId][_user]).length == 0,
    // && keccak256(usersVotes[_eventId][_user]) == keccak256(""),
    "You have no tokens locked or you have already voted to this event");
    _;
  }

  modifier canClaim(address _user, uint _eventId) {
    require (rewardAmountInEvent[_user][_eventId] > 0, "You did not vote");
    _;
  }

  modifier canUnlockVotesTokens(address _user) {
    require (lockedAmount[_user] > 0, "You have no tokens locked");
    _;
  }

  modifier eventsAreClosed(address _user) {
    require (userVoteDeadline[_user] < block.number, "Not all events are closed");
    _;
  }

  modifier eventIsNotClosed(uint _eventId) {
    require(block.number < nftEvents[_eventId].end || nftEventsParticipants[_eventId] < nftEvents[_eventId].maxParticipants, "Event is closed");
    _;
  }

  modifier evenIsOpened(uint _eventId) {
    require(block.number > nftEvents[_eventId].start, "Event is not started yet");
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
    IERC20(lockAsset).approve(address(this), minLockAmount);
    transfer(msg.sender, address(this), minLockAmount);
    lockedAmount[msg.sender] = minLockAmount;
    emit LockedTokens(msg.sender, minLockAmount);
  }

  function unlockVotesTokens () public canUnlockVotesTokens(msg.sender) {
    uint amount = lockedAmount[msg.sender];
    delete lockedAmount[msg.sender];
    transfer(address(this), msg.sender, amount);
    emit UnlockedTokens(msg.sender, amount);
  }

  function createNftEvent (string memory _nftUrl, uint _start, uint _end, uint _minParticipants, uint _maxParticipants, uint _rewardAmount) public canCreate(msg.sender, _rewardAmount) {
    IERC20(lockAsset).approve(address(this), _rewardAmount);
    transfer(msg.sender, address(this), _rewardAmount);
    uint fee = _rewardAmount.mul(feePercent).div(100);
    uint rewardWithoutFee = _rewardAmount.sub(fee);
    fees = fees.add(fee);
    NftEvent memory newNftEvent = NftEvent(msg.sender, _nftUrl, _start, _end, _minParticipants, _maxParticipants, rewardWithoutFee);
    nftEvents.push(newNftEvent);
    emit NewSurvey(nftEvents.length - 1, msg.sender, _nftUrl, block.number, _start, _end, _minParticipants, _maxParticipants, rewardWithoutFee);
  }

  function vote (string memory _answer, uint _eventId) public canVote(msg.sender, _eventId) eventIsNotClosed(_eventId) evenIsOpened(_eventId) {
    usersVotes[_eventId][msg.sender] = _answer;
    nftEventsParticipants[_eventId].add(1);
    if (nftEventsParticipants[_eventId] >= nftEvents[_eventId].maxParticipants) {
      emit MaxVotesReached(_eventId);
    }
    //setting new deadline for user to unlock tokens
    if (userVoteDeadline[msg.sender] > nftEvents[_eventId].end) {
      userVoteDeadline[msg.sender] = nftEvents[_eventId].end;
    }
    emit NewVote(_eventId, msg.sender, _answer);
  }

  function setRewards (uint _eventId, bool _succeed, address[] memory _addresses) public onlyOwner {
    uint totalRewards = nftEvents[_eventId].rewardAmount;
    if (_succeed) {
      for (uint i = 0; i < _addresses.length; i++) {
        rewardAmountInEvent[_addresses[i]][_eventId] = totalRewards.div(_addresses.length);
      }
    } else {
      address creator = nftEvents[_eventId].creator;
      rewardAmountInEvent[creator][_eventId] = totalRewards;
    }
    emit RewardsAreSet(_eventId);
  }

  function claimRewards (uint _eventId) public canClaim(msg.sender, _eventId) {
    uint amount = rewardAmountInEvent[msg.sender][_eventId];
    delete rewardAmountInEvent[msg.sender][_eventId];
    transfer(address(this), msg.sender, amount);
    emit Claim(_eventId, msg.sender, amount);
  }

  function collectFees () public onlyOwner feesAreNotZero() {
    transfer(address(this), msg.sender, fees);
    fees = 0;
  }
}

// SPDX-License-Identifier: MIT
// Creator: OpenZeppelin

pragma solidity ^0.6.5;

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
contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// Creator: OpenZeppelin

pragma solidity ^0.6.5;

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
}

// SPDX-License-Identifier: MIT
// Creator: OpenZeppelin

pragma solidity ^0.6.5;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// Creator: OpenZeppelin

pragma solidity ^0.6.5;

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
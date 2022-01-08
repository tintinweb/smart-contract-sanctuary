/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

contract EndorseUser is Context, Ownable {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  address public mscToken;
  address public lockAddress = 0x0F5dCfEB80A5986cA3AfC17eA7e45a1df8Be4844;
  address public flagAddress = 0x0F5dCfEB80A5986cA3AfC17eA7e45a1df8Be4844;
  address public rewardAddress = 0x292eC696dEc44222799c4e8D90ffbc1032D1b7AC;

  uint256 TotalLock;
  uint256 TotalDownvoteLock;
  uint256 RewardPerToken;

  struct Vote {
    bool upvoted;
    uint256 amount;
  }

  struct Voter {
    uint8 totalVote;
    uint256 totalLock;
    mapping(address => Vote) votes;
  }

  struct Downvote {
    bool downvoted;
    uint256 amount;
  }

  struct Downvoter {
    uint8 totalDownvote;
    uint256 totalAmount;
    mapping(address => Downvote) downvotes;
  }

  struct UserVote {
    uint8 totalVote;
    uint256 totalAmount;
  }

  struct UserDownvote {
    uint8 totalDownvote;
    uint256 totalAmount;
  }

  mapping(address => Voter) public _voters;
  mapping(address => UserVote) public _votes;
  mapping(address => int256) public _rewardTally;

  mapping(address => Downvoter) public _downvoters;
  mapping(address => UserDownvote) public _downvotes;

  event Upvoted(address indexed by, address indexed user, uint256 amount);
  event Unvoted(address indexed by, address indexed user, uint256 amount);
  event Flagged(address indexed by, address indexed user, uint256 amount);
  event Unflagged(address indexed by, address indexed user, uint256 amount);
  event Claimed(address indexed user, uint256 reward);
  event Distributed(uint256 reward);

  constructor (address _mscToken) {
    mscToken = _mscToken;
  }

  function updateLockAddress(address _newAddress) external onlyOwner {
    lockAddress = _newAddress;
  }

  function updateRewardAddress(address _newAddress) external onlyOwner {
    rewardAddress = _newAddress;
  }

  function updateFlagAddress(address _newAddress) external onlyOwner {
    flagAddress = _newAddress;
  }

  // Calculate reward per token based on the current total lock tokens
  function distribute(uint256 rewards) external onlyOwner returns (bool) {
    if (TotalLock > 0) {
      RewardPerToken = RewardPerToken.add(rewards.div(TotalLock.div(10**16)).mul(10**2));
    }

    emit Distributed(rewards);
    return true;
  }

  // Set reward tally for specific user on upvote
  // This will be used to deduct to the total rewards of the user
  function addRewardTally(address user, uint256 amount) private {
    uint256 totalReward = RewardPerToken.mul(amount.div(10**18));
    _rewardTally[user] = _rewardTally[user].add(int(totalReward));
  }

  // Set reward tally for specific user on unvote
  // This will be used to deduct to the total rewards of the user
  function subRewardTally(address user, uint256 amount) private {
    uint256 totalReward = RewardPerToken.mul(amount.div(10**18));
    _rewardTally[user] = _rewardTally[user].sub(int(totalReward));
  }

  function computeReward(address user) private view returns(uint256) {
    int256 totalReward = int(_votes[user].totalAmount.div(10**18).mul(RewardPerToken));
    int256 rewardBalance = totalReward.sub(_rewardTally[user]);
    return rewardBalance >= 0 ? uint(rewardBalance) : 0;
  }

  function upvote(address user, uint256 amount) public returns(bool) {
    require(user != address(0x0), "Invalid address");
    require(amount > 0 && amount <= IERC20(mscToken).balanceOf(_msgSender()), "Invalid amount or not enough balance");
    require(!_voters[_msgSender()].votes[user].upvoted, "Already upvoted to this user");

    _safeTransfer(_msgSender(), lockAddress, amount);

    _voters[_msgSender()].totalVote += 1;
    _voters[_msgSender()].totalLock = _voters[_msgSender()].totalLock.add(amount);
    _voters[_msgSender()].votes[user].upvoted = true;
    _voters[_msgSender()].votes[user].amount = amount;

    _votes[user].totalVote += 1;
    _votes[user].totalAmount = _votes[user].totalAmount.add(amount);

    TotalLock = TotalLock.add(amount);
    addRewardTally(user, amount);

    emit Upvoted(_msgSender(), user, amount);
    return true;
  }

  function unvote(address user) public returns(bool) {
    require(user != address(0x0), "Invalid address");
    require(_voters[_msgSender()].votes[user].upvoted, "You did not upvote this user");

    uint256 amount = _voters[_msgSender()].votes[user].amount;
    _safeTransfer(lockAddress, _msgSender(), amount);

    _voters[_msgSender()].totalVote -= 1;
    _voters[_msgSender()].totalLock = _voters[_msgSender()].totalLock.sub(amount);
    _voters[_msgSender()].votes[user].upvoted = false;

    _votes[user].totalVote -= 1;
    _votes[user].totalAmount = _votes[user].totalAmount.sub(amount);

    TotalLock = TotalLock.sub(amount);
    subRewardTally(user, amount);

    emit Unvoted(_msgSender(), user, amount);
    return true;
  }

  // Get the total upvotes distributed by the user
  function getTotalUpvotedBy(address upvotedBy) public view returns(uint8, uint256){
    return (_voters[upvotedBy].totalVote, _voters[upvotedBy].totalLock);
  }

  // Check if user is being endorse by another user
  function checkVote(address upvotedBy, address user) public view returns(bool, uint256){
    return (_voters[upvotedBy].votes[user].upvoted, _voters[upvotedBy].votes[user].amount);
  }

  // Get the total upvotes received by the user
  function checkTotalVotes(address user) public view returns(uint8, uint256){
    return (_votes[user].totalVote, _votes[user].totalAmount);
  }

  function checkRewards(address user) public view returns(uint256) {
    uint256 reward = computeReward(user);
    return reward;
  }

  function claim() public returns(bool) {
    uint256 reward = computeReward(_msgSender());
    uint256 rewardBalance = IERC20(mscToken).balanceOf(rewardAddress);
    require(reward > 0, "No rewards to claim.");
    require(reward <= rewardBalance, "No available funds.");

    _safeTransfer(rewardAddress, _msgSender(), reward);

    uint256 newRewardTally = _votes[_msgSender()].totalAmount.div(10**18).mul(RewardPerToken);
    _rewardTally[_msgSender()] = int(newRewardTally);

    emit Claimed(_msgSender(), reward);
    return true;
  }

  function flagUser(address user, uint256 amount) public returns(bool) {
    require(user != address(0x0), "Invalid address");
    require(amount > 0 && amount <= IERC20(mscToken).balanceOf(_msgSender()), "Invalid amount or not enough balance");
    require(!_downvoters[_msgSender()].downvotes[user].downvoted, "Already downvoted to this user");

    _safeTransfer(_msgSender(), flagAddress, amount);

    _downvoters[_msgSender()].totalDownvote += 1;
    _downvoters[_msgSender()].totalAmount = _downvoters[_msgSender()].totalAmount.add(amount);
    _downvoters[_msgSender()].downvotes[user].downvoted = true;
    _downvoters[_msgSender()].downvotes[user].amount = amount;

    _downvotes[user].totalDownvote += 1;
    _downvotes[user].totalAmount = _downvotes[user].totalAmount.add(amount);
    TotalDownvoteLock = TotalDownvoteLock.add(amount);

    emit Flagged(_msgSender(), user, amount);
    return true;
  }

  function unflagUser(address user) public returns(bool) {
    require(user != address(0x0), "Invalid address");
    require(_downvoters[_msgSender()].downvotes[user].downvoted, "You did not flag this user");

    uint256 amount = _downvoters[_msgSender()].downvotes[user].amount;
    _safeTransfer(flagAddress, _msgSender(), amount);

    _downvoters[_msgSender()].totalDownvote -= 1;
    _downvoters[_msgSender()].totalAmount = _downvoters[_msgSender()].totalAmount.sub(amount);
    _downvoters[_msgSender()].downvotes[user].downvoted = false;

    _downvotes[user].totalDownvote -= 1;
    _downvotes[user].totalAmount = _downvotes[user].totalAmount.sub(amount);
    TotalDownvoteLock = TotalDownvoteLock.sub(amount);

    emit Unflagged(_msgSender(), user, amount);
    return true;
  }

  // Get the total upvotes distributed by the user
  function getTotalDownvotedBy(address downvotedBy) public view returns(uint8, uint256){
    return (_downvoters[downvotedBy].totalDownvote, _downvoters[downvotedBy].totalAmount);
  }

  // Check if user is being downvoted by another user
  function checkDownvote(address downvotedBy, address user) public view returns(bool, uint256){
    return (_downvoters[downvotedBy].downvotes[user].downvoted, _downvoters[downvotedBy].downvotes[user].amount);
  }

  // Get the total downvotes received by the user
  function checkTotalDownvotes(address user) public view returns(uint8, uint256){
    return (_downvotes[user].totalDownvote, _downvotes[user].totalAmount);
  }

  // Transfer token from one address to another
  function _safeTransfer(address from, address to, uint256 amount) private {
    uint256 allowance = IERC20(mscToken).allowance(address(this), from);
    IERC20(mscToken).approve(from, allowance.add(amount));
    IERC20(mscToken).transferFrom(from, to, amount);
  }

}
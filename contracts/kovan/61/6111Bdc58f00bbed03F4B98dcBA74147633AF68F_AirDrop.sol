/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// File: AirDrop.sol

contract AirDrop {
  using SafeMath for uint256;

  address public guardian;
  uint256 public effectTime;

  address public token;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public period;

  uint256 public totalUser;
  uint256 public totalReward;
  uint256 public totalGain;
  bool public start;

  mapping(address => uint256) public amounts;
  mapping(address => uint256) public receives;
  mapping(address => uint256) public lastUpdates;

  constructor() public {
      guardian = msg.sender;
      effectTime = 30 days;
  }

  function setGuardian(address _guardian) external {
      require(msg.sender == guardian, "!guardian");
      guardian = _guardian;
  }

  function initialize(address token_, uint256 startTime_, uint256 period_) external {
      require(token == address(0), "already initialized");
      require(block.timestamp <= startTime_, "!startTime_");
      require(period_ > 0, "!period_");

      token = token_;
      startTime = startTime_;
      period = period_;
      endTime = startTime_.add(period_);
      effectTime = effectTime.add(endTime);
      start = true;
  }

  function addUsers(address[] memory users_, uint256[] memory amounts_) external returns (bool) {
      require(start == false, 'already started');
      require(users_.length == amounts_.length, "length error");

      uint256 _totalAmount = 0;
      for(uint i; i < users_.length; i++){
          amounts[users_[i]] = amounts_[i];
          _totalAmount += amounts_[i];
      }
      totalReward = totalReward.add(_totalAmount);
      totalUser = totalUser.add(users_.length);
      return true;
  }

  function claim() external {
      address _user = msg.sender;
      uint256 _amount = getReward(_user);
      if (_amount > 0) {
          lastUpdates[_user] = block.timestamp;
          receives[_user] = receives[_user].add(_amount);
          require(receives[_user] <= amounts[_user], 'already claim');
          tokenTransfer(_user, _amount);
      }
  }

  function getReward(address user_) public view returns (uint256) {
      uint256 _from = lastUpdates[user_];
      uint256 _to = block.timestamp;
      if (_from < startTime) {
          _from = startTime;
      }
      if (_to > endTime) {
          _to = endTime;
      }
      if (_to <= startTime || _from >= endTime) {
          return 0;
      }

      uint256 _reward = amounts[user_];
      return _to.sub(_from).mul(_reward).div(period);
  }

  function getInfos(address user_) public view returns (uint256 reward_, uint256 total_, uint256 claim_, uint256 endTime_) {
      reward_ = getReward(user_);
      total_ = amounts[user_];
      claim_ = receives[user_];
      endTime_ = endTime;
  }

  function tokenTransfer(address user_, uint256 amount_) internal returns (uint256) {
      uint256 _balance = IERC20(token).balanceOf(address(this));
      uint256 _amount = amount_;
      if (_amount > _balance) {
          _amount = _balance;
      }
      totalGain = totalGain.add(_amount);
      IERC20(token).transfer(user_, _amount);
      return _amount;
  }

  function sweepGuardian(address token_) external {
      require(msg.sender == guardian, "!guardian");
      require(block.timestamp > effectTime, "!effectTime");

      uint256 _balance = IERC20(token_).balanceOf(address(this));
      IERC20(token_).transfer(guardian, _balance);
  }
}
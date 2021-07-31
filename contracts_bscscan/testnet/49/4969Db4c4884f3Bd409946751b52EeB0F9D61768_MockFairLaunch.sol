/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBEP20 {
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract MockFairLaunch {
    using SafeMath for uint256;
    // Info of each user that stakes Staking tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    IBEP20 public ALPACA;

    uint256 public PERIOD_DAY = 1 days;
    uint256 public SUPPLY_APY = 1e11; // 10% 
    mapping(uint256 => mapping(address => uint256)) public timeOfUpdateInterestOf;
    mapping(uint256 => IBEP20) public AlpacaVault;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 bonusDebt; // Last block that user exec something to the pool.
        address fundedBy; // Funded by who?
        //
        // We do some fancy math here. Basically, any point in time, the amount of ALPACAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAlpacaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staking tokens to a pool. Here's what happens:
        //   1. The pool's `accAlpacaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    constructor(IBEP20 _alpaca) public {
        ALPACA = _alpaca;
    }
    function setAlpacaVault(uint256 _pid, IBEP20 _alpacaVault) public {
      AlpacaVault[_pid] = _alpacaVault;
    }
    function changeSupplyAPY(uint256 _value) public {
      SUPPLY_APY = _value;
    }
    function pendingAlpaca(uint256 _pid, address _user) public view returns (uint256) {
        uint256 _uBal = userInfo[_pid][_user].amount;
        uint256 _timeOfUpdate = timeOfUpdateInterestOf[_pid][_user];
        if (_uBal <= 0) {
            return 0;
        }
        if (_timeOfUpdate <= 0) {
            return 0;
        }
        return SUPPLY_APY.mul(_uBal).mul(block.timestamp.sub(_timeOfUpdate)).div(PERIOD_DAY.mul(365).mul(1e12));
    }
    // Deposit Staking tokens to FairLaunchToken for ALPACA allocation.
    function deposit(address _for, uint256 _pid, uint256 _amount) external {
        _deposit(_for, _pid, _amount);
    }
    // Withdraw Staking tokens from FairLaunchToken.
    function withdraw(address _for, uint256 _pid, uint256 _amount) external {
        _withdraw(_for, _pid, _amount);
    }
    function withdrawAll(address _for, uint256 _pid) external {
        _withdraw(_for, _pid, userInfo[_pid][_for].amount);
    }
    // Harvest ALPACAs earn from the pool.
    function harvest(uint256 _pid) external {
        _harvest(_pid, msg.sender);
    }
    function _deposit(address _for, uint256 _pid, uint256 _amount) private {
        _harvest(_pid, _for);
        require(_amount >= 0, 'INVALID_DEPOSIT_AMOUNT');
        // get token
        AlpacaVault[_pid].transferFrom(msg.sender, address(this), _amount);
        userInfo[_pid][_for].amount = userInfo[_pid][_for].amount.add(_amount);
    }
    function _withdraw(address _for, uint256 _pid, uint256 _amount) private {
         uint256 _uBal = userInfo[_pid][_for].amount;
        require(_uBal >= _amount, 'INVALID_WITHDRAW_AMOUNT');
        _harvest(_pid, _for);
        userInfo[_pid][_for].amount = userInfo[_pid][_for].amount.sub(_amount);
        AlpacaVault[_pid].transfer(_for, _amount);
    }
    function _harvest(uint256 _pid, address _for) private {
        uint256 _tokenReward = pendingAlpaca(_pid, _for);
        if (_tokenReward > 0) {
            ALPACA.mint(address(this), _tokenReward);
            ALPACA.transfer(_for, _tokenReward);
        }
        timeOfUpdateInterestOf[_pid][_for] = block.timestamp;
    }
}
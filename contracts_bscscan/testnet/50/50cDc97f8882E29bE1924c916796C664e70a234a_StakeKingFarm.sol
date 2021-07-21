/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 * StakeKing.Finance Farm
 */

pragma solidity 0.5.16;

interface IBEP20 {
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract StakeKingFarm is Context, Ownable {
  using SafeMath for uint256;

  struct TokenInfo {
    uint256 deposit;
    uint256 alloc;
    uint256 accShare;
    uint256 lastRewardBlock;
  }

  struct AccountInfo {
    uint256 deposit;
    uint256 rewardDebt;
    uint256 reserved;
  }

  struct ReferralInfo {
    uint256 deposit;
    uint256 lastReset;
  }

  mapping (address => TokenInfo) public tokenInfos;
  mapping (address => mapping (address => AccountInfo)) public accountInfos;
  mapping (address => ReferralInfo) private _referralInfos;
  mapping (address => address) private _referrers;
  address[] public topReferrers;
  uint256 public lastReferralReset;
  uint256 private _reserved;
  uint256 public alloc;
  uint256 private _startBlock;
  address private _pair;
  address public rewardToken;
  address private _wbnb;
  address private _router;

  constructor() public {
    _router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    _wbnb = IRouter(_router).WETH();
    _startBlock = 10731900;

    for (uint8 i = 0; i < 10; i++) {
      topReferrers.push(address(0));
    }

    lastReferralReset = block.number - 23 hours / 3;
  }

  function setRewardToken(address _rewardToken) external onlyOwner {
    require(rewardToken == address(0), "Already set reward token.");
    rewardToken = _rewardToken;
    _pair = IFactory(IRouter(_router).factory()).getPair(_wbnb, rewardToken);
  }

  function setTokenInfo(address token, uint256 _alloc) external onlyOwner {
    TokenInfo storage tokenInfo = tokenInfos[token];
    alloc = alloc.sub(tokenInfo.alloc).add(_alloc);
    tokenInfo.alloc = _alloc;
    tokenInfo.lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
  }

  function getReferralDeposit(address account) external view returns (uint256) {
    ReferralInfo storage referralInfo = _referralInfos[account];

    if (lastReferralReset > referralInfo.lastReset) {
      return 0;
    }

    return referralInfo.deposit;
  }

  function calcReward(address token, address account) external view returns (uint256) {
    TokenInfo memory tokenInfo = tokenInfos[token];
    uint256 accShare = tokenInfo.accShare;

    if (block.number > tokenInfo.lastRewardBlock && tokenInfo.deposit != 0) {
      uint256 reward = block.number.sub(tokenInfo.lastRewardBlock).mul(10 ** uint256(IBEP20(rewardToken).decimals()));
      uint256 balance = IBEP20(rewardToken).balanceOf(address(this));

      if (IBEP20(_pair).totalSupply() == 0) {
        balance = balance.sub(balance.div(2));
      }

      balance = balance.sub(_reserved).sub(tokenInfos[rewardToken].deposit);

      if (reward > balance) {
        reward = balance;
      }

      accShare = reward.mul(tokenInfo.alloc).div(alloc).mul(1e12).div(tokenInfo.deposit).add(accShare);
    }

    AccountInfo memory accountInfo = accountInfos[token][account];
    return accountInfo.deposit.mul(accShare).div(1e12).sub(accountInfo.rewardDebt).add(accountInfo.reserved);
  }

  function rewardAccount(address token) private returns (TokenInfo storage, AccountInfo storage) {
    TokenInfo storage tokenInfo = tokenInfos[token];

    if (block.number > tokenInfo.lastRewardBlock) {
      if (tokenInfo.deposit == 0) {
        tokenInfo.lastRewardBlock = block.number;
      } else {
        uint256 reward = block.number.sub(tokenInfo.lastRewardBlock).mul(10 ** uint256(IBEP20(rewardToken).decimals()));
        uint256 balance = IBEP20(rewardToken).balanceOf(address(this));

        if (IBEP20(_pair).totalSupply() == 0) {
          balance = balance.sub(balance.div(2));
        }

        balance = balance.sub(_reserved).sub(tokenInfos[rewardToken].deposit);

        if (reward > balance) {
          reward = balance;
        }

        tokenInfo.accShare = reward.mul(tokenInfo.alloc).div(alloc).mul(1e12).div(tokenInfo.deposit).add(tokenInfo.accShare);
        tokenInfo.lastRewardBlock = block.number;
      }
    }

    AccountInfo storage accountInfo = accountInfos[token][_msgSender()];
    uint256 reward = accountInfo.deposit.mul(tokenInfo.accShare).div(1e12).sub(accountInfo.rewardDebt);
    accountInfo.reserved = reward.add(accountInfo.reserved);

    if (reward != 0) {
      _reserved = reward.add(_reserved);
    }

    if (block.number >= _startBlock + 7 days / 3) {
      if (IBEP20(_pair).totalSupply() == 0) {
        uint256 amountA = IBEP20(_wbnb).balanceOf(address(this));

        if (amountA != 0) {
          uint256 amountB = IBEP20(rewardToken).balanceOf(address(this)).div(2);
          IBEP20(_wbnb).approve(_router, amountA);
          IBEP20(rewardToken).approve(_router, amountB);
          IRouter(_router).addLiquidity(_wbnb, rewardToken, amountA, amountB, 0, 0, 0x000000000000000000000000000000000000dEaD, block.timestamp);
        }
      }

      if (accountInfo.reserved != 0) {
        IBEP20(rewardToken).transfer(_msgSender(), accountInfo.reserved);
        emit ClaimReward(_msgSender(), accountInfo.reserved);
        _reserved = _reserved.sub(accountInfo.reserved);
        accountInfo.reserved = 0;
      }
    }

    return (tokenInfo, accountInfo);
  }

  function depositBNB(address referrer) external payable {
    (TokenInfo storage tokenInfo, AccountInfo storage accountInfo) = rewardAccount(_wbnb);

    if (msg.value != 0) {
      require(msg.value >= 1000, "Amount too low.");
      uint256 fee = msg.value.div(10); // 10%
      uint256 amount = msg.value.sub(fee);

      if (referrer != address(0) && referrer != _msgSender() && _referrers[_msgSender()] == address(0)) {
        _referrers[_msgSender()] = referrer;
      }

      referrer = _referrers[_msgSender()];

      if (block.number >= lastReferralReset + 14 days / 3) {
        for (uint8 i = 0; i < topReferrers.length; i++) {
          if (topReferrers[i] == address(0)) {
            break;
          }

          topReferrers[i] = address(0);
        }

        lastReferralReset = block.number;
      }

      if (referrer != address(0)) {
        ReferralInfo storage referralInfo = _referralInfos[referrer];

        if (lastReferralReset > referralInfo.lastReset) {
          referralInfo.deposit = 0;
          referralInfo.lastReset = lastReferralReset;
        }

        uint256 deposit = referralInfo.deposit + amount;
        referralInfo.deposit = deposit < referralInfo.deposit ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : deposit;

        for (uint8 i = 0; i < topReferrers.length; i++) {
          if (topReferrers[i] == referrer) {
            break;
          }

          if (referralInfo.deposit > _referralInfos[topReferrers[i]].deposit) {
            for (uint8 j = uint8(topReferrers.length) - 1; j > i; j--) {
              topReferrers[j] = topReferrers[j - 1];
            }

            topReferrers[i] = referrer;
            break;
          }
        }
      }

      uint8 referrers = 0;

      for (uint8 i = 0; i < topReferrers.length; i++) {
        if (topReferrers[i] == address(0)) {
          break;
        }

        referrers = referrers + 1;
      }

      if (referrers != 0) {
        uint256 referrerShare = fee.div(10 * referrers); // 10% of fee reserved for top referrers

        for (uint8 i = 0; i < referrers; i++) {
          (bool success, ) = topReferrers[i].call.value(referrerShare)("");
          require(success, "Rewarding referrer faled.");
          fee = fee.sub(referrerShare);
        }
      }

      (bool success, ) = _wbnb.call.value(fee)("");
      require(success, "Wrapping failed.");

      if (IBEP20(_pair).totalSupply() != 0) { // liquidity provided
        IBEP20(_wbnb).transfer(_pair, IBEP20(_wbnb).balanceOf(address(this)));
      }

      accountInfo.deposit = accountInfo.deposit.add(amount);
      tokenInfo.deposit = tokenInfo.deposit.add(amount);
      emit DepositBNB(_msgSender(), amount);
    }

    accountInfo.rewardDebt = accountInfo.deposit.mul(tokenInfo.accShare).div(1e12);
  }

  function depositToken(address token, uint256 amount) external {
    require(token != _wbnb, "Deposit BNB instead.");
    (TokenInfo storage tokenInfo, AccountInfo storage accountInfo) = rewardAccount(token);

    if (amount != 0) {
      uint256 balance = IBEP20(token).balanceOf(address(this));
      IBEP20(token).transferFrom(_msgSender(), address(this), amount);
      amount = IBEP20(token).balanceOf(address(this)).sub(balance); // consider tokens with transaction fees
      accountInfo.deposit = accountInfo.deposit.add(amount);
      tokenInfo.deposit = tokenInfo.deposit.add(amount);
      emit DepositToken(_msgSender(), token, amount);
    }

    accountInfo.rewardDebt = accountInfo.deposit.mul(tokenInfo.accShare).div(1e12);
  }

  function withdraw(address token, uint256 amount) external {
    (TokenInfo storage tokenInfo, AccountInfo storage accountInfo) = rewardAccount(token);

    if (amount != 0) {
      if (token == _wbnb) {
        accountInfo.deposit = accountInfo.deposit.sub(amount, "Amount too high.");
        tokenInfo.deposit = tokenInfo.deposit.sub(amount);
        (bool success, ) = _msgSender().call.value(amount)("");
        require(success, "Withdraw failed.");
        emit WithdrawBNB(_msgSender(), amount);
      } else {
        uint256 balance = IBEP20(token).balanceOf(address(this));

        if (amount > balance) { // evil contract?
          amount = balance;
        }

        accountInfo.deposit = accountInfo.deposit.sub(amount, "Amount too high.");
        tokenInfo.deposit = tokenInfo.deposit.sub(amount);
        IBEP20(token).transfer(_msgSender(), amount);
        emit WithdrawToken(_msgSender(), token, amount);
      }
    }

    accountInfo.rewardDebt = accountInfo.deposit.mul(tokenInfo.accShare).div(1e12);
  }

  event ClaimReward(address indexed account, uint256 amount);
  event DepositBNB(address indexed account, uint256 amount);
  event DepositToken(address indexed account, address indexed token, uint256 amount);
  event WithdrawBNB(address indexed account, uint256 amount);
  event WithdrawToken(address indexed account, address indexed token, uint256 amount);
}
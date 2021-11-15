// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
    function add(uint256 a, uint256 b) public pure returns (uint256) {
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

pragma solidity 0.8.0;

contract AccountChangable {
  address supervisor;
  address EMPTY_ADDRESS = address(0);
  mapping(address => address) oldToNew;
  mapping(address => address) newToOld;
  mapping(address => address) requests;

  constructor() { supervisor = msg.sender; }

  event ChangeAddressRequest(address oldAddress, address newAddress);
  event ApproveChangeAddressRequest(address oldAddress, address newAddress);

  function getOriginalAddress(address someAddress) public view returns(address) {
    if (newToOld[someAddress] != EMPTY_ADDRESS) return newToOld[someAddress];
    return someAddress;
  }
  
  function _originalMsgSender() internal view virtual returns (address) {
    require(!isReplaced(msg.sender), 'REPLACED');
    return getOriginalAddress(msg.sender);
  }

  function isReplaced(address oldAddress) internal view returns(bool) {
    return oldToNew[oldAddress] != EMPTY_ADDRESS;
  }

  function isNewAddress(address newAddress) public view returns(bool) {
    return newToOld[newAddress] != EMPTY_ADDRESS;
  }

  function getCurrentAddress(address someAddress) internal view returns(address) {
    if (oldToNew[someAddress] != EMPTY_ADDRESS) return oldToNew[someAddress];
    return someAddress;
  }

  function requestUpdateAddress(address newAddress) public {
    requests[msg.sender] = newAddress;
    emit ChangeAddressRequest(msg.sender, newAddress);
  }

  function accept(address oldAddress, address newAddress) public {
    require(msg.sender == supervisor, 'ONLY SUPERVISOR');
    require(newAddress != EMPTY_ADDRESS, 'NEW ADDRESS MUST NOT BE EMPTY');
    require(requests[oldAddress] == newAddress, 'INCORRECT NEW ADDRESS');
    requests[oldAddress] = EMPTY_ADDRESS;
    oldToNew[oldAddress] = newAddress;
    newToOld[newAddress] = oldAddress;
    emit ApproveChangeAddressRequest(oldAddress, newAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./4-account-changable.sol";
import "./0-ierc20.sol";
import "./0-safe-math.sol";

interface IMintable {
  function mint(address account, uint256 amount) external;
}

contract Farm is AccountChangable {
  using SafeMath for uint256;
  uint256 public totalWeight;
  IMintable public ticketToken;

  struct Pool {
    IERC20 lockToken;
    uint256 weight;
    uint256 accRewardPerOneGwei;
    uint256 lastRewardTime;
  }

  address public root;

  address public dev;
  address public saving;
  address public lotteryFund;
  address public adventureFund;

  Pool[] public pools;

  mapping(uint256 => mapping(address => Account)) public accounts;

  struct Account {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct User {
    uint256 level;
    address presenter;
  }

  mapping(address => User) public users;

  struct PoolInput {
    address lockToken;
    uint256 weight;
  }

  struct Config {
    address root;
    address ticketToken;
    address simToken;
    address dev;
    address saving;
    address lotteryFund;
    address adventureFund;
  }

  constructor(
    Config memory config,
    TimeRange[] memory _timeRanges,
    PoolInput[] memory _poolInputs
  ) {
    root = config.root;
    dev = config.dev;
    saving = config.saving;
    lotteryFund = config.lotteryFund;
    adventureFund = config.adventureFund;
    ticketToken = IMintable(config.ticketToken);
    simToken = IERC20(config.simToken);
    for (uint256 index = 0; index < _timeRanges.length; index++) {
      timeRanges.push(_timeRanges[index]);
    }
    for (uint256 index = 0; index < _poolInputs.length; index++) {
      PoolInput memory poolInput = _poolInputs[index];
      pools.push(Pool({
        lockToken: IERC20(poolInput.lockToken),
        weight: poolInput.weight,
        accRewardPerOneGwei: 0,
        lastRewardTime: 0
      }));
      totalWeight = totalWeight.add(poolInput.weight);
    }
    createUser(root, address(0));
    createUser(dev, root);
  }

  modifier onlyRoot() {
    require(_originalMsgSender() == root, 'ONLY_ROOT');
    _;
  }

  function setDev(address devAddress) public onlyRoot {
    require(users[devAddress].level > 0, 'INVALID_DEV_ADDRESS');
    dev = devAddress;
  }
  
  function setSaving(address savingAddress) public onlyRoot {
    saving = savingAddress;
  } 
  
  function setLotteryFund(address lotteryFundAddress) public onlyRoot {
    lotteryFund = lotteryFundAddress;
  }

  function setAdventureFund(address adventureFundAddress) public onlyRoot {
    adventureFund = adventureFundAddress;
  }

  // @PRODUCTION-WARNING @remove
  uint256 public skippedTime = 0;
  uint256 public overridedTime = 0;
  
  function skip(uint256 numberOfday) public {
    skippedTime = skippedTime.add(numberOfday.mul(86400));
  }

  function skipMilis(uint256 milis) public {
    skippedTime = skippedTime.add(milis);
  }
  
  function setOveridedTime(uint256 _overridedTime) public {
    overridedTime = _overridedTime;
  }

  function getNow() public view returns(uint256) {
    if (overridedTime > 0) return overridedTime;
    return skippedTime.add(block.timestamp);
  }
  
  /*
  function getNow() public view returns(uint256) {
    return block.timestamp;
  }
  */

  event Deposit(uint256 poolId, address account, uint256 value);
  
  function deposit(uint256 poolId, uint256 value, address presenter) public {
    require(value > 0, 'INVALID_VALUE');
    updatePool(poolId);
    harvest(poolId);
    address sender = _originalMsgSender();
    Pool memory pool = pools[poolId];
    createUser(sender, presenter);
    pool.lockToken.transferFrom(sender, address(this), value);
    Account storage account = accounts[poolId][sender];
    account.amount = account.amount.add(value);
    account.rewardDebt = account.amount.mul(pool.accRewardPerOneGwei).div(ONE_GWEI);
    emit Deposit(poolId, sender, value);
  }

  function isUser(address account) public view returns(bool) {
    return users[account].level != 0;
  }

  event CreateUser(address account, address presenter, uint256 level);

  // @PRODUCTION-WARNING @internal
  function createUser(address account, address presenter) public {
    if (isUser(account)) return;
    address normalizedPresenterAddress = normalizedPresenter(account, presenter);
    uint256 level = users[normalizedPresenterAddress].level + 1;
    users[account] = User({
      presenter: normalizedPresenterAddress,
      level: level
    });
    emit CreateUser(account, normalizedPresenterAddress, level);
  }

  function normalizedPresenter(address account, address presenter) public view returns(address) {
    address empty = address(0);
    if (account == root) return empty;
    if (presenter == empty) return root;
    require(isUser(presenter), 'INVALID_PRESENTER');
    return presenter;
  }

  event Withdraw(uint256 poolId, address account, uint256 value);

  function withdraw(uint256 poolId, uint256 value) public {
    updatePool(poolId);
    harvest(poolId);
    address sender = _originalMsgSender();
    Account storage account = accounts[poolId][sender];
    Pool memory pool = pools[poolId];
    account.amount = account.amount.sub(value, 'INSUFFICENT');
    account.rewardDebt = account.amount.div(ONE_GWEI).mul(pool.accRewardPerOneGwei);
    pool.lockToken.transfer(sender, value);
    emit Withdraw(poolId, sender, value);
  }

  function poolLength() public view returns (uint256) {
    return pools.length;
  }

  uint256 ONE_GWEI = 10 ** 9;

  function updatePool(uint256 poolId) public {
    Pool storage pool = pools[poolId];
    uint256 lockTokenBalance = pool.lockToken.balanceOf(address(this));
    if (lockTokenBalance == 0) return;
    uint256 currentTimestamp = getNow();
    uint256 newReward = getPoolRewardByTimeRange(
      pool.weight,
      totalWeight,
      pool.lastRewardTime,
      currentTimestamp
    );
    uint256 addition = newReward.mul(ONE_GWEI).div(lockTokenBalance);
    pool.accRewardPerOneGwei = pool.accRewardPerOneGwei.add(addition);
    pool.lastRewardTime = currentTimestamp;
  }

  struct TimeRange {
    uint256 from;
    uint256 to;
    uint256 amountOfTokenPerSecond;
  }

  TimeRange[] public timeRanges;

  function getPoolRewardByTimeRange(
    uint256 poolWeight,
    uint256 _totalWeight,
    uint256 from,
    uint256 to
  ) public view returns(uint256) {
    uint256 totalReward = 0;
    for (uint256 index = 0; index < timeRanges.length; index++) {
      TimeRange memory timeRange = timeRanges[index];
      totalReward += getCollapse(from, to, timeRange.from, timeRange.to).mul(timeRange.amountOfTokenPerSecond);
    }
    return totalReward.mul(poolWeight).div(_totalWeight);
  }

  function getCollapse(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns(uint256) {
    uint256 start = x1 > x2 ? x1 : x2;
    uint256 end = y1 < y2 ? y1 : y2;
    if (end < start) return 0;
    return end - start;
  }

  function getAccount(uint256 poolId, address account) public view returns (Account memory) {
    return accounts[poolId][account];
  }

  uint256 PAY_REASON_FARM_REWARD = 1;
  uint256 PAY_REASON_DIRECT_COMMISSION = 2;
  uint256 PAY_REASON_SAVING = 3;
  uint256 PAY_REASON_DEV_COMMISSION = 4;
  uint256 PAY_REASON_LOTTERY_FUND_COMMISSION = 5;
  uint256 PAY_REASON_ADVENTURE_FUND_COMMISSION = 6;

  uint256 public DIRECT_COMMISSION = 5;
  uint256 public DEV_COMMISSION = 10;
  uint256 public LOTTERY_FUND_COMMISSION = 5;
  uint256 public ADVENTURE_FUND_COMMISSION = 10;

  // @PRODUCTION-WARNING @internal
  function harvest(uint256 poolId) public {
    address sender = _originalMsgSender();
    Account storage account = accounts[poolId][sender];
    Pool memory pool = pools[poolId];
    uint256 pendingReward = account.amount.div(ONE_GWEI).mul(pool.accRewardPerOneGwei).sub(account.rewardDebt);
    if (pendingReward == 0) return;
    account.rewardDebt = account.rewardDebt.add(pendingReward);
    uint256 ONE_HUNDRED_PERCENT = 100;
    uint256 rate = ONE_HUNDRED_PERCENT
      .sub(DIRECT_COMMISSION)
      .sub(DEV_COMMISSION)
      .sub(LOTTERY_FUND_COMMISSION)
      .sub(ADVENTURE_FUND_COMMISSION);
    pay(sender, pendingReward.mul(rate).div(100), PAY_REASON_FARM_REWARD);
    payCommission(sender, pendingReward);
  }

  function getPendingReward(uint256 poolId, address account) public view returns(uint256) {
    Pool storage pool = pools[poolId];
    uint256 lockTokenBalance = pool.lockToken.balanceOf(address(this));
    if (lockTokenBalance == 0) return 0;
    uint256 currentTimestamp = getNow();
    uint256 newReward = getPoolRewardByTimeRange(
      pool.weight,
      totalWeight,
      pool.lastRewardTime,
      currentTimestamp
    );
    uint256 addition = newReward.mul(ONE_GWEI).div(lockTokenBalance);
    uint256 currentAccRewardPerOneGwei = pool.accRewardPerOneGwei.add(addition);
    Account memory accountInfo = getAccount(poolId, account);
    return currentAccRewardPerOneGwei.mul(accountInfo.amount).div(ONE_GWEI).sub(accountInfo.rewardDebt);
  }

  event Pay(address account, uint256 value, uint256 reason);
  
  // @PRODUCTION-WARNING @internal
  function payCommission(address account, uint256 totalReward) public {
    CommissionPayment[4] memory commissionPayments = getCommissionPayments(account);
    for (uint256 index = 0; index < commissionPayments.length; index++) {
      CommissionPayment memory commissionPayment = commissionPayments[index];
      if (commissionPayment.receiver == address(0)) continue;
      pay(
        commissionPayment.receiver,
        totalReward.mul(commissionPayment.rate).div(100),
        commissionPayment.reason
      );
    }
  }

  struct CommissionPayment {
    address receiver;
    uint256 rate;
    uint256 reason;
  }

  IERC20 public simToken;

  function getCommissionPayments(address fromAccount) public view returns(CommissionPayment[4] memory result) {
    result[0] = CommissionPayment({
      receiver: dev,
      rate: DEV_COMMISSION,
      reason: PAY_REASON_DEV_COMMISSION
    });

    address presenterAddress = users[fromAccount].presenter;
    uint256 SIM_BALANCE_REQUIRED = 500 ether;
    bool shouldPresenterReceiveDirectCommission = (
      presenterAddress != address(0) &&
      simToken.balanceOf(presenterAddress) >= SIM_BALANCE_REQUIRED
    );
    if (shouldPresenterReceiveDirectCommission) {
      result[1] = CommissionPayment({
        receiver: presenterAddress,
        rate: PAY_REASON_DIRECT_COMMISSION,
        reason: DIRECT_COMMISSION          
      });
    } else {
      result[1] = CommissionPayment({
        receiver: saving,
        rate: PAY_REASON_SAVING,
        reason: DIRECT_COMMISSION          
      });
    }
    result[2] = CommissionPayment({
      receiver: lotteryFund,
      rate: LOTTERY_FUND_COMMISSION,
      reason: PAY_REASON_LOTTERY_FUND_COMMISSION
    });
    
    result[3] = CommissionPayment({
      receiver: adventureFund,
      rate: ADVENTURE_FUND_COMMISSION,
      reason: PAY_REASON_ADVENTURE_FUND_COMMISSION
    });

    return result;
  }

  function pay(address account, uint256 value, uint256 reason) public {
    ticketToken.mint(account, value);
    emit Pay(account, value, reason);
  }

  function claimReward(uint256 poolId) public {
    updatePool(poolId);
    harvest(poolId);
  }

  struct Payment {
    address receiver;
    uint256 value;
    uint256 reason;
  }

  function getUsers(address[] memory userAddresses) public view returns(User[] memory result) {
    uint256 length = userAddresses.length;
    result = new User[](length);
    for (uint256 index = 0; index < length; index++) {
      result[index] = users[userAddresses[index]];
    }
    return result;
  }
  
  function getAccounts(address[] memory userAddresses) public view returns(Account[] memory result) {
    uint256 poolsLength = pools.length;
    uint256 addressesLength = userAddresses.length;
    result = new Account[](userAddresses.length * poolsLength);
    for (uint256 addressIndex = 0; addressIndex < addressesLength; addressIndex++) {
      for (uint256 poolIndex = 0; poolIndex < poolsLength; poolIndex++) {
        result[poolsLength * addressIndex + poolIndex] = accounts[poolIndex][userAddresses[addressIndex]];
      }
    }
    return result;
  }
}


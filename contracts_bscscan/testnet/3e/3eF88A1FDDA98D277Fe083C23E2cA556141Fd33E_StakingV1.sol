// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IStakingV1 } from "./IStakingV1.sol";
import { Address } from "./library/Address.sol";
import { Authorizable } from "./Authorizable.sol";
import { Pausable } from "./Pausable.sol";
import { IDCounter } from "./IDCounter.sol";
import { IERC20 } from "./library/IERC20.sol";
import { ReentrancyGuard } from "./library/ReentrancyGuard.sol";
import { SafeERC20 } from "./library/SafeERC20.sol";
import { Util } from "./Util.sol";
import { Math } from "./Math.sol";

struct StakerData {
  bool autoClaimOptOut;
  /** amount currently staked */
  uint256 amount;
  /** total amount of eth claimed */
  uint256 totalClaimed;
  uint256 totalExcluded;
  uint256 lastDeposit;
  uint256 lastClaim;
}

contract StakingV1 is IStakingV1, Authorizable, Pausable, ReentrancyGuard {
  /** libraries */
  using Address for address payable;
  using SafeERC20 for IERC20;

  constructor(
    address owner_,
    address tokenAddress_,
    string memory name_,
    uint16 lockDurationDays_
  ) Authorizable(owner_) {
    //
    _token = IERC20(tokenAddress_);
    _name = name_;
    _decimals = _token.decimals();
    _lockDurationDays = lockDurationDays_;
  }

  /** @dev reference to the staked token */
  IERC20 internal immutable _token;

  /** @dev name of this staking instance */
  string internal _name;

  /** @dev cached copy of the staked token decimals value */
  uint8 internal immutable _decimals;

  uint16 internal _lockDurationDays;

  uint256 internal _totalStaked;
  uint256 internal _totalClaimed;

  uint256 internal _lastBalance;
  uint256 internal _rewardsPerToken;
  uint256 internal _accuracy = 10 ** 18;

  /** @dev current number of stakers */
  uint64 internal _currentNumStakers;

  /** @dev total number of stakers - not reduced when a staker withdraws all */
  uint64 internal _totalNumStakers;

  /** @dev used to limit the amount of gas spent during auto claim */
  uint256 internal _autoClaimGasLimit = 200000;

  /** @dev current index used for auto claim iteration */
  uint64 internal _autoClaimIndex;

  bool internal _autoClaimEnabled = true;

  /** @dev should autoClaim be run automatically on deposit? */
  bool internal _autoClaimOnDeposit = true;

  /** @dev should autoClaim be run automatically on manual claim? */
  bool internal _autoClaimOnClaim = true;

  /** @dev account => staker data */
  mapping(address => StakerData) internal _stakers;

  /** @dev this is essentially an index in the order that new users are added. */
  mapping(uint64 => address) internal _autoClaimQueue;
  /** @dev reverse lookup for _autoClaimQueue. allows getting index by address */
  mapping(address => uint64) internal _autoClaimQueueReverse;

  // modifier autoClaimAfter {
  //   _;
  //   _autoClaim();
  // }

  function _totalRewards() internal virtual view returns (uint256) {
    return _getRewardsBalance() + _totalClaimed;
  }

  function rewardsAreToken() public virtual override pure returns (bool) {
    return false;
  }

  function autoClaimEnabled() external virtual override view returns (bool) {
    return _autoClaimEnabled;
  }

  function setAutoClaimEnabled(bool value) external virtual override {
    _autoClaimEnabled = value;
  }

  function accuracy() external virtual override view returns (uint256) {
    return _accuracy;
  }

  function setAccuracy(uint256 value) external virtual override onlyAuthorized {
    _rewardsPerToken = _rewardsPerToken * value / _accuracy;
    _accuracy = value;
  }

  function setAutoClaimOnDeposit(bool value) external virtual override onlyAuthorized {
    _autoClaimOnDeposit = value;
  }

  function setAutoClaimOnClaim(bool value) external virtual override onlyAuthorized {
    _autoClaimOnClaim = value;
  }

  function getAutoClaimOptOut(address account) external virtual override view returns (bool) {
    return _stakers[account].autoClaimOptOut;
  }

  function setAutoClaimOptOut(bool value) external virtual override {
    _stakers[_msgSender()].autoClaimOptOut = value;
  }

  /**
   * @dev allow removing the lock duration, but not setting it directly.
   * this removes the possibility of creating a long lock duration after
   * people have deposited their tokens, essentially turning the staking
   * contract into a honeypot.
   *
   * removing the lock is necessary in case of emergencies,
   * like migrating to a new staking contract.
   */
  function removeLockDuration() external virtual override onlyAuthorized {
    _lockDurationDays = 0;
  }

  function getPlaceInQueue(address account) external virtual override view returns (uint256) {
    if (_autoClaimQueueReverse[account] >= _autoClaimIndex)
      return _autoClaimQueueReverse[account] - _autoClaimIndex;

    return _totalNumStakers - (_autoClaimIndex - _autoClaimQueueReverse[account]);
  }

  function autoClaimGasLimit() external virtual override view returns (uint256) {
    return _autoClaimGasLimit;
  }

  function setAutoClaimGasLimit(uint256 value) external virtual override onlyAuthorized {
    _autoClaimGasLimit = value;
  }

  /** @return the address of the staked token */
  function token() external virtual override view returns (address) {
    return address(_token);
  }

  function getStakingData() external virtual override view returns (
    address stakedToken,
    string memory name,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  ) {
    stakedToken = address(_token);
    name = _name;
    decimals = _decimals;
    totalStaked = _totalStaked;
    totalRewards = _totalRewards();
    totalClaimed = _totalClaimed;
  }

  function getStakingDataForAccount(address account) external virtual override view returns (
    uint256 amount,
    uint64 lastClaimedAt,
    uint256 pendingRewards,
    uint256 totalClaimed
  ) {
    amount = _stakers[account].amount;
    lastClaimedAt = uint64(_lastClaimTime(account));
    pendingRewards = _pending(account);
    totalClaimed = _stakers[account].totalClaimed;
  }

  function _earned(address account) internal virtual view returns (uint256) {
    if (_stakers[account].amount == 0)
      return 0;

    uint256 rewards = _getCumalativeRewards(_stakers[account].amount);
    uint256 excluded = _stakers[account].totalExcluded;

    return rewards > excluded ? rewards - excluded : 0;
  }

  function _pending(address account) internal virtual view returns (uint256) {
    if (_stakers[account].amount == 0)
      return 0;
    
    uint256 rewards = _stakers[account].amount * _getRewardsPerToken() / _accuracy;
    uint256 excluded = _stakers[account].totalExcluded;

    return rewards > excluded ? rewards - excluded : 0;
  }

  function pending(address account) external virtual override view returns (uint256) {
    return _pending(account);
  }

  function _sendRewards(address account, uint256 amount) internal virtual {
    payable(account).sendValue(amount);
  }

  function _claim(address account) internal virtual returns (bool) {
    _updateRewards();

    uint256 pendingRewards = _earned(account);

    if (_stakers[account].amount == 0 || pendingRewards == 0)
      return false;

    _stakers[account].totalClaimed += pendingRewards;
    _stakers[account].totalExcluded += pendingRewards;
    _stakers[account].lastClaim = block.timestamp;
    _totalClaimed += pendingRewards;

    _sendRewards(account, pendingRewards);

    _updateRewards();

    emit ClaimedRewards(account, pendingRewards);

    return true;
  }

  function claimFor(address account, bool revertOnFailure, bool doAutoClaim) external virtual override nonReentrant {
    if (revertOnFailure)
      require(_claim(account), "Claim failed");
    else
      _claim(account);

    if (doAutoClaim) _autoClaim();
  }

  function claim() external virtual override nonReentrant {
    require(_claim(_msgSender()), "Claim failed");

    if (_autoClaimOnClaim) _autoClaim();
  }

  function _deposit(address account, uint256 amount) internal virtual onlyNotPaused {
    require(amount != 0, "Deposit amount cannot be 0");

    // claim before depositing
    _claim(account);

    if (_autoClaimQueueReverse[account] == 0) {
      _totalNumStakers++;
      _currentNumStakers++;
      _autoClaimQueueReverse[account] = _totalNumStakers;
      _autoClaimQueue[_totalNumStakers] = account;
    }

    _stakers[account].amount += amount;
    _stakers[account].totalExcluded = _getCumalativeRewards(_stakers[account].amount);
    _stakers[account].lastDeposit = block.timestamp;
    _totalStaked += amount;

    // store previous balance to determine actual amount transferred
    uint256 oldBalance = _token.balanceOf(address(this));
    // make the transfer
    _token.safeTransferFrom(account, address(this), amount);
    // check for lost tokens - this is an unsupported situation currently.
    // tokens could be lost during transfer if the token has tax.
    require(
      amount == _token.balanceOf(address(this)) - oldBalance,
      "Lost tokens during transfer"
    );

    emit DepositedTokens(account, amount);
  }

  /**
   * @dev deposit amount of tokens to the staking pool.
   * reverts if tokens are lost during transfer.
   */
  function deposit(uint256 amount) external virtual override nonReentrant {
    _deposit(_msgSender(), amount);
  }

  function _getUnlockTime(address account) internal virtual view returns (uint64) {
    return _lockDurationDays == 0 ? 0 : uint64(_lastClaimTime(account)) + (uint64(_lockDurationDays) * 86400);
  }

  function getUnlockTime(address account) external virtual override view returns (uint64) {
    return _getUnlockTime(account);
  }

  function _withdraw(address account, uint256 amount, bool claimFirst) internal virtual {
    require(
      _stakers[account].amount != 0 && _stakers[account].amount >= amount,
      "Attempting to withdraw too many tokens"
    );

    if (_lockDurationDays != 0)
      require(
        block.timestamp > _getUnlockTime(account),
        "Wait for tokens to unlock before withdrawing"
      );

    if (claimFirst)
      _claim(account);

    _stakers[account].amount -= amount;
    _stakers[account].totalExcluded = _getCumalativeRewards(_stakers[account].amount);
    _totalStaked -= amount;

    if (_stakers[account].amount == 0) {
      // decrement current number of stakers
      _currentNumStakers--;
      // remove account from auto claim queue
      _autoClaimQueue[_autoClaimQueueReverse[account]] = address(0);
      _autoClaimQueueReverse[account] = 0;
    }

    // transfer eth after modifying internal state
    _token.safeTransfer(account, amount);

    emit WithdrewTokens(account, amount);
  }

  function withdraw(uint256 amount) external virtual override nonReentrant {
    _withdraw(_msgSender(), amount, true);
  }

  /** this withdraws all and skips the claiming step */
  function emergencyWithdraw() external virtual override nonReentrant {
    _withdraw(_msgSender(), _stakers[_msgSender()].amount, false);
  }

  function _lastClaimTime(address account) internal virtual view returns (uint256) {
    return _stakers[account].lastClaim;
  }

  function _depositRewards(address account, uint256 amount) internal virtual onlyNotPaused {
    require(amount != 0, "Receive value cannot be 0");

    // _totalRewards += amount;

    emit DepositedEth(account, amount);
  }

  function _autoClaim() internal virtual {
    if (!_autoClaimEnabled) return;

    uint256 startingGas = gasleft();
    uint256 iterations = 0;

    while (startingGas - gasleft() < _autoClaimGasLimit && iterations++ < _totalNumStakers) {
      // use unchecked here so index can overflow, since it doesn't matter.
      // this prevents the incredibly unlikely future problem of running
      // into an overflow error and probably saves some gas
      uint64 index;
      unchecked {
        index = _autoClaimIndex++;
      }

      address autoClaimAddress = _autoClaimQueue[1 + (index % _totalNumStakers)];

      if (!_stakers[autoClaimAddress].autoClaimOptOut)
        _claim(autoClaimAddress);
    }
  }

  /** @dev allow anyone to process autoClaim functionality manually */
  function processAutoClaim() external virtual override nonReentrant {
    _autoClaim();
  }

  function _getRewardsPerToken() internal virtual view returns (uint256) {
    uint256 rewardsBalance = _getRewardsBalance();

    if (rewardsBalance < _lastBalance || _totalStaked == 0)
      return 0;

    return _rewardsPerToken + ((rewardsBalance - _lastBalance) * _accuracy / _totalStaked);
  }

  function _updateRewards() internal virtual {
    uint256 rewardsBalance = _getRewardsBalance();

    if (rewardsBalance > _lastBalance && _totalStaked != 0)
      _rewardsPerToken += (rewardsBalance - _lastBalance) * _accuracy / _totalStaked;

    if (_totalStaked != 0)
      _lastBalance = rewardsBalance;
  }

  function _getCumalativeRewards(uint256 amount) internal virtual view returns (uint256) {
    return amount * _rewardsPerToken / _accuracy;
  }

  function _getRewardsBalance() internal virtual view returns (uint256) {
    return address(this).balance;
  }

  receive() external virtual payable nonReentrant {
    _depositRewards(_msgSender(), msg.value);

    if (_autoClaimOnDeposit) _autoClaim();
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface IStakingV1 {
  /** events */
  event DepositedEth(address indexed account, uint256 amount);
  event DepositedTokens(address indexed account, uint256 amount);
  event WithdrewTokens(address indexed account, uint256 amount);
  event ClaimedRewards(address indexed account, uint256 amount);

  function rewardsAreToken() external pure returns (bool);
  function autoClaimEnabled() external view returns (bool);
  function setAutoClaimEnabled(bool value) external;
  function accuracy() external view returns (uint256);
  function setAccuracy(uint256 value) external;
  function setAutoClaimOnDeposit(bool value) external;
  function setAutoClaimOnClaim(bool value) external;
  function getAutoClaimOptOut(address account) external view returns (bool);
  function setAutoClaimOptOut(bool value) external;
  function removeLockDuration() external;
  function getPlaceInQueue(address account) external view returns (uint256);
  function autoClaimGasLimit() external view returns (uint256);
  function setAutoClaimGasLimit(uint256 value) external;
  function token() external view returns (address);
  function getStakingData() external view returns (
    address stakedToken,
    string memory name,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  );
  function getStakingDataForAccount(address account) external view returns (
    uint256 amount,
    uint64 lastClaimedAt,
    uint256 pendingRewards,
    uint256 totalClaimed
  );
  function pending(address account) external view returns (uint256);
  function claimFor(address account, bool revertOnFailure, bool doAutoClaim) external;
  function claim() external;
  function deposit(uint256 amount) external;
  function getUnlockTime(address account) external view returns (uint64);
  function withdraw(uint256 amount) external;
  function emergencyWithdraw() external;
  function processAutoClaim() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Ownable } from "./Ownable.sol";

abstract contract Authorizable is Ownable {
  event Authorized(address indexed account, bool value);

  constructor(address owner_) Ownable(owner_) {
    //
  }

  mapping(address => bool) internal _authorized;

  modifier onlyAuthorized() {
    require(_isAuthorized(_msgSender()), "Unauthorized");
    _;
  }

  function _isAuthorized(address account) internal virtual view returns (bool) {
    // always return true for the owner
    return account == _owner() ? true : _authorized[account];
  }

  function isAuthorized() external view returns (bool) {
    return _isAuthorized(_msgSender());
  }

  function _authorize(address account, bool value) internal virtual {
    _authorized[account] = value;

    emit Authorized(account, value);
  }

  /** @dev only allow the owner to authorize more accounts */
  function authorize(address account, bool value) external onlyOwner {
    _authorize(account, value);
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Ownable } from "./Ownable.sol";

abstract contract Pausable is Ownable {
  bool internal _paused;

  modifier onlyNotPaused() {
    require(!_paused, "Contract is paused");
    _;
  }

  function paused() external view returns (bool) {
    return _paused;
  }

  function _setPaused(bool value) internal virtual {
    _paused = value;
  }

  function setPaused(bool value) external onlyOwner {
    _setPaused(value);
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IIDCounter } from "./IIDCounter.sol";

abstract contract IDCounter is IIDCounter {
  uint256 internal _count;

  function count() external view override returns (uint256) {
    return _count;
  }

  function _next() internal virtual returns (uint256) {
    return _count++;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IERC20 } from "./library/IERC20.sol";
import { IUniswapV2Pair } from "./library/Dex.sol";

library Util {
  /**
   * @dev retrieves basic information about a token, including sender balance
   */
  function getTokenData(address address_) external view returns (
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 totalSupply,
    uint256 balance
  ){
    IERC20 _token = IERC20(address_);

    name = _token.name();
    symbol = _token.symbol();
    decimals = _token.decimals();
    totalSupply = _token.totalSupply();
    balance = _token.balanceOf(msg.sender);
  }

  /**
   * @dev this throws an error on false, instead of returning false,
   * but can still be used the same way on frontend.
   */
  function isLpToken(address address_) external view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(address_);

    try pair.token0() returns (address tokenAddress_) {
      // any address returned successfully should be valid?
      // but we might as well check that it's not 0
      return tokenAddress_ != address(0);
    } catch Error(string memory /* reason */) {
      return false;
    } catch (bytes memory /* lowLevelData */) {
      return false;
    }
  }

  /**
   * @dev this function will revert the transaction if it's called
   * on a token that isn't an LP token. so, it's recommended to be
   * sure that it's being called on an LP token, or expect the error.
   */
  function getLpData(address address_) external view returns (
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    IUniswapV2Pair _pair = IUniswapV2Pair(address_);

    token0 = _pair.token0();
    token1 = _pair.token1();

    balance0 = IERC20(token0).balanceOf(address(_pair));
    balance1 = IERC20(token1).balanceOf(address(_pair));

    price0 = _pair.price0CumulativeLast();
    price1 = _pair.price1CumulativeLast();
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

library Math {
  function clamp8(uint8 n, uint8 min, uint8 max) pure internal returns (uint8) {
    return n > min ? n < max ? n : max : min;
  }

  function clamp16(uint16 n, uint16 min, uint16 max) pure internal returns (uint16) {
    return n > min ? n < max ? n : max : min;
  }

  /**
   * @dev Calculate x * y / scale rounding down.
   *
   * https://ethereum.stackexchange.com/a/79736
   */
  function mulScale(uint256 x, uint256 y, uint128 scale) pure internal returns (uint256) {
    uint256 a = x / scale;
    uint256 b = x % scale;
    uint256 c = y / scale;
    uint256 d = y % scale;

    return a * c * scale + a * d + b * c + b * d / scale;
  }

  /**
   * @return `numerator` percentage of `denominator`
   *
   * https://ethereum.stackexchange.com/a/18877
   * https://stackoverflow.com/a/42739843
   */
  function percent(uint256 numerator, uint256 denominator, uint256 precision) pure internal returns (uint256) {
    // caution, check safe-to-multiply here
    // NOTE - solidity 0.8 and above throws on overflows automatically
    uint256 _numerator = numerator * 10 ** (precision+1);
    // with rounding of last digit
    return ((_numerator / denominator) + 5) / 10;
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Context } from "./library/Context.sol";

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract Ownable is Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address private _owner_;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function _owner() internal view returns (address) {
    return _owner_;
  }

  function owner() external view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) virtual internal onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external onlyOwner {
    _transferOwnership(newOwner_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface IIDCounter {
  function count() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}
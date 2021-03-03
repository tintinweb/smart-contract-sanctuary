// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./utils/Address.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./ERC20/SafeERC20.sol";
import "./interfaces/IBonusRewards.sol";

/**
 * @title Bonus Token Rewards contract
 * @author crypto-pumpkin
 * @notice ETH is not allowed to be an bonus token, use wETH instead
 * @notice We support multiple bonus tokens for each pool. However, each pool will have 1 bonus token normally, may have 2 in rare cases
 */
contract BonusRewards is IBonusRewards, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  bool public paused;
  uint256 private constant WEEK = 7 days;
  // help calculate rewards/bonus PerToken only. 1e12 will allow meaningful $1 deposit in a $1bn pool  
  uint256 private constant CAL_MULTIPLIER = 1e30;
  // use array to allow convinient replacement. Size of responders should be very small to 0 till a reputible responder multi-sig within DeFi or Yearn ecosystem is established
  address[] private responders;
  address[] private poolList;
  // lpToken => Pool
  mapping(address => Pool) private pools;
  // lpToken => User address => User data
  mapping(address => mapping(address => User)) private users;
  // use array to allow convinient replacement. Size of Authorizers should be very small (one or two partner addresses for the pool and bonus)
  // lpToken => bonus token => [] allowed authorizers to add bonus tokens
  mapping(address => mapping(address => address[])) private allowedTokenAuthorizers;
  // bonusTokenAddr => 1, used to avoid collecting bonus token when not ready
  mapping(address => uint8) private bonusTokenAddrMap;

  modifier notPaused() {
    require(!paused, "BonusRewards: paused");
    _;
  }

  constructor () {
    initializeOwner();
  }

  function claimRewardsForPools(address[] calldata _lpTokens) external override nonReentrant notPaused {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      address lpToken = _lpTokens[i];
      User memory user = users[lpToken][msg.sender];
      if (user.amount == 0) continue;
      _updatePool(lpToken);
      _claimRewards(lpToken, user);
      _updateUserWriteoffs(lpToken);
    }
  }

  function deposit(address _lpToken, uint256 _amount) external override nonReentrant notPaused {
    require(pools[_lpToken].lastUpdatedAt > 0, "Blacksmith: pool does not exists");
    require(IERC20(_lpToken).balanceOf(msg.sender) >= _amount, "Blacksmith: insufficient balance");

    _updatePool(_lpToken);
    User storage user = users[_lpToken][msg.sender];
    _claimRewards(_lpToken, user);

    IERC20 token = IERC20(_lpToken);
    uint256 balanceBefore = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 received = token.balanceOf(address(this)) - balanceBefore;

    user.amount = user.amount + received;
    _updateUserWriteoffs(_lpToken);
    emit Deposit(msg.sender, _lpToken, received);
  }

  /// @notice withdraw up to all user deposited
  function withdraw(address _lpToken, uint256 _amount) external override nonReentrant notPaused {
    require(pools[_lpToken].lastUpdatedAt > 0, "Blacksmith: pool does not exists");
    _updatePool(_lpToken);

    User storage user = users[_lpToken][msg.sender];
    _claimRewards(_lpToken, user);
    uint256 amount = user.amount > _amount ? _amount : user.amount;
    user.amount = user.amount - amount;
    _updateUserWriteoffs(_lpToken);

    _safeTransfer(_lpToken, amount);
    emit Withdraw(msg.sender, _lpToken, amount);
  }

  /// @notice withdraw all without rewards
  function emergencyWithdraw(address[] calldata _lpTokens) external override nonReentrant {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      User storage user = users[_lpTokens[i]][msg.sender];
      uint256 amount = user.amount;
      user.amount = 0;
      _safeTransfer(_lpTokens[i], amount);
      emit Withdraw(msg.sender, _lpTokens[i], amount);
    }
  }

  /// @notice called by authorizers only
  function addBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint48 _startTime,
    uint256 _weeklyRewards,
    uint256 _transferAmount
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");
    require(_startTime >= block.timestamp, "BonusRewards: startTime in the past");

    // make sure the pool is in the right state (exist with no active bonus at the moment) to add new bonus tokens
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt > 0, "BonusRewards: pool does not exist");
    Bonus[] memory bonuses = pool.bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      if (bonuses[i].bonusTokenAddr == _bonusTokenAddr) {
        // when there is alreay a bonus program with the same bonus token, make sure the program has ended properly
        require(bonuses[i].endTime + WEEK < block.timestamp, "BonusRewards: last bonus period hasn't ended");
        require(bonuses[i].remBonus == 0, "BonusRewards: last bonus not all claimed");
      }
    }

    IERC20 bonusTokenAddr = IERC20(_bonusTokenAddr);
    uint256 balanceBefore = bonusTokenAddr.balanceOf(address(this));
    bonusTokenAddr.safeTransferFrom(msg.sender, address(this), _transferAmount);
    uint256 received = bonusTokenAddr.balanceOf(address(this)) - balanceBefore;
    // endTime is based on how much tokens transfered v.s. planned weekly rewards
    uint48 endTime = uint48(received * WEEK / _weeklyRewards + _startTime);

    pools[_lpToken].bonuses.push(Bonus({
      bonusTokenAddr: _bonusTokenAddr,
      startTime: _startTime,
      endTime: endTime,
      weeklyRewards: _weeklyRewards,
      accRewardsPerToken: 0,
      remBonus: received
    }));
  }

  /// @notice called by authorizers only, update weeklyRewards (if not ended), or update startTime (only if rewards not started, 0 is ignored)
  function updateBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint256 _weeklyRewards,
    uint48 _startTime
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");
    require(_startTime == 0 || _startTime > block.timestamp, "BonusRewards: startTime in the past");

    // make sure the pool is in the right state (exist with no active bonus at the moment) to add new bonus tokens
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt > 0, "BonusRewards: pool does not exist");
    Bonus[] memory bonuses = pool.bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      if (bonuses[i].bonusTokenAddr == _bonusTokenAddr && bonuses[i].endTime > block.timestamp) {
        Bonus storage bonus = pools[_lpToken].bonuses[i];
        _updatePool(_lpToken); // update pool with old weeklyReward to this block
        if (bonus.startTime >= block.timestamp) {
          // only honor new start time, if program has not started
          if (_startTime >= block.timestamp) {
            bonus.startTime = _startTime;
          }
          bonus.endTime = uint48(bonus.remBonus * WEEK / _weeklyRewards + bonus.startTime);
        } else {
          // remaining bonus to distribute * week
          uint256 remBonusToDistribute = (bonus.endTime - block.timestamp) * bonus.weeklyRewards;
          bonus.endTime = uint48(remBonusToDistribute / _weeklyRewards + block.timestamp);
        }
        bonus.weeklyRewards = _weeklyRewards;
      }
    }
  }

  /// @notice extend the current bonus program, the program has to be active (endTime is in the future)
  function extendBonus(
    address _lpToken,
    uint256 _poolBonusId,
    address _bonusTokenAddr,
    uint256 _transferAmount
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");

    Bonus memory bonus = pools[_lpToken].bonuses[_poolBonusId];
    require(bonus.bonusTokenAddr == _bonusTokenAddr, "BonusRewards: bonus and id dont match");
    require(bonus.endTime > block.timestamp, "BonusRewards: bonus program ended, please start a new one");

    IERC20 bonusTokenAddr = IERC20(_bonusTokenAddr);
    uint256 balanceBefore = bonusTokenAddr.balanceOf(address(this));
    bonusTokenAddr.safeTransferFrom(msg.sender, address(this), _transferAmount);
    uint256 received = bonusTokenAddr.balanceOf(address(this)) - balanceBefore;
    // endTime is based on how much tokens transfered v.s. planned weekly rewards
    uint48 endTime = uint48(received * WEEK / bonus.weeklyRewards + bonus.endTime);

    pools[_lpToken].bonuses[_poolBonusId].endTime = endTime;
    pools[_lpToken].bonuses[_poolBonusId].remBonus = bonus.remBonus + received;
  }

  /// @notice add pools and authorizers to add bonus tokens for pools, combine two calls into one. Only reason we add pools is when bonus tokens will be added
  function addPoolsAndAllowBonus(
    address[] calldata _lpTokens,
    address[] calldata _bonusTokenAddrs,
    address[] calldata _authorizers
  ) external override onlyOwner notPaused {
    // add pools
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      address _lpToken = _lpTokens[i];
      require(IERC20(_lpToken).decimals() <= 18, "BonusRewards: lptoken decimals > 18");
      if (pools[_lpToken].lastUpdatedAt == 0) {
        pools[_lpToken].lastUpdatedAt = currentTime;
        poolList.push(_lpToken);
      }

      // add bonus tokens and their authorizers (who are allowed to add the token to pool)
      for (uint256 j = 0; j < _bonusTokenAddrs.length; j++) {
        address _bonusTokenAddr = _bonusTokenAddrs[j];
        require(pools[_bonusTokenAddr].lastUpdatedAt == 0, "BonusRewards: lpToken, not allowed");
        allowedTokenAuthorizers[_lpToken][_bonusTokenAddr] = _authorizers;
        bonusTokenAddrMap[_bonusTokenAddr] = 1;
      }
    }
  }

  /// @notice collect bonus token dust to treasury
  function collectDust(address _token, address _lpToken, uint256 _poolBonusId) external override onlyOwner {
    require(pools[_token].lastUpdatedAt == 0, "BonusRewards: lpToken, not allowed");

    if (_token == address(0)) { // token address(0) = ETH
      Address.sendValue(payable(owner()), address(this).balance);
    } else {
      uint256 balance = IERC20(_token).balanceOf(address(this));
      if (bonusTokenAddrMap[_token] == 1) {
        // bonus token
        Bonus memory bonus = pools[_lpToken].bonuses[_poolBonusId];
        require(bonus.bonusTokenAddr == _token, "BonusRewards: wrong pool");
        require(bonus.endTime + WEEK < block.timestamp, "BonusRewards: not ready");
        balance = bonus.remBonus;
        pools[_lpToken].bonuses[_poolBonusId].remBonus = 0;
      }

      IERC20(_token).safeTransfer(owner(), balance);
    }
  }

  function setResponders(address[] calldata _responders) external override onlyOwner {
    responders = _responders;
  }

  function setPaused(bool _paused) external override {
    require(_isAuthorized(responders), "BonusRewards: caller not responder");
    emit PausedStatusUpdated(msg.sender, paused, _paused);
    paused = _paused;
  }

  function getPool(address _lpToken) external view override returns (Pool memory) {
    return pools[_lpToken];
  }

  function getUser(address _lpToken, address _account) external view override returns (User memory, uint256[] memory) {
    return (users[_lpToken][_account], viewRewards(_lpToken, _account));
  }

  function getAuthorizers(address _lpToken, address _bonusTokenAddr) external view override returns (address[] memory) {
    return allowedTokenAuthorizers[_lpToken][_bonusTokenAddr];
  }

  function getResponders() external view override returns (address[] memory) {
    return responders;
  }

  function viewRewards(address _lpToken, address _user) public view override returns (uint256[] memory) {
    Pool memory pool = pools[_lpToken];
    User memory user = users[_lpToken][_user];
    uint256[] memory rewards = new uint256[](pool.bonuses.length);
    if (user.amount <= 0) return rewards;

    uint256 rewardsWriteoffsLen = user.rewardsWriteoffs.length;
    for (uint256 i = 0; i < rewards.length; i ++) {
      Bonus memory bonus = pool.bonuses[i];
      if (bonus.startTime < block.timestamp && bonus.remBonus > 0) {
        uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
        uint256 bonusForTime = _calRewardsForTime(bonus, pool.lastUpdatedAt);
        uint256 bonusPerToken = bonus.accRewardsPerToken + bonusForTime / lpTotal;
        uint256 rewardsWriteoff = rewardsWriteoffsLen <= i ? 0 : user.rewardsWriteoffs[i];
        uint256 reward = user.amount * bonusPerToken / CAL_MULTIPLIER - rewardsWriteoff;
        rewards[i] = reward < bonus.remBonus ? reward : bonus.remBonus;
      }
    }
    return rewards;
  }


  function getPoolList() external view override returns (address[] memory) {
    return poolList;
  }

  /// @notice update pool's bonus per staked token till current block timestamp, do nothing if pool does not exist
  function _updatePool(address _lpToken) private {
    Pool storage pool = pools[_lpToken];
    uint256 poolLastUpdatedAt = pool.lastUpdatedAt;
    if (poolLastUpdatedAt == 0 || block.timestamp <= poolLastUpdatedAt) return;
    pool.lastUpdatedAt = block.timestamp;
    uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
    if (lpTotal == 0) return;

    for (uint256 i = 0; i < pool.bonuses.length; i ++) {
      Bonus storage bonus = pool.bonuses[i];
      if (poolLastUpdatedAt < bonus.endTime && bonus.startTime < block.timestamp) {
        uint256 bonusForTime = _calRewardsForTime(bonus, poolLastUpdatedAt);
        bonus.accRewardsPerToken = bonus.accRewardsPerToken + bonusForTime / lpTotal;
      }
    }
  }

  function _updateUserWriteoffs(address _lpToken) private {
    Bonus[] memory bonuses = pools[_lpToken].bonuses;
    User storage user = users[_lpToken][msg.sender];
    for (uint256 i = 0; i < bonuses.length; i++) {
      // update writeoff to match current acc rewards per token
      if (user.rewardsWriteoffs.length == i) {
        user.rewardsWriteoffs.push(user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER);
      } else {
        user.rewardsWriteoffs[i] = user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER;
      }
    }
  }

  /// @notice tranfer upto what the contract has
  function _safeTransfer(address _token, uint256 _amount) private returns (uint256 _transferred) {
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    if (balance > _amount) {
      token.safeTransfer(msg.sender, _amount);
      _transferred = _amount;
    } else if (balance > 0) {
      token.safeTransfer(msg.sender, balance);
      _transferred = balance;
    }
  }

  function _calRewardsForTime(Bonus memory _bonus, uint256 _lastUpdatedAt) internal view returns (uint256) {
    if (_bonus.endTime <= _lastUpdatedAt) return 0;

    uint256 calEndTime = block.timestamp > _bonus.endTime ? _bonus.endTime : block.timestamp;
    uint256 calStartTime = _lastUpdatedAt > _bonus.startTime ? _lastUpdatedAt : _bonus.startTime;
    uint256 timePassed = calEndTime - calStartTime;
    return _bonus.weeklyRewards * CAL_MULTIPLIER * timePassed / WEEK;
  }

  function _claimRewards(address _lpToken, User memory _user) private {
    // only claim if user has deposited before
    if (_user.amount == 0) return;
    uint256 rewardsWriteoffsLen = _user.rewardsWriteoffs.length;
    Bonus[] memory bonuses = pools[_lpToken].bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      uint256 rewardsWriteoff = rewardsWriteoffsLen <= i ? 0 : _user.rewardsWriteoffs[i];
      uint256 bonusSinceLastUpdate = _user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER - rewardsWriteoff;
      uint256 toTransfer = bonuses[i].remBonus < bonusSinceLastUpdate ? bonuses[i].remBonus : bonusSinceLastUpdate;
      if (toTransfer == 0) continue;
      uint256 transferred = _safeTransfer(bonuses[i].bonusTokenAddr, toTransfer);
      pools[_lpToken].bonuses[i].remBonus = bonuses[i].remBonus - transferred;
    }
  }

  // only owner or authorized users from list
  function _isAuthorized(address[] memory checkList) private view returns (bool) {
    if (msg.sender == owner()) return true;

    for (uint256 i = 0; i < checkList.length; i++) {
      if (msg.sender == checkList[i]) {
        return true;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ruler: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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

    function initializeReentrancyGuard () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

/**
 * @title Ruler Protocol Bonus Token Rewards Interface
 * @author crypto-pumpkin
 */
interface IBonusRewards {
  event Deposit(address indexed user, address indexed lpToken, uint256 amount);
  event Withdraw(address indexed user, address indexed lpToken, uint256 amount);
  event PausedStatusUpdated(address user, bool old, bool _new);

  struct Bonus {
    address bonusTokenAddr; // the external bonus token, like CRV
    uint48 startTime;
    uint48 endTime;
    uint256 weeklyRewards; // total amount to be distributed from start to end
    uint256 accRewardsPerToken; // accumulated bonus to the lastUpdated Time
    uint256 remBonus; // remaining bonus in contract
  }

  struct Pool {
    Bonus[] bonuses;
    uint256 lastUpdatedAt; // last accumulated bonus update timestamp
  }

  struct User {
    uint256 amount;
    uint256[] rewardsWriteoffs; // the amount of bonus tokens to write off when calculate rewards from last update
  }

  function getPoolList() external view returns (address[] memory);
  function getResponders() external view returns (address[] memory);
  function getPool(address _lpToken) external view returns (Pool memory);
  function getUser(address _lpToken, address _account) external view returns (User memory _user, uint256[] memory _rewards);
  function getAuthorizers(address _lpToken, address _bonusTokenAddr) external view returns (address[] memory);
  function viewRewards(address _lpToken, address _user) external view  returns (uint256[] memory);

  function claimRewardsForPools(address[] calldata _lpTokens) external;
  function deposit(address _lpToken, uint256 _amount) external;
  function withdraw(address _lpToken, uint256 _amount) external;
  function emergencyWithdraw(address[] calldata _lpTokens) external;
  function addBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint48 _startTime,
    uint256 _weeklyRewards,
    uint256 _transferAmount
  ) external;
  function extendBonus(
    address _lpToken,
    uint256 _poolBonusId,
    address _bonusTokenAddr,
    uint256 _transferAmount
  ) external;
  function updateBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint256 _weeklyRewards,
    uint48 _startTime
  ) external;

  // only owner
  function setResponders(address[] calldata _responders) external;
  function setPaused(bool _paused) external;
  function collectDust(address _token, address _lpToken, uint256 _poolBonusId) external;
  function addPoolsAndAllowBonus(
    address[] calldata _lpTokens,
    address[] calldata _bonusTokenAddrs,
    address[] calldata _authorizers
  ) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}